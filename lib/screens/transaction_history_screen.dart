// transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:payment_app/services/api_service.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/common_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // For loading shimmer effect
import 'package:payment_app/screens/transaction_detail_screen.dart'; // Import the transaction detail screen

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  final Map<String, String> _userNamesCache = {};
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeAppState();
  }

  Future<void> _initializeAppState() async {
  await _loadCurrentUserId();
  print("Current User ID: $_currentUserId"); // ADD THIS LOG
  if (_currentUserId == null) {
     if (mounted) { // Ensure widget is still mounted
       setState(() {
         _isLoading = false;
         _error = "User session invalid. Please log in again.";
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(_error!), backgroundColor: Theme.of(context).colorScheme.error),
       );
     }
     return; // Stop further execution if user ID is missing
  }
  // ... rest of the function ...
  await _loadTransactions();
}
  Future<void> _loadCurrentUserId() async {
    _currentUserId = await _storage.read(key: 'user_id');
    if (_currentUserId == null) {
      print("Critical: Current User ID not found.");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Could not identify current user. Please log in again.";
        });
      }
    }
  }

  Future<String> _getPartyDisplayName(String partyId, String token) async {
    if (partyId.isEmpty) return "Unknown User";
    if (_currentUserId != null && partyId == _currentUserId) return "Yourself (Transfer)";

    if (_userNamesCache.containsKey(partyId)) {
      return _userNamesCache[partyId]!;
    }

    try {
      final userDetails = await getUserDetailsById(token, partyId);
      if (userDetails != null && userDetails['user'] != null) {
        final userMap = userDetails['user'] as Map<String, dynamic>;
        String firstName = (userMap['first_name'] as String?) ?? '';
        String lastName = (userMap['last_name'] as String?) ?? '';
        String username = (userMap['username'] as String?) ?? '';
        
        String name = '$firstName $lastName'.trim();
        if (name.isEmpty) name = username;
        if (name.isEmpty) name = partyId.length > 8 ? "${partyId.substring(0, 8)}..." : partyId;
        
        _userNamesCache[partyId] = name;
        return name;
      }
    } catch (e) {
      print("Error fetching details for $partyId: $e");
    }
    return partyId.length > 8 ? "${partyId.substring(0, 8)}..." : partyId; // Fallback
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null && mounted) { // Check mounted before setState
        setState(() {
          _isLoading = false;
          _error = "User session error. Please try logging in again.";
        });
        return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception("Authentication token not found.");
      
      final apiResult = await fetchAllTransactions(token);
      List<Map<String, dynamic>> processedTransactions = [];

      for (var transactionData in apiResult) {
        final senderUserId = (transactionData['sender_user_id'] ?? transactionData['sender_id'] ?? '').toString();
        final receiverUserId = (transactionData['receiver_user_id'] ?? transactionData['receiver_id'] ?? '').toString();
        
        if (senderUserId.isEmpty || receiverUserId.isEmpty) continue; // Skip invalid transactions

        final isIncoming = receiverUserId == _currentUserId;
        
        String partyDisplayName = await _getPartyDisplayName(
            isIncoming ? senderUserId : receiverUserId, token);

        final dateString = transactionData['server_timestamp'] ?? 
                           transactionData['created_at'] ?? 
                           transactionData['updated_at'] ?? // Use updated_at as another fallback for date
                           DateTime.now().toIso8601String();
        
        processedTransactions.add({
          'id': (transactionData['transaction_id'] ?? transactionData['id'] ?? UniqueKey().toString()).toString(),
          'amount': double.tryParse(transactionData['amount'].toString()) ?? 0.0,
          'type': isIncoming ? 'incoming' : 'outgoing',
          'party_name': partyDisplayName,
          'date': dateString,
          'status': transactionData['status']?.toString().toUpperCase() ?? 'COMPLETED',
          'description': transactionData['description']?.toString() ?? '',
          'transaction_type': transactionData['transaction_type']?.toString() ?? 'P2P',
          'currency': transactionData['currency']?.toString() ?? 'INR',
        });
      }

      if (mounted) {
        setState(() {
          _transactions = processedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ThemeData currentTheme = Theme.of(context); // Get theme for specific values

    // --- Define Shimmer Colors Based on Theme ---
    Color shimmerBaseColor;
    Color shimmerHighlightColor;
    Color cardBackgroundColor; // The background on which the shimmer elements sit

    if (isDarkMode) {
       // Dark Theme: Aim for a subtle "glassy" highlight on a very dark base
       cardBackgroundColor = AppTheme.darkSurfaceColor.withOpacity(0.35); // Slightly more opaque card bg
       shimmerBaseColor = Colors.white.withOpacity(0.05); // Very faint base for shapes
       shimmerHighlightColor = Colors.white.withOpacity(0.12); // Slightly brighter faint highlight

       // Alternative Dark: Using theme greys
       // cardBackgroundColor = AppTheme.darkSurfaceColor.withOpacity(0.35);
       // shimmerBaseColor = AppTheme.darkHighlightColor.withOpacity(0.5); // Use darkHighlightColor
       // shimmerHighlightColor = AppTheme.darkSurfaceColor.withOpacity(0.9); // Slightly lighter than bg
    } else {
       // Light Theme (Your "Neo Purple Galaxy" which has dark elements):
       // Use shades of the actual card background color (dark purple)
       cardBackgroundColor =AppTheme.surfaceColor.withOpacity(0.25); // Your dark purple card bg
       shimmerBaseColor = AppTheme.primaryColor.withOpacity(0.3); // Base derived from darker primary
       shimmerHighlightColor = AppTheme.surfaceColor.withOpacity(0.4); // Highlight derived from card bg color
    }
    // --- End Color Definitions ---

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      period: const Duration(milliseconds: 1100), // Slightly faster shimmer pulse
      child: ListView.builder(
        itemCount: 7, // Show a decent number of placeholders
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container( // Represents the Card structure
              height: 75, // Maintain consistent height
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: cardBackgroundColor, // Apply the card's background color
                borderRadius: BorderRadius.circular(14), // Match card shape
                border: Border.all(
                   color: Colors.white.withOpacity(0.1), // Keep subtle border
                   width: 0.8,
                 ),
              ),
              child: Row( // Mimic the inner Row layout
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Shimmer Circle - Colored with shimmerBaseColor
                  Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: shimmerBaseColor, shape: BoxShape.circle)
                  ),
                  const SizedBox(width: 14),
                  // Shimmer Text Lines - Colored with shimmerBaseColor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width * 0.5, height: 14, // Slightly wider title placeholder
                            decoration: BoxDecoration(color: shimmerBaseColor, borderRadius: BorderRadius.circular(4))
                        ),
                        const SizedBox(height: 8),
                        Container(
                           width: MediaQuery.of(context).size.width * 0.3, height: 12,
                           decoration: BoxDecoration(color: shimmerBaseColor, borderRadius: BorderRadius.circular(4))
                        ),
                      ],
                    ),
                  ),
                  // Shimmer Amount Line - Colored with shimmerBaseColor
                  Container(
                     width: 60, height: 14,
                     decoration: BoxDecoration(color: shimmerBaseColor, borderRadius: BorderRadius.circular(4))
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
 }

  @override
  Widget build(BuildContext context) {
    final ThemeData currentTheme = Theme.of(context);
    final bool isDarkMode = currentTheme.brightness == Brightness.dark;
    
    // Determine appropriate text color for gradient background
    final Color textOnGradientColor = isDarkMode ? AppTheme.textPrimaryColorDark.withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final Color subTextOnGradientColor = isDarkMode ? AppTheme.textSecondaryColorDark.withOpacity(0.7) : Colors.white.withOpacity(0.7);


    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      appBar: commonAppBar(
        title: 'Transactions', 
        context: context,
        // Example of how commonAppBar might set its bg based on current theme
        // backgroundColor: currentTheme.appBarTheme.backgroundColor, 
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? AppTheme.darkGradientColors 
                : AppTheme.gradientColors,
          ),
        ),
        child: SafeArea( // Added SafeArea
          child: Column( // Added Column for potential header/filter section later
            children: [
              // Optional: Add a header or filter section here if needed in the future
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: Text("Recent Activity", style: currentTheme.textTheme.headlineSmall?.copyWith(color: textOnGradientColor)),
              // ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingShimmer(context)
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 60),
                                  const SizedBox(height: 16),
                                  Text('Error Loading Transactions', style: currentTheme.textTheme.titleLarge?.copyWith(color: textOnGradientColor)),
                                  const SizedBox(height: 8),
                                  Text(_error!, textAlign: TextAlign.center, style: currentTheme.textTheme.bodyMedium?.copyWith(color: subTextOnGradientColor)),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _loadTransactions,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor,
                                      foregroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
                                    )
                                  )
                                ],
                              ),
                            ))
                        : _transactions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 80, color: textOnGradientColor.withOpacity(0.6)),
                                    const SizedBox(height: 20),
                                    Text('No transactions found.', style: currentTheme.textTheme.titleLarge?.copyWith(color: textOnGradientColor)),
                                    const SizedBox(height: 8),
                                    Text('Your transaction history is currently empty.', style: currentTheme.textTheme.bodyMedium?.copyWith(color: subTextOnGradientColor), textAlign: TextAlign.center,),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadTransactions,
                                color: currentTheme.colorScheme.primary,
                                backgroundColor: currentTheme.cardTheme.color ?? currentTheme.colorScheme.surface,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  itemCount: _transactions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final transaction = _transactions[index];
                                    final isIncoming = transaction['type'] == 'incoming';
                                    final amount = transaction['amount'] as double;
                                    final DateTime date = DateTime.tryParse(transaction['date']) ?? DateTime.now();
                                    final description = transaction['description'] as String;
                                    // final status = transaction['status'] as String; // Can be used if needed
                                    final currency = transaction['currency'] as String;
                                    // final transactionType = transaction['transaction_type'] as String;
                                    final partyName = transaction['party_name'] as String;

                                    Color amountColor = isIncoming
                                        ? (isDarkMode ? Colors.greenAccent.shade200 : Colors.green.shade700)
                                        : (isDarkMode ? Colors.redAccent.shade100 : Colors.red.shade700);
                                    IconData typeIconData = isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded;
                                    Color iconBgColor = isIncoming 
                                        ? Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1) 
                                        : Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1);
                                    Color iconColor = isIncoming
                                        ? (isDarkMode ? Colors.greenAccent.shade100 : Colors.green.shade600)
                                        : (isDarkMode ? Colors.redAccent.shade100 : Colors.red.shade600);


                                    return Card(
                                      elevation: isDarkMode ? 1.5 : 3.0,
                                      // Use the specific AppTheme colors for cards on gradient
                                      color: isDarkMode 
                                          ? AppTheme.darkSurfaceColor.withOpacity(0.25) // More transparent on gradient
                                          : AppTheme.surfaceColor.withOpacity(0.25), // More transparent on gradient
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.08), // Subtle border
                                          width: 0.7,
                                        ),
                                      ),
                                      child: InkWell( // Added InkWell for potential tap action
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TransactionDetailScreen(transaction: transaction),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: iconBgColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(typeIconData, size: 20, color: iconColor),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      partyName,
                                                      style: currentTheme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: textOnGradientColor, // Text on card (on gradient)
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                                                      style: currentTheme.textTheme.bodySmall?.copyWith(
                                                        color: subTextOnGradientColor, // Subtext on card (on gradient)
                                                      ),
                                                    ),
                                                    if (description.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        description,
                                                        style: currentTheme.textTheme.bodySmall?.copyWith(
                                                            color: subTextOnGradientColor.withOpacity(0.8),
                                                            fontStyle: FontStyle.italic),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${isIncoming ? '+' : '-'}$currency${amount.abs().toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: amountColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15, // Slightly smaller amount for balance
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 