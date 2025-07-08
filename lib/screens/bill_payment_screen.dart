import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart'; // Import AppTheme
import './bill_details_screen.dart';

class BillPaymentScreen extends StatelessWidget {
  const BillPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bills'),
        // Use theme colors
        backgroundColor: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
        foregroundColor: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight,
      ),
      // Use theme background color
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildBillCategory(
            context,
            icon: Icons.lightbulb_outline,
            title: 'Electricity Bill',
            // Use theme-aware colors for icon and card
            iconColor: isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillDetailsScreen(billType: 'Electricity'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildBillCategory(
            context,
            icon: Icons.water_drop_outlined,
            title: 'Water Bill',
            iconColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700, // Example specific color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillDetailsScreen(billType: 'Water'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildBillCategory(
            context,
            icon: Icons.router_outlined,
            title: 'Internet Bill',
            iconColor: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillDetailsScreen(billType: 'Internet'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildBillCategory(
            context,
            icon: Icons.phone_android_outlined,
            title: 'Mobile Recharge',
            iconColor: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillDetailsScreen(billType: 'Mobile Recharge'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildBillCategory(
            context,
            icon: Icons.more_horiz_outlined,
            title: 'Other Bills',
            iconColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillDetailsScreen(billType: 'Other'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillCategory(BuildContext context, {required IconData icon, required String title, required Color iconColor, VoidCallback? onTap}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Use theme-aware card color
      color: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
      child: ListTile(
        leading: Icon(icon, size: 36, color: iconColor), // Use passed iconColor
        title: Text(
          title, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w500, 
            // Use theme-aware text color
            color: isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight
          )
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          // Use theme-aware icon color
          color: isDarkMode ? AppTheme.textSecondaryColorDark : AppTheme.textSecondaryColorLight
        ),
        onTap: onTap,
      ),
    );
  }
}
