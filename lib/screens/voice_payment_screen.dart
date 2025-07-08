// voice_payment_screen.dart
import 'dart:async';
// Needed for jsonDecode in case user_data is fetched differently
import 'package:flutter/material.dart';
// Keep for PopScope and status bar
import 'package:payment_app/services/api_service.dart'; // Import your API service
import 'package:payment_app/utils/theme.dart'; // Using OLD AppTheme for styling
// import 'package:payment_app/utils/common_widgets.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // For number formatting in dialog
// Speech To Text Imports
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
// Permission Handler Import
import 'package:permission_handler/permission_handler.dart';

// Local Contact Model (ensure structure matches getContacts result mapping)
class Contact {
  String id;
  String name;
  String phoneNumber; // Assuming this is the identifier used for verification

  Contact({required this.id, required this.name, required this.phoneNumber});

  // Example factory if needed to create from API response
  factory Contact.fromApiContact(ApiContact apiContact) {
    // Ensure ApiContact class (from api_service.dart) has these fields
    return Contact(
      id: apiContact.id, // Check if ApiContact provides 'id'
      name: apiContact.name,
      phoneNumber: apiContact.phoneNumber,
    );
  }
}


class VoicePaymentScreen extends StatefulWidget {
  const VoicePaymentScreen({super.key});

  @override
  State<VoicePaymentScreen> createState() => _VoicePaymentScreenState();
}

class _VoicePaymentScreenState extends State<VoicePaymentScreen> with SingleTickerProviderStateMixin {
  // State Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceCommandStatus = 'Tap the mic and speak your command\n(e.g., "Pay 100 rupees to John Doe")';
  bool _speechAvailable = false;
  Timer? _silenceTimer;
  bool _isLoading = false; // General loading state (e.g., during payment execution)
  String? _currentUserId;
  Map<String, dynamic>? _walletData; // For sender ID and balance checks maybe
  List<Contact> _savedContacts = []; // Store loaded contacts
  bool _isLoadingData = true; // Combined initial loading state
  String? _initializationError; // Error during initial load

  final _storage = const FlutterSecureStorage();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _parsingInProgress = false; // Flag to prevent re-parsing


  @override
  void initState() {
    super.initState();
    // Animation
    _pulseController = AnimationController( duration: const Duration(milliseconds: 1000), vsync: this, )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate( CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut), );
    _pulseController.stop(); // Start stopped

    _initializeScreenAndSpeech();
  }

  // --- Define Helper Methods BEFORE Use ---
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

   void _showVoiceError(String message) {
     if (!mounted) return;
     // Ensure error message is not overly long
     final displayMessage = message.length > 150 ? "${message.substring(0, 150)}..." : message;
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(displayMessage),
      backgroundColor: AppTheme.errorColor,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
     ));
   }

  void _showSuccessDialog(Map<String, dynamic> response, String amountSent, String recipientName) {
    // Keep the existing success dialog logic using AppTheme colors
    if (!mounted) return;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paymentId = response['payment_id'] ?? 'N/A';
    final status = (response['status'] as String?)?.toUpperCase() ?? 'SUCCESSFUL';
    showDialog( context: context, barrierDismissible: false, builder: (context) => Dialog( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.9) : Colors.white, child: Padding( padding: const EdgeInsets.all(24.0), child: Column( mainAxisSize: MainAxisSize.min, children: [ Container( padding: const EdgeInsets.all(16), decoration: BoxDecoration( color: isDarkMode ? Colors.green.withOpacity(0.2) : Colors.green.shade50, shape: BoxShape.circle, ), child: Icon( Icons.check_circle, color: isDarkMode ? Colors.green.shade300 : Colors.green.shade600, size: 60, ), ), const SizedBox(height: 24), Text( 'Payment $status!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87), ), const SizedBox(height: 12), Text( 'You sent ₹$amountSent to $recipientName', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.grey.shade700), ), const SizedBox(height: 8), Text( 'Payment ID: $paymentId', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.grey.shade500), ), const SizedBox(height: 24), SizedBox( width: double.infinity, child: ElevatedButton( style: ElevatedButton.styleFrom( backgroundColor: isDarkMode ? Colors.white.withOpacity(0.15) : AppTheme.accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ), onPressed: () { Navigator.of(context).pop(); }, child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), ), ), ], ), ), ), );
   }
   // --- End Helper Definitions ---


  Future<void> _initializeScreenAndSpeech() async {
     setState(()=> _isLoadingData = true);
     _speech = stt.SpeechToText();
     try {
       // Check speech availability, handle potential errors during init
        bool available = false;
        try {
            available = await _speech.initialize( onStatus: _speechStatusListener, onError: _speechErrorListener, );
        } catch (e) {
            print("Speech initialization threw exception: $e");
            available = false; // Mark as unavailable if init throws
        }
        _speechAvailable = available;
        if (!_speechAvailable) {
            print("Speech recognition not available after initialize().");
            // Set a specific status message if speech couldn't init
             _voiceCommandStatus = "Speech recognition service not available on this device.";
        }

       await _loadRequiredData(); // Load essential user data regardless of speech
     } catch (e) {
       if(mounted) {
          _initializationError = "Initialization failed: ${e.toString().replaceFirst("Exception: ", "")}";
           // Ensure speech is marked unavailable if data load fails critically
          _speechAvailable = false;
       }
     } finally {
        if(mounted) setState(() => _isLoadingData = false);
     }
  }

   Future<void> _loadRequiredData() async {
     // Fetch User ID, Wallet, and Contacts in parallel
     try {
        final token = await _getToken();
        if (token == null) throw Exception("Auth Token not found.");
        final results = await Future.wait([
           _storage.read(key: 'user_id'),
           getWalletBalance(token),
           getContacts(token), // Fetch contacts from API
        ]);

        _currentUserId = results[0] as String?;
        _walletData = results[1] as Map<String, dynamic>?;
        final apiContacts = results[2] as List<ApiContact>;

        if (_currentUserId == null || _currentUserId!.isEmpty) throw Exception("User ID missing.");
        if (_walletData == null) throw Exception("Wallet details missing.");

        if (mounted) {
           _savedContacts = apiContacts.map((apiC) => Contact.fromApiContact(apiC)).toList();
           _savedContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            print(">>> CONTACTS DEBUG: Loaded Contacts: ${_savedContacts.map((c) => "'${c.name}' (Phone: ${c.phoneNumber})").toList()}");
        }
     } catch (e) {
        print("Error loading required data: $e");
        rethrow; // Important: Let initializer handle error display
     }
   }

  @override
  void dispose() {
    // Safe stop/cancel operations
    if (_speech.isListening) {
       _speech.stop();
    } else if (_speech.isAvailable) { // Check if init was successful before cancel
      _speech.cancel();
    }
    _silenceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
     var status = await Permission.microphone.status; if (!status.isGranted) { status = await Permission.microphone.request(); }
     if(mounted){
        if (!status.isGranted) { _showVoiceError("Microphone permission is required."); _speechAvailable = false; }
        else { _speechAvailable = true; }
        setState((){}); // Update UI to reflect permission status
     }
  }


  void _startListening() async {
     // Double check speech availability, potentially re-init if needed after permission grant
     if (!_speechAvailable) {
       await _requestMicPermission();
       if (!_speechAvailable || !mounted) return;
       // Re-try initialization ONLY if permission was just granted and init failed before
       if (!_speech.isAvailable) { // Check internal status
          bool success = await _speech.initialize( onStatus: _speechStatusListener, onError: _speechErrorListener, );
           if (!success) { _showVoiceError("Could not re-initialize speech."); return; }
           setState(() { _speechAvailable = true; }); // Update state if init now succeeds
       }
     }
      if (!_speechAvailable) { // Final check
         _showVoiceError("Speech recognition is not available.");
         return;
      }

      if (_isListening || _isLoading) return; // Don't start if already listening or loading

     setState(() { _isListening = true; _voiceCommandStatus = 'Listening...'; _parsingInProgress = false; });
     _pulseController.repeat(reverse: true);
     _silenceTimer?.cancel();

    // Use options compatible with most package versions
    // Note: behavior of pauseFor might vary or not be fully respected
    // depending on the underlying OS/engine. Silence timer is a fallback.
    _speech.listen(
      onResult: _speechResultListener,
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 5), // Attempt to use pauseFor
      partialResults: true,
      localeId: 'en_IN',
      cancelOnError: true,
      // listenMode: stt.ListenMode.dictation, // Potentially remove if causing issues
    );
     _resetSilenceTimer(); // Rely on manual silence timer
  }


  void _speechResultListener(SpeechRecognitionResult result) {
    // Check if still mounted before doing anything
    if (!mounted) return;

    _silenceTimer?.cancel(); // Cancel timer on any result activity
    if (_isListening) { // Only update if we are supposed to be listening
        setState(() {
            // Show recognized words, fallback to "Listening..." if empty
            _voiceCommandStatus = result.recognizedWords.isNotEmpty
                ? result.recognizedWords
                : "Listening...";
        });
        _resetSilenceTimer(); // Reset silence timer as long as we get results
    }

    // Process ONLY when the engine marks it as final AND we have words
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
        final finalWords = result.recognizedWords;
        print("** SPEECH DEBUG ** Final Recognized Words: -->$finalWords<--");
        _pulseController.stop();
        if(mounted) {
           setState(() {
              _voiceCommandStatus = finalWords; // Display final result briefly
              _isListening = false; // Update listening state
           });
          _parseAndConfirmPayment(finalWords); // Process the command
        }
    }
 }


  void _speechStatusListener(String status) {
    print('Speech Status: $status');
    if (!mounted) return; // Check if mounted

    final isCurrentlyListening = status == stt.SpeechToText.listeningStatus;

    // Update listening state and animation
    if (isCurrentlyListening != _isListening) {
       setState(() => _isListening = isCurrentlyListening);
       if(!isCurrentlyListening) {
          _pulseController.animateTo(0.0, duration: Duration(milliseconds: 200)); // Stop pulse smoothly
       } else {
           _pulseController.repeat(reverse: true); // Ensure pulse starts/resumes
       }
    }

    // If engine stopped listening
    if(status == stt.SpeechToText.notListeningStatus) {
       _silenceTimer?.cancel(); // Stop our timer
       _pulseController.stop(); // Stop animation right away
       if (mounted) {
          // Check if we stopped while actually listening and have something (that wasn't final yet)
          if(_isListening && _voiceCommandStatus.isNotEmpty && _voiceCommandStatus != 'Listening...' && !_parsingInProgress) {
             print("Stopped listening (maybe timeout), trying to parse: $_voiceCommandStatus");
             _parseAndConfirmPayment(_voiceCommandStatus);
          } else if (!_parsingInProgress) {
             // Reset placeholder text if stopped manually or without useful input
             setState(() { _isListening = false; _voiceCommandStatus = 'Tap the mic to speak.'; });
          }
          // Ensure _isListening state is false if status is notListening
           if(_isListening) setState(() => _isListening = false);
       }
    } else if (status == stt.SpeechToText.listeningStatus) {
       _resetSilenceTimer(); // Keep resetting timer while actively listening
    }
  }


  void _speechErrorListener(SpeechRecognitionError error) {
    print('Speech Error: ${error.errorMsg} (${error.permanent})');
    if (mounted) {
      setState(() { _isListening = false; _voiceCommandStatus = 'Error. Tap mic to try again.'; });
      _showVoiceError("Speech error: ${error.errorMsg}");
      _pulseController.stop();
    }
    _silenceTimer?.cancel();
  }


  void _resetSilenceTimer() {
     _silenceTimer?.cancel();
     _silenceTimer = Timer(const Duration(seconds: 6), () { // Adjusted timeout
        if (_isListening && mounted) {
           print("Silence timeout reached, stopping speech engine...");
           _speech.stop(); // Ask engine to stop, status listener should handle UI update
        }
     });
   }

  void _stopListening() {
     if (!_isListening && !_speech.isListening) return;
     _silenceTimer?.cancel();
     _speech.stop(); // Engine stop triggers status listener
     if (mounted) {
        _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 200));
        // Status listener might reset text, or we can do it here for immediate feedback
        setState(() { _isListening = false; _voiceCommandStatus = 'Tap the mic to speak.'; });
     }
  }

  // --- Parse Command (Using Contacts + Amount Helper + Debugging) ---
   double? _parseAmountFromText(String text) { // Keep this helper
     final digitRegex = RegExp(r'(\d+(\.\d+)?)\s*(rupees|rs)?'); var match = digitRegex.firstMatch(text); if (match != null) return double.tryParse(match.group(1) ?? '');
     final wordMap = { 'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0, 'six': 6.0, 'seven': 7.0, 'eight': 8.0, 'nine': 9.0, 'ten': 10.0, 'twenty': 20.0, 'thirty': 30.0, 'forty': 40.0, 'fifty': 50.0, 'sixty': 60.0, 'seventy': 70.0, 'eighty': 80.0, 'ninety': 90.0, 'hundred': 100.0, 'thousand': 1000.0, };
     final wordRegex = RegExp(r'\b(one|two|three|four|five|six|seven|eight|nine|ten|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)\s+(rupees|rs)\b', caseSensitive: false); match = wordRegex.firstMatch(text); if (match != null) { String word = match.group(1)!.toLowerCase(); return wordMap[word]; }
     final anyDigitRegex = RegExp(r'(\d+(\.\d+)?)'); match = anyDigitRegex.firstMatch(text); if (match != null) return double.tryParse(match.group(1) ?? '');
     return null;
   }

   // --- REVISED: Parse Command with Corrected firstWhere and Retry Prompt ---
  void _parseAndConfirmPayment(String command) {
    // Prevent double entry if already processing
    if (_parsingInProgress) return;
    // Ignore empty commands or initial placeholder
    if (command.isEmpty || command == 'Listening...' ) {
       // Don't set parsing flag if command is invalid from the start
       return;
    }

    setState(() => _parsingInProgress = true); // Set flag now

    command = command.toLowerCase().trim();
    print("** PARSE DEBUG ** Command Lowercase: -->$command<--");

    double? parsedAmount = _parseAmountFromText(command);
    print("** PARSE DEBUG ** Parsed Amount: $parsedAmount");

    String? potentialRecipientName;
    int potentialAmountEnd = command.indexOf(parsedAmount?.toString() ?? ' '); // Find where amount starts
     if (potentialAmountEnd == -1 && parsedAmount != null) potentialAmountEnd = command.indexOf(parsedAmount.toStringAsFixed(0));
     if (potentialAmountEnd == -1) { potentialAmountEnd = command.indexOf("rupees"); if (potentialAmountEnd == -1) potentialAmountEnd = command.indexOf("rs"); if(potentialAmountEnd != -1) potentialAmountEnd += 6; }
    else if (potentialAmountEnd != -1) { potentialAmountEnd = RegExp(r'\d+(\.\d+)?\s*(rupees|rs)?').firstMatch(command.substring(potentialAmountEnd))?.end ?? potentialAmountEnd + parsedAmount.toString().length; }
     if (potentialAmountEnd < 0) potentialAmountEnd = 0;
     final toIndex = command.indexOf(" to ", potentialAmountEnd);
     if (toIndex != -1 && command.length > toIndex + 4) { potentialRecipientName = command.substring(toIndex + 4).trim(); potentialRecipientName = potentialRecipientName.replaceAll(RegExp(r'[^\w\s]+$'), '').trim(); }
     print("** PARSE DEBUG ** Potential Recipient String: '$potentialRecipientName'");

    // --- Validation and Contact Matching ---
    Contact? matchedContact;
    String errorMsg = '';

    if (parsedAmount == null || parsedAmount <= 0) { errorMsg += "Couldn't understand amount. "; }
    if (potentialRecipientName == null || potentialRecipientName.isEmpty) { errorMsg += "Couldn't understand recipient. "; }

    // Proceed only if basic parsing seems okay
    if(errorMsg.isEmpty) {
        final searchNameLower = potentialRecipientName!.toLowerCase(); // Not null here
        print("** MATCH DEBUG ** Comparing '$searchNameLower'");
        print("** MATCH DEBUG ** Against Contacts: [${_savedContacts.map((c) => "'${c.name}' (lower: '${c.name.toLowerCase()}')").join(', ')}]");

        // --- *** USE TRY-CATCH FOR firstWhere *** ---
        try {
          matchedContact = _savedContacts.firstWhere(
            (contact) => contact.name.toLowerCase() == searchNameLower,
            // NO orElse needed here
          );
           print("** MATCH DEBUG ** Exact match found via firstWhere: ${matchedContact.name}");
        } catch (e) {
           // firstWhere throws if no element is found
           print("** MATCH DEBUG ** No exact match found via firstWhere.");
           matchedContact = null;
           // Now try partial matching ONLY if exact match failed
            List<Contact> possibleMatches = _savedContacts
               .where((contact) => contact.name.toLowerCase().contains(searchNameLower))
               .toList();
           print("** MATCH DEBUG ** Partial matches found: ${possibleMatches.length}");

           if (possibleMatches.length == 1) {
              matchedContact = possibleMatches.first;
              print("** MATCH DEBUG ** Unique partial match: ${matchedContact.name}");
           } else if (possibleMatches.length > 1) {
              String matchesText = possibleMatches.take(3).map((c) => c.name).join(", ");
              errorMsg += "Multiple matches: $matchesText. Be specific."; // Add to errors
              matchedContact = null; // Ensure no proceeding
           } else {
              // No exact or partial match found
              errorMsg += "'$potentialRecipientName' not found in contacts.";
           }
        }
        // --- *** END TRY-CATCH *** ---

    } // End if(errorMsg.isEmpty) for initial parse

    // 4. Handle Outcomes
    if (errorMsg.isEmpty && matchedContact != null) {
        // Success: Parsed amount and found unique contact
        print("Proceeding to confirm: ${matchedContact.phoneNumber}, Name: ${matchedContact.name}");
         if(mounted) setState(() => _parsingInProgress = false); // Reset flag before async dialog
        _showPaymentConfirmationDialog(parsedAmount!, matchedContact.phoneNumber, matchedContact.name);
    } else {
        // Failure: Show combined error and prompt retry
        errorMsg += " Please try again, e.g., 'Pay 100 rupees to <Contact Name>'.";
        _showVoiceError(errorMsg.trim());
        if (mounted) {
           setState(() {
              _voiceCommandStatus = 'Sorry, please try again.'; // Update status text
              _parsingInProgress = false; // Reset flag
           });
        }
    }
  }

  // ... rest of _VoicePaymentScreenState ...
 // --- End Parse ---


 void _showPaymentConfirmationDialog(double amount, String recipientContactIdentifier, String likelyRecipientName) async {
      // Reset parsing flag if we reach here (just in case)
     if (mounted) setState(() => _parsingInProgress = false);

      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      BuildContext? loadingDialogContext;

      showDialog( context: context, barrierDismissible: false, builder: (ctx) { loadingDialogContext = ctx; return PopScope( canPop: false, child: AlertDialog( key: ValueKey(loadingDialogContext.hashCode), backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.9) : Colors.white, content: Row( children: [ const CircularProgressIndicator(), const SizedBox(width: 15), Text("Verifying $likelyRecipientName..."),]) ) ); });

      String ultimateRecipientName = likelyRecipientName; String? recipientUserId; bool verificationSuccess = false;

      try {
         final token = await _getToken(); if(token == null) throw Exception("No token");
          final userData = await searchUserByPhone(token, recipientContactIdentifier); // Verify identifier
          if(mounted && loadingDialogContext!= null) {Navigator.pop(loadingDialogContext!); loadingDialogContext = null;} else {loadingDialogContext = null;}

          if(userData != null && userData['user'] != null && userData['user']['id'] != null){ final userMap = userData['user'] as Map<String, dynamic>; recipientUserId = userMap['id'] as String; String f = (userMap['first_name'] as String?) ?? ''; String l = (userMap['last_name'] as String?) ?? ''; String verifiedName = '$f $l'.trim(); if (verifiedName.isEmpty) verifiedName = (userMap['username'] as String?) ?? likelyRecipientName; ultimateRecipientName = verifiedName; verificationSuccess = true; }
          else { throw Exception("Recipient not found or invalid."); }
      } catch(e) {
         verificationSuccess = false;
         if (loadingDialogContext != null && mounted) { Navigator.pop(loadingDialogContext!); }
         if(mounted) {_showVoiceError("Couldn't verify '$likelyRecipientName' ($recipientContactIdentifier).");} return;
      }

      if (!verificationSuccess || !mounted) return; // Check mounted again

       bool? confirmed = await showDialog<bool>( context: context, barrierDismissible: false,
         builder: (BuildContext dialogContext) => AlertDialog( // ... Confirmation Dialog UI ...
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.95) : Colors.white, title: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)), content: Text( 'Pay ₹${NumberFormat("#,##0.00", "en_IN").format(amount)} to $ultimateRecipientName?', style: const TextStyle(fontSize: 17), ), actions: <Widget>[ TextButton( child: Text('CANCEL', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700])), onPressed: () => Navigator.of(dialogContext).pop(false), ), ElevatedButton( style: ElevatedButton.styleFrom( backgroundColor: isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor, foregroundColor: isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) ), onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('CONFIRM PAYMENT'), ), ], ), );

      if (confirmed == true) { _executeVoicePayment(amount, recipientUserId, ultimateRecipientName); }
      else { if(mounted) setState(() { _voiceCommandStatus = 'Payment cancelled. Tap mic.'; }); }
   }


   void _executeVoicePayment(double amount, String recipientId, String recipientNameForDialog) async {
       if (_currentUserId == null || _currentUserId!.isEmpty) { _showVoiceError("User session error."); return; } if (_walletData == null) { _showVoiceError("Wallet data missing."); return; } setState(() => _isLoading = true); String? token; try { token = await _getToken(); if (token == null) throw Exception('Token missing.'); final senderId = _walletData!['user_id'] ?? ""; if (senderId.isEmpty) throw Exception('Sender ID missing.'); final description = "Voice payment to $recipientNameForDialog"; final response = await initiateOnlinePayment( token, senderId, recipientId, amount, description: description, );
        if (!mounted) return; _showSuccessDialog(response, amount.toStringAsFixed(2), recipientNameForDialog);
        if (mounted) setState(() { _voiceCommandStatus = 'Payment Complete!'; }); // Simpler success message
      } catch (e) { if (mounted) { _showVoiceError("Payment failed: ${e.toString().replaceFirst("Exception: ", "")}"); } }
       finally { if (mounted) { setState(() => _isLoading = false); } }
   }


  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final Color gradientTop = isDarkMode ? AppTheme.darkGradientColors[0] : AppTheme.gradientColors[0];
    final Color gradientBottom = isDarkMode ? AppTheme.darkGradientColors[2] : AppTheme.gradientColors[2];
    final Color micBg = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final Color micListeningBg = Colors.redAccent.shade200;
    final Color statusTextColor = isDarkMode ? AppTheme.textSecondaryColorDark : Colors.white.withOpacity(0.9);
    final ThemeData currentTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
       appBar: AppBar( title: const Text('Pay by Voice'), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: currentTheme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600), ),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [gradientTop, gradientBottom], ), ),
        child: SafeArea(
          child: Padding( padding: const EdgeInsets.all(24.0),
            child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                 // Initial Loading/Error takes precedence
                 if(_isLoadingData) const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white))),
                 if(!_isLoadingData && _initializationError != null) Expanded(child: Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text(_initializationError!, style: TextStyle(color: AppTheme.errorColor, fontSize: 16), textAlign: TextAlign.center)))),

                 // Main UI shown only if init is ok
                 if(!_isLoadingData && _initializationError == null) ...[
                    Expanded( child: Center( // Status Display
                          child: AnimatedSwitcher( duration: const Duration(milliseconds: 300), transitionBuilder:(child, animation) => FadeTransition(opacity: animation, child: child),
                             child: Text( _voiceCommandStatus, key: ValueKey(_voiceCommandStatus), textAlign: TextAlign.center, style: currentTheme.textTheme.headlineSmall?.copyWith(color: statusTextColor, height: 1.45), ), ), ), ),
                    SizedBox( height: 120, child: Center( // Mic Button Area
                            child: ScaleTransition( scale: _pulseAnimation,
                               child: FloatingActionButton.large( heroTag: 'voicePayScreenFAB',
                                  onPressed: _isLoading ? null : (!_speechAvailable ? _requestMicPermission : (_isListening ? _stopListening : _startListening)),
                                  backgroundColor: _isLoading ? Colors.grey.shade600 : (_isListening ? micListeningBg : micBg),
                                  foregroundColor: Colors.white, elevation: 6.0,
                                  child: _isLoading ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Icon( !_speechAvailable ? Icons.mic_off_rounded : (_isListening ? Icons.stop_rounded : Icons.mic_rounded), size: 40, ), ), ), ), )
                 ]
               ],
            ),
          ),
        ),
      ),
    );
  }
  // --- END BUILD METHOD ---

} // End of _VoicePaymentScreenState