import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'flight_results_screen.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _numberOfPassengers = 1; // Default to 1 passenger

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _searchFlights() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlightResultsScreen(
            fromCity: _fromController.text,
            toCity: _toController.text,
            numberOfPassengers: _numberOfPassengers, // Pass the number of passengers
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
        title: const Text('Search Flights'),
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
                controller: _fromController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'From',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.flight_takeoff, color: textColor.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter departure city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'To',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                   prefixIcon: Icon(Icons.flight_land, color: textColor.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown for number of passengers
              DropdownButtonFormField<int>(
                value: _numberOfPassengers,
                items: List.generate(5, (index) => index + 1) // Allows 1 to 5 passengers
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
                  prefixIcon: Icon(Icons.people_alt_outlined, color: textColor.withOpacity(0.7))
                ),
                dropdownColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                iconEnabledColor: dropdownIconColor,
                 style: TextStyle(color: textColor), // Style for selected item text
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
                onPressed: _searchFlights,
                child: const Text('Search Flights', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}