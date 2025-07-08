import 'dart:convert';
import 'package:flutter/material.dart';
// Keep for SystemUiOverlayStyle if used by AppBar
import 'package:payment_app/screens/contact_screen.dart';
import 'package:payment_app/screens/movie_selection_screen.dart';
import 'package:payment_app/screens/voice_payment_screen.dart';
import 'package:payment_app/services/api_service.dart'; // Required for API calls
import 'package:payment_app/screens/payment_screen.dart';
import 'package:payment_app/screens/transaction_history_screen.dart';
import 'package:payment_app/screens/rewards_screen.dart';
import 'package:payment_app/screens/profile_screen.dart';
import 'package:payment_app/screens/qr_code_screen.dart';
// import 'package:payment_app/screens/authentication_screen.dart'; // Removed unused import
import 'package:payment_app/utils/theme.dart'; // Import OLD AppTheme for constants
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Keep shimmer import for wallet balance loading
import 'package:payment_app/screens/bill_payment_screen.dart'; // Added for Pay Bills
import 'package:payment_app/screens/wallet_screen.dart'; // Added for Wallet navigation
import 'package:payment_app/screens/travel.dart'; // Added for Travel navigation

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
// --- State Variables (Keep from New Code) ---
String _username = "User";
Map<String, dynamic>? _walletData;
List<Map<String, dynamic>> _recentTransactions = [];
final Map<String, String> _userNamesCache = {};
String? _currentUserId;

// Loading States
bool _isLoadingWallet = true;
bool _isLoadingTransactions = true;
bool _isRefreshing = false;
String? _transactionError;
 bool _isBalanceVisible = false; // Add this line

final _storage = const FlutterSecureStorage();

// --- Mock Notifications Data (Using the Old Structure) ---
// Keep this static for now, as requested
final List<Map<String, dynamic>> notifications = [
{'title': 'Payment Received', 'message': 'You received ₹500 from John', 'time': '2 min ago', 'isRead': false },
{'title': 'Special Offer', 'message': 'Get 10% cashback!', 'time': '1 hour ago', 'isRead': false },
];
// --- ---

@override
void initState() {
super.initState();
_initializeScreen();
}

// --- Data Loading Functions (Keep Functional Logic from New Code) ---
Future<void> _initializeScreen() async {
// Reset states on init
setState(() {
_isLoadingWallet = true;
_isLoadingTransactions = true;
_transactionError = null;
_isRefreshing = false;
_recentTransactions = []; // Clear previous list
});
await _loadCurrentUserId();
if (_currentUserId == null && mounted) {
setState(() { _isLoadingWallet = false; _isLoadingTransactions = false; }); return;
}
// Fetch concurrently
await Future.wait([
_loadUserData(),
_fetchWalletBalance(isInitialLoad: true),
_loadRecentTransactions(isInitialLoad: true),
]);
}

Future<void> _handleRefresh() async {
if (_isRefreshing) return;
setState(() => _isRefreshing = true);
try {
await _loadCurrentUserId();
if (_currentUserId == null) throw Exception("User session lost.");
// Refresh wallet and recent transactions in parallel
await Future.wait([
_fetchWalletBalance(),
_loadRecentTransactions(),
]);
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar( SnackBar(
content: Text('Refresh failed: ${e.toString().replaceFirst("Exception: ", "")}'),
// Use errorColor directly from AppTheme like old style
backgroundColor: AppTheme.errorColor,
),
);
}
} finally {
if (mounted) { setState(() => _isRefreshing = false); }
}
}

Future<void> _loadCurrentUserId() async {
try {
_currentUserId = await _storage.read(key: 'user_id');
if (_currentUserId == null || _currentUserId!.isEmpty) throw Exception("User ID not found.");
} catch(e) {
print("Critical Error loading User ID: $e");
if (mounted) {
// Stop loading indicators if User ID fails, set error
setState(() {
_isLoadingWallet = false;
_isLoadingTransactions = false;
_transactionError = "Could not identify user session.";
});
}
}
}

Future<String> _getPartyDisplayName(String partyId, String token) async {
if (_currentUserId != null && partyId == _currentUserId) return "Yourself"; // Simplified
if (partyId.isEmpty) return "Unknown";
if (_userNamesCache.containsKey(partyId)) return _userNamesCache[partyId]!;
try {
final userDetails = await getUserDetailsById(token, partyId); // Assumes exists
if (userDetails != null && userDetails['user'] != null) {
final userMap = userDetails['user'] as Map<String, dynamic>;
String firstName = (userMap['first_name'] as String?) ?? '';
String lastName = (userMap['last_name'] as String?) ?? '';
String username = (userMap['username'] as String?) ?? '';
String name = '$firstName $lastName'.trim();
if (name.isEmpty) name = username;
// Simplified fallback similar to original user data loading
if (name.isEmpty || name.toLowerCase() == 'null' || name.toLowerCase() == 'null null') {
name = username.isNotEmpty ? username : "User:${partyId.substring(0, 6)}"; // Use username or short ID
}
if (mounted) _userNamesCache[partyId] = name;
return name;
}
} catch (e) { print("Err fetching name for $partyId: $e"); }
String fallbackName = "ID: ${partyId.substring(0, 6)}"; // Fallback
if (mounted) _userNamesCache[partyId] = fallbackName;
return fallbackName;
}

Future<void> _loadRecentTransactions({bool isInitialLoad = false, int limit = 2}) async {
if (_currentUserId == null) { // Don't proceed if user ID failed
if (isInitialLoad && mounted) setState(()=> _isLoadingTransactions = false);
return;
}
if (isInitialLoad) setState(() => _isLoadingTransactions = true);
if (!isInitialLoad) _userNamesCache.clear(); // Clear cache on refresh maybe
setState(()=> _transactionError = null);

try {
  final token = await _storage.read(key: 'auth_token'); if (token == null) throw Exception("Auth token missing.");
  final apiResult = await fetchAllTransactions(token);
  List<Map<String, dynamic>> processedTransactions = [];
  final recentApiResults = apiResult.take(limit).toList(); // Get latest 'limit'

  for (var transactionData in recentApiResults) {
     final senderUserId = (transactionData['sender_user_id'] ?? transactionData['sender_id'] ?? '').toString();
     final receiverUserId = (transactionData['receiver_user_id'] ?? transactionData['receiver_id'] ?? '').toString();
     if (senderUserId.isEmpty || receiverUserId.isEmpty) continue;

     final isIncoming = receiverUserId == _currentUserId!; // Assert non-null after check
     final partyId = isIncoming ? senderUserId : receiverUserId;
     String partyDisplayName = await _getPartyDisplayName(partyId, token);

     final dateString = transactionData['server_timestamp'] ?? transactionData['created_at'] ?? transactionData['updated_at'];
     DateTime transactionDate = DateTime.tryParse(dateString?.toString() ?? '') ?? DateTime.now();
     // Format date string for OLD _TransactionItem widget
     String formattedDate;
     final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final yesterday = DateTime(now.year, now.month, now.day - 1); final txDay = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
     if (txDay == today) {formattedDate = 'Today';} else if (txDay == yesterday) {formattedDate = 'Yesterday';} else {formattedDate = DateFormat('MMM dd, yyyy').format(transactionDate);}

     final IconData icon = isIncoming ? Icons.attach_money : Icons.shopping_bag; // OLD icon logic
     final double amount = double.tryParse(transactionData['amount'].toString()) ?? 0.0;
     final double displayAmount = isIncoming ? amount : -amount; // OLD item expects signed amount

     processedTransactions.add({
       'icon': icon, 'title': partyDisplayName, 'amount': displayAmount, 'date': formattedDate,
       'description': transactionData['description']?.toString() ?? '', // Keep description data
     });
  }
  if (mounted) { setState(() { _recentTransactions = processedTransactions; _isLoadingTransactions = false; }); }
} catch (e) { print("Err loading recent tx: $e"); if (mounted) { setState(() { _isLoadingTransactions = false; _transactionError = e.toString().replaceFirst("Exception: ", ""); }); } }
}

Future<void> _loadUserData() async { // Use OLD username logic
try { final userData = await _storage.read(key: 'user_data'); if (userData != null && mounted) { final user = jsonDecode(userData); setState(() { _username = user['username'] ?? user['first_name'] ?? "User"; }); } }
catch (e) { print('Err loading user: $e'); }
}

Future<void> _fetchWalletBalance({bool isInitialLoad = false}) async { // Keep functional logic
if (isInitialLoad) { setState(() => _isLoadingWallet = true); }
try { final token = await _storage.read(key: 'auth_token'); if (token == null) { throw Exception("Token not found."); } final wallet = await getWalletBalance(token); if (mounted) { setState(() { _walletData = wallet; }); } }
catch (e) { print('Err fetching wallet: $e'); if(mounted && isInitialLoad) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Could not load wallet balance.'), backgroundColor: AppTheme.errorColor,) ); } if (!isInitialLoad) { /* Optionally handle non-initial load errors, e.g. silent fail or subtle indicator */ } else { rethrow; } }
finally { if (mounted && isInitialLoad) { setState(() => _isLoadingWallet = false); } }
}

String _formatBalance(dynamic balance) { // Use OLD formatting
if (balance == null) return '0.00'; if (balance is num) return balance.toStringAsFixed(2); if (balance is String) { try { return double.parse(balance).toStringAsFixed(2); } catch (e) { return balance.toString(); } } return '0.00';
}

// Revert Notification Modal Style to OLD Code
void _showNotifications() { // Reverted styling
showModalBottomSheet( context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container( constraints: BoxConstraints( maxHeight: MediaQuery.of(context).size.height * 0.7, ), decoration: BoxDecoration( color: Theme.of(context).brightness == Brightness.light ? Colors.white : AppTheme.primaryColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), ),
child: Column( mainAxisSize: MainAxisSize.min, children: [ Container( margin: const EdgeInsets.only(top: 8), height: 4, width: 40, decoration: BoxDecoration( color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4), ), ), Container( padding: const EdgeInsets.all(16), decoration: BoxDecoration( border: Border( bottom: BorderSide( color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade800, ), ), ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text( 'Notifications', style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold), ), TextButton( onPressed: () { setState(() { for (var n in notifications) { n['isRead'] = true; } }); Navigator.pop(context); }, child: Text('Mark all as read', style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? AppTheme.accentColor : Colors.white70)), ), ], ), ),
Flexible( child: ListView.builder( shrinkWrap: true, itemCount: notifications.length, itemBuilder: (context, index) { final notification = notifications[index]; return ListTile( leading: Container( padding: const EdgeInsets.all(8), decoration: BoxDecoration( color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle, ), child: const Icon(Icons.notifications, color: Colors.blue), ), title: Text(notification['title']), subtitle: Text(notification['message']), trailing: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Text( notification['time'], style: TextStyle( color: Colors.grey.shade400, fontSize: 12, ), ), if (!notification['isRead']) Container( margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: const BoxDecoration( color: Colors.blue, shape: BoxShape.circle, ), ), ] ), onTap: () { setState(() { notification['isRead'] = true; }); }, ); }, ), ),
],
),
),
);
}

@override
Widget build(BuildContext context) {
// Use brightness check and AppTheme constants like the old code
final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
final int unreadNotifications = notifications.where((n) => !n['isRead']).length;
// Use white text on gradient like old code
final Color textOnGradient = Colors.white;

return Scaffold(
  // Direct AppTheme usage like old code
  backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
  body: Container(
    width: double.infinity, height: double.infinity,
    decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors, ), ),
    child: SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        // Style indicator based on OLD AppTheme constants
        color: isDarkMode ? Colors.white : AppTheme.primaryColor,
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
        child: ListView( // Use ListView to make content scrollable under RefreshIndicator
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling is always enabled for refresh
          children: [
            // --- App Bar Row (OLD STYLE) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: Colors.white,
                          onPressed: _showNotifications,
                        ),
                        if (!_isLoadingWallet && !_isLoadingTransactions && !_isRefreshing && unreadNotifications > 0) 
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadNotifications.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Wallet Card (OLD STYLE) ---
            GestureDetector(
              onTap: () async { // MODIFIED: Made async
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
                // If WalletScreen (or any screen that can add funds) pops with `true`,
                // it indicates a potential balance change.
                if (result == true && mounted) {
                  await _fetchWalletBalance();
                  // Optionally, refresh recent transactions if top-ups create transaction entries
                  await _loadRecentTransactions(); 
                }
              },
              child: Container(
                height: 200, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.accentColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Balance row with eye icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _isLoadingWallet
                                  ? Shimmer.fromColors(
                                      baseColor: Colors.white.withOpacity(0.5),
                                      highlightColor: Colors.white.withOpacity(0.8),
                                      child: Container(
                                        width: 150,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _isBalanceVisible
                                          ? (_walletData == null
                                              ? 'Error'
                                              : '₹${_formatBalance(_walletData?['balance'])}')
                                          : 'XXXXXX',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  if (!_isBalanceVisible) {
                                    setState(() {
                                      _isLoadingWallet = true;
                                    });
                                    await _fetchWalletBalance();
                                    if (mounted) {
                                      setState(() {
                                        _isBalanceVisible = true;
                                        _isLoadingWallet = false;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _isBalanceVisible = false;
                                    });
                                  }
                                },
                                child: Icon(
                                  _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _WalletActionButton(
                                icon: Icons.qr_code_scanner,
                                label: 'Scan & Pay',
                                onTap: () async { // MODIFIED: Made async
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const QRCodeScreen(initialTabIndex: 1),
                                    ),
                                  );
                                  if (result == true && mounted) { // Assuming QRCodeScreen/payment flow pops with true
                                    await _fetchWalletBalance();
                                    await _loadRecentTransactions();
                                  }
                                },
                              ),
                              _WalletActionButton(
                                icon: Icons.qr_code,
                                label: 'My QR',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const QRCodeScreen(initialTabIndex: 0),
                                  ),
                                ), // Viewing QR doesn't change balance itself
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Rewards Button (OLD STYLE) ---
             Padding( padding: const EdgeInsets.only(top: 12.0), child: _WalletActionButton( icon: Icons.card_giftcard, label: 'Rewards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())), color: AppTheme.accentColor.withOpacity(0.15), ), ),
            const SizedBox(height: 24),

            // --- Quick Actions Section (OLD STYLE) ---
             Text( 'Quick Actions', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: textOnGradient, ), ), // Use white/light text
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: <Widget>[ 
                _QuickActionCard( 
                  icon: Icons.send, 
                  label: 'Send Money', 
                  onTap: () async { // MODIFIED: Made async
                    final result = await Navigator.push( context, MaterialPageRoute(builder: (_) => const PaymentScreen()), );
                    if (result == true && mounted) { // Assuming PaymentScreen pops with true
                      await _fetchWalletBalance();
                      await _loadRecentTransactions();
                    }
                  }, 
                ),
                _QuickActionCard( 
                  icon: Icons.history, 
                  label: 'History', 
                  onTap: () => Navigator.push( context, MaterialPageRoute( builder: (_) => const TransactionHistoryScreen(), ), ),
                ),
                _QuickActionCard( 
                  icon: Icons.mic_rounded, 
                  label: 'Voice\nPay', 
                  onTap: () async { // MODIFIED: Made async
                    final result = await Navigator.push(context, MaterialPageRoute( builder: (_) => const VoicePaymentScreen(),),);
                     if (result == true && mounted) { // Assuming VoicePaymentScreen pops with true
                      await _fetchWalletBalance();
                      await _loadRecentTransactions();
                    }
                  },
                ),
                _QuickActionCard( 
                  icon: Icons.contacts, 
                  label: 'Contacts', 
                  onTap: () => Navigator.push(context, MaterialPageRoute( builder: (_) => const ContactScreen(),),),
                ),
                _QuickActionCard( 
                  icon: Icons.movie, 
                  label: 'Movies', 
                  onTap: () async { // MODIFIED: Made async
                    final result = await Navigator.push(context, MaterialPageRoute( builder: (_) => const MovieSelectionScreen(),),);
                    if (result == true && mounted) { // Assuming MovieSelectionScreen pops with true if payment made
                      await _fetchWalletBalance();
                      await _loadRecentTransactions();
                    }
                  },
                ),
                _QuickActionCard( 
                  icon: Icons.receipt_long, // Added icon for Pay Bills
                  label: 'Pay Bills', // Added label for Pay Bills
                  onTap: () async { // MODIFIED: Made async
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPaymentScreen()));
                    if (result == true && mounted) { // Assuming BillPaymentScreen pops with true
                      await _fetchWalletBalance();
                      await _loadRecentTransactions();
                    }
                  },
                ),
                _QuickActionCard( 
                  icon: Icons.card_travel, 
                  label: 'Travel', 
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TravelScreen()),
                  ),
                ),
              ], 
            ), 
             const SizedBox(height: 24),

             // --- Recent Transactions Section (OLD STYLE Card Header) ---
              Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( 'Recent Transactions', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: textOnGradient, ), ), TextButton( onPressed: () => Navigator.push(context, MaterialPageRoute( builder: (_) => const TransactionHistoryScreen(),)), child: Text( 'See All', style: TextStyle( color:Colors.white , fontWeight: FontWeight.bold, ), ), ), ], ), // Old accent color for light button
              const SizedBox(height: 16),
              // Use Helper to build list items inside the OLD style card
              _buildOldStyleRecentTransactionsList(context, isDarkMode), // Use the helper defined below

             const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    ),
  ),
);
}

// --- Helper: Build Recent Transactions List using OLD Styling ---
Widget _buildOldStyleRecentTransactionsList(BuildContext context, bool isDarkMode) {
// Use OLD Card styling for the container
final Color cardBg = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white;
final Color defaultTextColor = isDarkMode ? Colors.white70 : Colors.grey.shade600; // Fallback text color within card

if (_isLoadingTransactions) {
  // Simple Loading indicator (inside the Card structure)
  return Card( color: cardBg, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, // Clip content
    child: Padding( padding: const EdgeInsets.symmetric(vertical: 30.0), child: Center(child: CircularProgressIndicator(color: defaultTextColor)),)
  );
}
if (_transactionError != null) {
  // Simple Error Text (inside the Card structure)
  return Card( color: cardBg, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
      child: Padding( padding: const EdgeInsets.all(20.0), child: Center(child: Text('Could not load recent activity.', style: TextStyle(color: defaultTextColor))),)
  );
}
if (_recentTransactions.isEmpty) {
   // Simple Empty Text (inside the Card structure)
   return Card( color: cardBg, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
      child: Padding( padding: const EdgeInsets.all(20.0), child: Center(child: Text('No recent transactions.', style: TextStyle(color: defaultTextColor))),)
   );
}

// Build column of OLD _TransactionItems inside the OLD style card
return Card(
  elevation: 4, // Old elevation
  color: cardBg, // Old bg
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), side: isDarkMode ? BorderSide(color: Colors.white.withOpacity(0.15), width: 1) : BorderSide.none, ), // Old shape/border
  clipBehavior: Clip.antiAlias, // Clip list items to card shape
  child: Column( // Use Column to list items inside the Card, no extra padding needed here
      children: _recentTransactions.map((transaction) {
        // Data Extraction (using keys set in _loadRecentTransactions for OLD _TransactionItem)
         final double amount = transaction['amount'] as double;
         final String title = transaction['title'] as String;
         final String date = transaction['date'] as String;
         final String description = transaction['description'] as String;
         final dynamic iconData = transaction['icon']; // Should be IconData
         final IconData icon = (iconData is IconData) ? iconData : Icons.help_outline; // Default icon if missing

         // Build UI for each transaction
         return Column( // Wrap Item and Description
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Add internal padding for list tile content
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Padding for item itself
               child: _TransactionItem( // OLD Item Widget
                 icon: icon, title: title, amount: amount, date: date,
               ),
             ),
             // Conditional Description
             if (description.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(left: 76.0, right: 16, top: 2, bottom: 16), // Indent description & add bottom padding here
                 child: Text( description, style: TextStyle( color: (isDarkMode ? Colors.white70 : Colors.grey.shade600).withOpacity(0.9), fontSize: 12, fontStyle: FontStyle.italic, ), maxLines: 2, overflow: TextOverflow.ellipsis, ),
               )
             else
                 const SizedBox(height: 16), // Add padding if no description (matching _TransactionItem's default)
              // Divider only if NOT the last item
              if (transaction != _recentTransactions.last)
                 Divider(height: 1, indent: 16, endIndent: 16, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))
           ],
         );
      }).toList(),
  ),
);
}

} // End of _HomeScreenState

// --- Reintroduce EXACT OLD Helper Widgets ---
class _QuickActionCard extends StatelessWidget {
final IconData icon;
final String label;
final VoidCallback onTap;
const _QuickActionCard({ required this.icon, required this.label, required this.onTap});

@override
Widget build(BuildContext context) {
final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
// Exact styling from OLD code
return Card( margin: EdgeInsets.zero, color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white, elevation: 4, shadowColor: Colors.black.withOpacity(0.2), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), side: BorderSide( color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.1), width: 1, ),),
child: InkWell( onTap: onTap, borderRadius: BorderRadius.circular(16),
child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration( color: isDarkMode ? Colors.white.withOpacity(0.15): AppTheme.accentColor.withOpacity(0.1), shape: BoxShape.circle, ),
child: Icon( icon, color: isDarkMode ? Colors.white : AppTheme.accentColor, size: 24, ),
),
const SizedBox(height: 10),
Padding( padding: const EdgeInsets.symmetric(horizontal: 4.0),
child: Text( label, textAlign: TextAlign.center, style: TextStyle( fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppTheme.primaryColor, ), maxLines: 2, overflow: TextOverflow.ellipsis,), // Allow 2 lines
),
],
),
),
);
}
}

class _WalletActionButton extends StatelessWidget {
final IconData icon;
final String label;
final VoidCallback onTap;
final Color? color; // Keep optional color
const _WalletActionButton({ required this.icon, required this.label, required this.onTap, this.color});

@override
Widget build(BuildContext context) {
// Exact styling from OLD code
return Material( color: color ?? Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
child: InkWell( onTap: onTap, borderRadius: BorderRadius.circular(12),
child: Container( padding: const EdgeInsets.symmetric( horizontal: 16, vertical: 12, ),
child: Row( mainAxisSize: MainAxisSize.min, children: [
Icon(icon, color: Colors.white, size: 20),
const SizedBox(width: 8),
Text( label, style: const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, ), ),
],
),
),
),
);
}
}

// Use the exact OLD _TransactionItem
class _TransactionItem extends StatelessWidget {
final IconData icon;
final String title;
final double amount; // Expects signed amount
final String date;
const _TransactionItem({ required this.icon, required this.title, required this.amount, required this.date});

@override
Widget build(BuildContext context) {
final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
// Exact styling from OLD code
return Padding( padding: const EdgeInsets.only(bottom: 16.0), // Own bottom padding
child: Row( children: [
Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration( color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12), ),
child: Icon( icon, color: isDarkMode ? Colors.white : Colors.black87, ), // Adjusted icon color slightly
),
const SizedBox(width: 16),
Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
Text( title, style: TextStyle( fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87, ), maxLines: 1, overflow: TextOverflow.ellipsis,),
Text( date, style: TextStyle( color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 12, ), ),
],
),
),
Text(
'${amount.isNegative ? "-" : "+"}₹${amount.abs().toStringAsFixed(2)}', // Logic based on signed amount
style: TextStyle( fontWeight: FontWeight.bold, color: amount.isNegative ? (isDarkMode ? Colors.red.shade300 : Colors.red) : (isDarkMode ? Colors.green.shade300 : Colors.green),
),
),
],
),
);
}
}