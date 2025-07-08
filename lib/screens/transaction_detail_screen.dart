import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payment_app/utils/theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black87;

    final String partyName = transaction['party_name'] ?? 'Unknown';
    final String description = transaction['description'] ?? 'No description provided';
    final String currency = transaction['currency'] ?? 'INR';
    final double amount = transaction['amount'] ?? 0.0;
    final String type = transaction['type'] ?? 'unknown';
    final String status = transaction['status'] ?? 'Unknown';
    final DateTime date = DateTime.tryParse(transaction['date']) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Party Name:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              partyName,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              '$currency ${amount.toStringAsFixed(2)} (${type.toUpperCase()})',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Date:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(date),
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}