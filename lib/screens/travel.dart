import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
// import 'package:payment_app/screens/coming_soon_screen.dart'; // No longer needed if all options lead somewhere
import 'flight_search_screen.dart';
import 'train_search_screen.dart';
import 'bus_search_screen.dart'; // Import the new bus search screen

class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Travel Booking'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTravelOptionCard(
              context: context,
              icon: Icons.flight,
              label: 'Book Flights',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlightSearchScreen(),
                  ),
                );
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildTravelOptionCard(
              context: context,
              icon: Icons.directions_bus,
              label: 'Book Buses',
              onTap: () {
                // Navigate to bus search screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusSearchScreen(), // Changed here
                  ),
                );
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildTravelOptionCard(
              context: context,
              icon: Icons.train,
              label: 'Book Trains',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrainSearchScreen(),
                  ),
                );
              },
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final Color cardIconColor = isDarkMode ? Colors.white70 : AppTheme.primaryColor;
    final Color cardTextColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;

    return Card(
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
        highlightColor: AppTheme.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: cardIconColor,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}