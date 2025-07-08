import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';

class ScheduledPaymentsScreen extends StatelessWidget {
  const ScheduledPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final List<Color> gradientColors = isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Scheduled Payments', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_send_outlined, size: 80, color: textColor.withOpacity(0.8)),
              const SizedBox(height: 20),
              Text(
                'No Scheduled Payments Yet',
                style: TextStyle(fontSize: 20, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              Text(
                'Check back later or schedule a new payment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
