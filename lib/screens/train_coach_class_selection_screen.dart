import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'train_results_screen.dart'; // For Train class
import 'train_seat_selection_screen.dart';

class TrainCoachClassSelectionScreen extends StatefulWidget {
  final Train train;
  final int numberOfPassengers;

  const TrainCoachClassSelectionScreen({
    super.key,
    required this.train,
    required this.numberOfPassengers,
  });

  @override
  State<TrainCoachClassSelectionScreen> createState() => _TrainCoachClassSelectionScreenState();
}

class _TrainCoachClassSelectionScreenState extends State<TrainCoachClassSelectionScreen> {
  String? _selectedClass;

  // Mock price multipliers or differentials. A real app would get actual prices.
  Map<String, double> classPriceMultipliers = {
    "SL": 1.0,
    "3A": 1.8, "3E": 1.8, // AC 3 Tier / Economy
    "2A": 2.5, // AC 2 Tier
    "1A": 4.0, // AC 1st Class (not implemented in seat layout yet)
    "CC": 1.5, // AC Chair Car
    "2S": 0.8, // Second Sitting
  };

  double _getPriceForClass(String coachClass) {
    double multiplier = classPriceMultipliers[coachClass] ?? classPriceMultipliers["SL"]!; // Default to SL if not found
    return widget.train.basePrice * multiplier;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Select Class - ${widget.train.name}'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Classes for ${widget.numberOfPassengers} passenger(s):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.train.availableClasses.length,
              itemBuilder: (context, index) {
                final coachClass = widget.train.availableClasses[index];
                final price = _getPriceForClass(coachClass);
                final bool isSelected = _selectedClass == coachClass;

                return Card(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(isDarkMode ? 0.4 : 0.2)
                      : (isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.7) : Colors.white),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isSelected ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    title: Text(
                      coachClass,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 16),
                    ),
                    trailing: Text(
                      '₹${price.toStringAsFixed(2)} /pax',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                          fontSize: 15),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedClass = coachClass;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedClass != null ? AppTheme.primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedClass == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainSeatSelectionScreen(
                            train: widget.train,
                            numberOfSeatsToSelect: widget.numberOfPassengers,
                            selectedCoachType: _selectedClass!,
                            pricePerSeat: _getPriceForClass(_selectedClass!),
                          ),
                        ),
                      );
                    },
              child: const Text('Proceed to Select Seats', style: TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}