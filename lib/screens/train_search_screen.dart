import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'train_results_screen.dart'; // We will create this next

class TrainSearchScreen extends StatefulWidget {
  const TrainSearchScreen({super.key});

  @override
  State<TrainSearchScreen> createState() => _TrainSearchScreenState();
}

class _TrainSearchScreenState extends State<TrainSearchScreen> {
  final _fromStationController = TextEditingController();
  final _toStationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _numberOfPassengers = 1;

  @override
  void dispose() {
    _fromStationController.dispose();
    _toStationController.dispose();
    super.dispose();
  }

  void _searchTrains() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainResultsScreen(
            fromStation: _fromStationController.text,
            toStation: _toStationController.text,
            numberOfPassengers: _numberOfPassengers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final Color fieldBgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color dropdownIconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Search Trains'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _fromStationController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'From Station',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.departure_board, color: textColor.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter departure station';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toStationController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'To Station',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.pin_drop_outlined, color: textColor.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination station';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // You would typically add a Date Picker here as well
              DropdownButtonFormField<int>(
                value: _numberOfPassengers,
                items: List.generate(6, (index) => index + 1) // Allows 1 to 6 passengers
                    .map((num) => DropdownMenuItem<int>(
                          value: num,
                          child: Text('$num Passenger${num > 1 ? "s" : ""}', style: TextStyle(color: textColor)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _numberOfPassengers = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Passengers',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.people_alt_outlined, color: textColor.withOpacity(0.7)),
                ),
                dropdownColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                iconEnabledColor: dropdownIconColor,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _searchTrains,
                child: const Text('Search Trains', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}