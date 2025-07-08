import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/common_widgets.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;

  const ComingSoonScreen({
    super.key,
    this.featureName = 'This feature',
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: commonAppBar(
        title: featureName,
        context: context,
        backgroundColor: Colors.transparent, // Optional, but makes it explicit
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Construction icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withAlpha(26) // 0.1 opacity
                      : Colors.white.withAlpha(230), // 0.9 opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction,
                  size: 60,
                  color: isDarkMode
                      ? Colors.white70
                      : AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 32),
              // Coming soon text
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Feature name and description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  '$featureName is under development\nCheck back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(179), // 0.7 opacity
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Back button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.white.withAlpha(51) // 0.2 opacity
                      : Colors.white,
                  foregroundColor: isDarkMode
                      ? Colors.white
                      : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Go back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
