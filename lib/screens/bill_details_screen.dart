import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart'; // Import AppTheme
import './payment_screen.dart'; // Import PaymentScreen

class BillDetailsScreen extends StatefulWidget {
  final String billType;
  const BillDetailsScreen({super.key, required this.billType});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _accountNumber;
  double? _amount;

  String _getIdentifierLabel() {
    switch (widget.billType) {
      case 'Mobile Recharge':
        return 'Mobile Number';
      case 'Electricity':
        return 'Consumer ID / Account Number';
      case 'Water':
        return 'Connection ID / Consumer Number';
      case 'Internet':
        return 'Subscriber ID / Account Number';
      case 'Other':
        return 'Account / Reference Number';
      default:
        return 'Account/Consumer Number';
    }
  }

  String _getIdentifierHintText() {
    switch (widget.billType) {
      case 'Mobile Recharge':
        return 'Enter Mobile Number';
      case 'Electricity':
        return 'Enter Consumer ID / Account Number';
      case 'Water':
        return 'Enter Connection ID / Consumer Number';
      case 'Internet':
        return 'Enter Subscriber ID / Account Number';
      case 'Other':
        return 'Enter Account / Reference Number';
      default:
        return 'Enter Account/Consumer Number';
    }
  }

  TextInputType _getIdentifierKeyboardType() {
    switch (widget.billType) {
      case 'Mobile Recharge':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  void _proceedToPayment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Navigate to PaymentScreen.
      // To make PaymentScreen use the specific biller ID without modification,
      // we treat it like a P2P payment to a specific (biller) entity ID.
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            amount: _amount!,
            description: '${widget.billType} Bill for $_accountNumber', // Detailed description
            prefilledIdentifier: '88b0eb61-79d1-4c1d-a642-5abc544e59fe', // The specific biller ID
            identifierIsUserId: true, // Crucial: tells PaymentScreen to treat prefilledIdentifier as a direct ID for _findUserById
            // isBillPayment will default to false. This ensures PaymentScreen uses the
            // _selectedRecipientId (which will be the billerID after _findUserById)
            // for the transaction, rather than generating "biller_type" ID.

            // Parameters like billType and billAccountNumber are not passed here
            // as they are not used by PaymentScreen when isBillPayment is false.
            // The information is already in the 'description'.
          ),
        ),
      );

      // After payment screen is popped, check result and navigate back if successful
      if (paymentResult == 'success' && mounted) {
        Navigator.pop(context, 'payment_successful'); // Pop BillDetailsScreen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.billType} Bill Details'),
        backgroundColor: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
        foregroundColor: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight,
      ),
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter details for ${widget.billType} Bill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: TextStyle(color: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight),
                decoration: AppTheme.inputDecoration(
                  labelText: _getIdentifierLabel(),
                  hintText: _getIdentifierHintText(),
                  isDarkMode: isDarkMode,
                  prefixIcon: widget.billType == 'Mobile Recharge' ? Icons.phone_android : Icons.person_outline,
                ),
                keyboardType: _getIdentifierKeyboardType(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ${_getIdentifierLabel().toLowerCase()}';
                  }
                  if (widget.billType == 'Mobile Recharge' && (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value))) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
                onSaved: (value) => _accountNumber = value,
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: TextStyle(color: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight),
                decoration: AppTheme.inputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter Amount',
                  isDarkMode: isDarkMode,
                  prefixIcon: Icons.currency_rupee,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.tryParse(value!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}