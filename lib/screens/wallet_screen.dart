import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/screens/transaction_history_screen.dart';
import 'package:payment_app/screens/scheduled_payments_screen.dart';
import 'package:payment_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart'; // Added shimmer import

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Add storage instance
  double _walletBalance = 0.00; // Initialize with 0.00
  bool _isLoadingBalance = true;
  bool _isAddingFunds = false;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBalance = true;
    });
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found.');
      }
      // Ensure getWalletBalance is awaited
      final walletData = await getWalletBalance(token);
      if (mounted) {
        setState(() {
          // Safely parse the balance
          final balanceValue = walletData['balance'];
          if (balanceValue is num) {
            _walletBalance = balanceValue.toDouble();
          } else if (balanceValue is String) {
            _walletBalance = double.tryParse(balanceValue) ?? 0.00;
          } else {
            _walletBalance = 0.00;
          }
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
        print('Error fetching wallet balance: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  void _navigateToAddFunds() async {
    // Show a dialog to enter the amount to add
    final double? amountToAdd = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController amountController = TextEditingController();
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Define text field style based on theme for better visibility
        final TextStyle inputTextStyle = TextStyle(color: isDarkMode ? AppTheme.textPrimaryColorDark : Colors.black);
        
        // Define InputDecoration specifically for the dialog to ensure visibility
        final InputDecoration dialogInputDecoration = AppTheme.inputDecoration(
          hintText: 'Enter amount',
          labelText: 'Amount',
          isDarkMode: isDarkMode,
          prefixIcon: Icons.currency_rupee,
        ).copyWith(
          hintStyle: TextStyle(color: isDarkMode ? AppTheme.textSecondaryColorDark.withOpacity(0.7) : Colors.grey.shade600), // Darker grey for light mode hint
          labelStyle: TextStyle(color: isDarkMode ? AppTheme.textSecondaryColorDark.withOpacity(0.7) : Colors.grey.shade700), // Darker grey for light mode label
        );

        return AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
          title: Text(
            'Add Funds to Wallet', 
            style: TextStyle(color: isDarkMode ? AppTheme.textPrimaryColorDark : Colors.black87) // Ensure title is visible in light mode
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: inputTextStyle, // Apply defined input text style
              decoration: dialogInputDecoration, // Apply defined input decoration
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final double? amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: isDarkMode ? AppTheme.accentColor : AppTheme.primaryColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isDarkMode ? AppTheme.accentColor : AppTheme.primaryColor),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(double.tryParse(amountController.text));
                }
              },
            ),
          ],
        );
      },
    );

    if (amountToAdd != null && amountToAdd > 0) {
      if (!mounted) return;
      setState(() => _isAddingFunds = true);
      try {
        final token = await _storage.read(key: 'auth_token');
        if (token == null) throw Exception('Token not found');

        // Call the new api_service function
        final response = await addFundsToWallet(token, amountToAdd);

        if (response['status'] == 'success') {
          if (!mounted) return;
          
          // Option 1: Directly update the wallet balance if returned in the response
          if (response['new_balance'] != null) {
            setState(() {
              final dynamic newBalance = response['new_balance'];
              if (newBalance is num) {
                _walletBalance = newBalance.toDouble();
                _isLoadingBalance = false;
              } else if (newBalance is String) {
                _walletBalance = double.tryParse(newBalance) ?? _walletBalance;
                _isLoadingBalance = false;
              }
            });
          } else {
            // Option 2: If new balance not in response, refresh from server
            _fetchWalletBalance(); 
          }
        } else {
          // Backend reported an error but might have returned a 2xx status
          print('Failed to add funds (API reported error): ${response['message']}');
          if (mounted) {
             _fetchWalletBalance(); // Still refresh balance
          }
        }

      } catch (e) {
        if (!mounted) return;
        print('Error adding funds: ${e.toString()}');
        _fetchWalletBalance(); // Attempt to refresh balance even on error
      } finally {
        if (mounted) setState(() => _isAddingFunds = false);
      }
    }
  }

  void _navigateToTransactionHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
  }

  void _navigateToScheduledPayments() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduledPaymentsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final Color surfaceColor = isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final Color highlightColor = isDarkMode ? (Colors.amberAccent.shade400) : AppTheme.highlightColor; // Brighter highlightColor in dark mode
    final Color textColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final Color secondaryTextColor = isDarkMode ? AppTheme.textSecondaryColorDark : AppTheme.textSecondaryColorLight;
    final List<Color> gradientColors = isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors;


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Wallet', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // Make AppBar transparent to show gradient
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              _buildBalanceCard(context, isDarkMode, textColor, secondaryTextColor, highlightColor),
              const SizedBox(height: 30),
              _buildAddFundsButton(context, accentColor, textColor),
              const SizedBox(height: 20),
              _buildWalletActionListTile(
                context: context,
                icon: Icons.history_edu_rounded,
                title: 'Transaction History',
                onTap: _navigateToTransactionHistory,
                isDarkMode: isDarkMode,
                tileColor: surfaceColor.withOpacity(0.5),
                iconColor: highlightColor,
                textColor: textColor,
              ),
              _buildWalletActionListTile(
                context: context,
                icon: Icons.schedule_rounded,
                title: 'Scheduled Payments',
                onTap: _navigateToScheduledPayments,
                isDarkMode: isDarkMode,
                tileColor: surfaceColor.withOpacity(0.5),
                iconColor: highlightColor,
                textColor: textColor,
              ),
              // Add more wallet features here if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, bool isDarkMode, Color textColor, Color secondaryTextColor, Color highlightColor) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: (isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor).withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 32, color: highlightColor),
                const SizedBox(width: 12),
                Text(
                  'Current Balance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: secondaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoadingBalance
                ? Shimmer.fromColors(
                    baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
                    child: Container(
                      width: 200,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Text(
                    '₹${_walletBalance.toStringAsFixed(2)}', // Changed from \$ to ₹
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
            const SizedBox(height: 24),
            Text(
              'Manage your funds and view your spending habits all in one place.',
              style: TextStyle(fontSize: 14, color: secondaryTextColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFundsButton(BuildContext context, Color accentColor, Color textColor) {
    return ElevatedButton.icon(
      icon: _isAddingFunds
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
          : Icon(Icons.add_circle_outline_rounded, color: textColor),
      label: Text(_isAddingFunds ? 'Processing...' : 'Add Funds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      onPressed: _isAddingFunds ? null : _navigateToAddFunds,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
    );
  }

  Widget _buildWalletActionListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color tileColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: tileColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: isDarkMode ? Colors.amberAccent.shade400 : iconColor, size: 28), // Brighter icon in dark mode
        title: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: isDarkMode ? Colors.amberAccent.shade400 : textColor.withOpacity(0.7), size: 18), // Brighter trailing icon in dark mode
        onTap: onTap,
      ),
    );
  }
}
