import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
// import 'train_seat_selection_screen.dart'; // No longer directly navigating here
import 'train_coach_class_selection_screen.dart'; // New import

// Train class definition remains the same
class Train {
  final String name;
  final String trainNumber;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final List<String> availableClasses; // e.g., ["SL", "3A", "2A", "CC"]
  final double basePrice; // Base price, for lowest class or as a reference

  Train({
    required this.name,
    required this.trainNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.availableClasses,
    required this.basePrice,
  });
}

class TrainResultsScreen extends StatelessWidget {
  final String fromStation;
  final String toStation;
  final int numberOfPassengers;

  const TrainResultsScreen({
    super.key,
    required this.fromStation,
    required this.toStation,
    required this.numberOfPassengers,
  });

  List<Train> _getMockTrains() {
    // Make sure availableClasses are varied for testing
    return [
      Train(name: 'Rajdhani Express', trainNumber: '12301', departureTime: '05:30 PM', arrivalTime: '09:00 AM', duration: '15h 30m', availableClasses: ['3A', '2A', '1A'], basePrice: 1800.00),
      Train(name: 'Duronto Express', trainNumber: '12259', departureTime: '08:00 PM', arrivalTime: '11:00 AM', duration: '15h 0m', availableClasses: ['SL', '3A', '2A'], basePrice: 1200.00),
      Train(name: 'Shatabdi Express', trainNumber: '12001', departureTime: '06:00 AM', arrivalTime: '12:00 PM', duration: '6h 0m', availableClasses: ['CC', 'EC'], basePrice: 700.00), // EC for Executive Chair Car
      Train(name: 'Intercity Express', trainNumber: '12127', departureTime: '02:00 PM', arrivalTime: '08:00 PM', duration: '6h 0m', availableClasses: ['CC', '2S'], basePrice: 350.00),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final List<Train> trains = _getMockTrains();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Trains ($numberOfPassengers Pax)'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: trains.isEmpty
          ? Center( /* ... No changes here ... */ )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: trains.length,
              itemBuilder: (context, index) {
                final train = trains[index];
                return Card(
                  /* ... No changes to Card styling ... */
                  color: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    /* ... No changes to leading, title, subtitle, trailing ... */
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                        Icons.train_outlined,
                        color: isDarkMode ? Colors.orange.shade300 : AppTheme.primaryColor,
                        size: 40,
                    ),
                    title: Text(
                      '${train.name} (${train.trainNumber})',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Dep: ${train.departureTime} - Arr: ${train.arrivalTime}', style: TextStyle(color: textColor.withOpacity(0.8))),
                        Text('Duration: ${train.duration}', style: TextStyle(color: textColor.withOpacity(0.8))),
                        const SizedBox(height: 2),
                        Text('Classes: ${train.availableClasses.join(", ")}', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                      ],
                    ),
                    trailing: Text( 
                      'From ₹${train.basePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                          fontSize: 14, 
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainCoachClassSelectionScreen( // Changed navigation
                            train: train,
                            numberOfPassengers: numberOfPassengers,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}