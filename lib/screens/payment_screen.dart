import 'package:flutter/material.dart';
import 'package:payment_app/services/api_service.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/common_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payment_app/screens/contact_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? prefilledIdentifier;
  final bool identifierIsUserId;
  final double? amount;
  final String? description; // Add this parameter
  final bool isBillPayment; // New parameter
  final String? billType; // New parameter
  final String? billAccountNumber; // New parameter

  const PaymentScreen({
    super.key,
    this.prefilledIdentifier,
    this.identifierIsUserId = false,
    this.amount,
    this.description, // Add this
    this.isBillPayment = false, // Default to false
    this.billType,
    this.billAccountNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _phoneNumberController = TextEditingController(); // Still used for manual input

  bool _isLoading = false;
  bool _isLoadingWallet = true;
  bool _isVerifyingRecipient = false; // Changed from _isSearchingUser for clarity

  Map<String, dynamic>? _walletData;
  String? _selectedRecipientId;
  String _recipientDisplayName = '';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();

    // Handle prefilled amount and description if provided
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toString();
    }
    if (widget.description != null) {
      _noteController.text = widget.description!;
    }

    // Existing prefilled identifier logic
    if (widget.prefilledIdentifier != null && widget.prefilledIdentifier!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.identifierIsUserId) {
            // If it's a user ID, directly try fetching details by ID
            _phoneNumberController.text = "User ID: ${widget.prefilledIdentifier!.substring(0, 8)}..."; // Show masked ID initially
            _findUserById(widget.prefilledIdentifier!);
          } else {
            // If it's expected to be phone/email/username, use the standard search
            _phoneNumberController.text = widget.prefilledIdentifier!;
            _findUserByPhoneOrUsername(widget.prefilledIdentifier!);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _fetchWalletBalance() async {
    setState(() => _isLoadingWallet = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Auth token not found.');
      final wallet = await getWalletBalance(token);
      if (mounted) {
        setState(() {
        _walletData = wallet;
      });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet Load Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _searchRecipient() async {
    final identifier = _phoneNumberController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone, username or email.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _findUserByPhoneOrUsername(identifier);
  }

  Future<void> _findUserByPhoneOrUsername(String identifier) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifyingRecipient = true;
      _selectedRecipientId = null;
      _recipientDisplayName = 'Verifying User...';
    });

    String? token;
    try {
      token = await _getToken();
      if (token == null) throw Exception('Auth token not found.');
      final dynamic userData = await searchUserByPhone(token, identifier);
      _processUserData(userData);
    } catch (e) {
      _handleSearchError(e);
    } finally {
      if (mounted) {
        setState(() => _isVerifyingRecipient = false);
      }
    }
  }

  Future<void> _findUserById(String userId) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifyingRecipient = true;
      _selectedRecipientId = null;
      _recipientDisplayName = 'Verifying User...';
    });

    String? token;
    try {
      token = await _getToken();
      if (token == null) throw Exception('Auth token not found.');
      final dynamic userData = await getUserDetailsById(token, userId);
      _processUserData(userData);
    } catch (e) {
      _handleSearchError(e);
    } finally {
      if (mounted) {
        setState(() => _isVerifyingRecipient = false);
      }
    }
  }

  void _processUserData(dynamic userData) {
    if (!mounted) return;

    print('Processing User Data Response: $userData');

    if (userData != null && userData is Map<String, dynamic>) {
      final dynamic userObject = userData['user'];
      print('Nested User Object: $userObject');

      if (userObject != null && userObject is Map<String, dynamic>) {
        final dynamic idValue = userObject['id'];
        print('ID Value: $idValue, type: ${idValue.runtimeType}');

        if (idValue != null && idValue is String && idValue.isNotEmpty) {
          _selectedRecipientId = idValue;
          final firstName = (userObject['first_name'] as String?) ?? '';
          final lastName = (userObject['last_name'] as String?) ?? '';
          final username = (userObject['username'] as String?) ?? '';
          _recipientDisplayName = '$firstName $lastName'.trim();
          if (_recipientDisplayName.isEmpty) _recipientDisplayName = username;
          if (_recipientDisplayName.isEmpty) _recipientDisplayName = 'Verified User';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recipient Found: $_recipientDisplayName'), backgroundColor: Colors.green),
          );
          if (!widget.identifierIsUserId) {
            _phoneNumberController.text = _recipientDisplayName;
          }
        } else {
          _recipientDisplayName = 'Verification Error (Invalid ID).';
          _selectedRecipientId = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Found user, but failed to get valid ID.'), backgroundColor: Colors.orange),
          );
        }
      } else {
        _recipientDisplayName = 'Verification Error (Data Format).';
        _selectedRecipientId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Received unexpected user data format.'), backgroundColor: Colors.orange),
        );
      }
    } else {
      _recipientDisplayName = 'Recipient Not Found.';
      _selectedRecipientId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with this identifier.'), backgroundColor: Colors.orange),
      );
    }
    setState(() {});
  }

  void _handleSearchError(Object e) {
    print('Error finding user: $e');
    if (mounted) {
      setState(() {
        _recipientDisplayName = 'Search Failed.';
        _selectedRecipientId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToContactScreen() async {
    final selectedPhoneNumber = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ContactScreen()),
    );
    if (selectedPhoneNumber != null && selectedPhoneNumber.isNotEmpty && mounted) {
      _phoneNumberController.text = selectedPhoneNumber;
      _findUserByPhoneOrUsername(selectedPhoneNumber);
    }
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // For bill payments, recipient verification might be different or not required in the same way.
    // The backend might handle biller details based on billType and billAccountNumber.
    if (!widget.isBillPayment && (_selectedRecipientId == null || _selectedRecipientId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify recipient first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Auth token missing.');
      final amount = double.parse(_amountController.text);
      final description = _noteController.text.trim().isNotEmpty 
                          ? _noteController.text.trim() 
                          : (widget.isBillPayment 
                              ? '${widget.billType} Bill for ${widget.billAccountNumber}' 
                              : "Payment from TapKaro app");
      
      final senderId = _walletData?['user_id'] ?? "";
      if (senderId.isEmpty) print("Warning: Sender ID missing.");

      // Use a placeholder or specific biller ID for bill payments if your API requires a recipientId
      final String effectiveRecipientId = widget.isBillPayment 
          ? "biller_${widget.billType?.toLowerCase().replaceAll(' ', '_') ?? 'unknown'}" 
          : _selectedRecipientId!;

      // Potentially use a different API endpoint or add parameters for bill payment
      final response = await initiateOnlinePayment(
        token,
        senderId,
        effectiveRecipientId, // Use effectiveRecipientId
        amount,
        description: description,
        // You might need to pass additional parameters for bill payment to your API service
        // e.g., transaction_type: widget.isBillPayment ? "BILL_PAYMENT" : "P2P",
        // billDetails: widget.isBillPayment ? { "type": widget.billType, "account": widget.billAccountNumber } : null,
      );

      if (mounted) {
        final recipientNameForDialog = widget.isBillPayment 
            ? widget.billType ?? 'Biller' 
            : (_recipientDisplayName.isNotEmpty && !_recipientDisplayName.contains('...') 
                ? _recipientDisplayName 
                : 'Recipient');
        
        _showSuccessDialog(response, amount.toStringAsFixed(2), recipientNameForDialog);
        _amountController.clear();
        _noteController.clear();
        
        if (!widget.isBillPayment) {
          _phoneNumberController.clear();
          setState(() {
            _selectedRecipientId = null;
            _recipientDisplayName = '';
          });
        }
        _fetchWalletBalance(); // Refresh wallet balance on this screen

        // If it was a bill payment, pop with success to also refresh WalletScreen via BillDetailsScreen
        if (widget.isBillPayment) {
          Navigator.pop(context, 'success'); // Pop PaymentScreen, returning to BillDetailsScreen
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response, String amountSent, String recipientName) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paymentId = response['payment_id'] ?? 'N/A';
    final status = (response['status'] as String?)?.toUpperCase() ?? 'SUCCESSFUL';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment $status!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'You sent ₹$amountSent to $recipientName',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment ID: $paymentId',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white.withOpacity(0.15) : AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBalance(dynamic balance) {
    if (balance == null) return '0.00';
    if (balance is num) return balance.toStringAsFixed(2);
    if (balance is String) {
      try {
        return double.parse(balance).toStringAsFixed(2);
      } catch (e) {
        return balance.toString();
      }
    }
    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textOnGradient = isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white;

    // Determine AppBar title based on payment type
    final String appBarTitle = widget.isBillPayment ? 'Pay ${widget.billType} Bill' : 'Send Money';

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: commonAppBar(title: appBarTitle, context: context), // Use dynamic title
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textOnGradient.withOpacity(0.9)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textOnGradient)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 180,
                                    child: TextFormField(
                                      controller: _amountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.blueGrey.shade800),
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, color: (isDarkMode ? Colors.white : Colors.blueGrey.shade800).withOpacity(0.5)),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        errorStyle: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade300,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Enter amount';
                                        double? amount = double.tryParse(value);
                                        if (amount == null || amount <= 0) return 'Invalid amount';
                                        final balance = _walletData?['balance'];
                                        if (balance != null) {
                                          double currentBalance = 0.0;
                                          if (balance is String) {
                                            currentBalance = double.tryParse(balance) ?? 0.0;
                                          } else if (balance is num) {
                                            currentBalance = balance.toDouble();
                                          }
                                          if (amount > currentBalance) return 'Insufficient balance';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _isLoadingWallet
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor)))
                                  : Text(
                                      'Available Balance: ₹${_formatBalance(_walletData?['balance'])}',
                                      style: TextStyle(color: textOnGradient.withOpacity(0.7), fontSize: 14),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Divider(color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 20),
                        // Conditionally show recipient selection for P2P, hide for bill payment
                        if (!widget.isBillPayment)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send To', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textOnGradient.withOpacity(0.9))),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneNumberController,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                                keyboardType: TextInputType.text,
                                decoration: AppTheme.inputDecoration(
                                  hintText: 'Enter phone, username or email',
                                  isDarkMode: isDarkMode,
                                ).copyWith(
                                  fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                                  prefixIcon: Icon(Icons.person_outline, color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDarkMode
                                        ? BorderSide(color: Colors.white.withOpacity(0.2), width: 1)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: isDarkMode
                                        ? BorderSide(color: Colors.white.withOpacity(0.5), width: 1)
                                        : BorderSide(color: AppTheme.accentColor, width: 1),
                                  ),
                                ),
                                autovalidateMode: AutovalidateMode.disabled,
                                onChanged: (value) {
                                  if (_selectedRecipientId != null) {
                                    setState(() {
                                      _selectedRecipientId = null;
                                      _recipientDisplayName = '';
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_selectedRecipientId == null && (value == null || value.isEmpty)) {
                                    return 'Enter recipient identifier';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: ElevatedButton.icon(
                                  onPressed: _isVerifyingRecipient ? null : _searchRecipient,
                                  icon: _isVerifyingRecipient
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: AppTheme.accentColor))
                                      : Icon(Icons.search,
                                          size: 20, color: isDarkMode ? Colors.white : AppTheme.accentColor),
                                  label: Text('Verify User',
                                      style: TextStyle(
                                          color: isDarkMode ? Colors.white : AppTheme.accentColor)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode
                                          ? AppTheme.darkSurfaceColor.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.8),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      side: BorderSide(color: AppTheme.accentColor.withOpacity(0.5))),
                                )),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: ElevatedButton.icon(
                                  onPressed: _navigateToContactScreen,
                                  icon: Icon(Icons.contacts, size: 20, color: Colors.white),
                                  label: Text('Contacts', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                )),
                              ]),
                              if (_recipientDisplayName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    _recipientDisplayName,
                                    style: TextStyle(
                                      color: (_selectedRecipientId != null)
                                          ? (isDarkMode
                                              ? Colors.greenAccent.shade100
                                              : Colors.green.shade700)
                                          : (isDarkMode
                                              ? Colors.orangeAccent.shade100
                                              : Colors.orange.shade900),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        Text('Note (Optional)',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textOnGradient.withOpacity(0.9))),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                          maxLines: 3,
                          minLines: 1,
                          decoration: AppTheme.inputDecoration(
                            hintText: 'Add a note...',
                            isDarkMode: isDarkMode,
                          ).copyWith(
                            fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: isDarkMode
                                  ? BorderSide(color: Colors.white.withOpacity(0.2), width: 1)
                                  : BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: isDarkMode
                                  ? BorderSide(color: Colors.white.withOpacity(0.5), width: 1)
                                  : BorderSide(color: AppTheme.accentColor, width: 1),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || (!widget.isBillPayment && _isVerifyingRecipient)) ? null : _processPayment, // Adjust loading check for bill payment
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: isDarkMode ? 4 : 2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor)))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 20),
                                SizedBox(width: 8),
                                Text('Send Money',
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}