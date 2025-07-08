import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:payment_app/utils/theme.dart';
import 'bus_results_screen.dart';

class BusSearchScreen extends StatefulWidget {
  const BusSearchScreen({super.key});

  @override
  State<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends State<BusSearchScreen> {
  final _fromCityController = TextEditingController();
  final _toCityController = TextEditingController();
  final _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _numberOfPassengers = 1;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _fromCityController.dispose();
    _toCityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Allow today
      lastDate: DateTime.now().add(const Duration(days: 90)), // Allow booking 90 days in advance
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM, yyyy').format(picked); // Format for display
      });
    }
  }

  void _searchBuses() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date of journey.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusResultsScreen(
            fromCity: _fromCityController.text,
            toCity: _toCityController.text,
            journeyDate: _selectedDate!,
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
        title: const Text('Search Buses'),
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
                controller: _fromCityController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'From City',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.departure_board_outlined, color: textColor.withOpacity(0.7)),
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
                controller: _toCityController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'To City',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  // CORRECTED ICON HERE:
                  prefixIcon: Icon(Icons.pin_drop_outlined, color: textColor.withOpacity(0.7)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Date of Journey',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: fieldBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: textColor.withOpacity(0.7)),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select date of journey';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _numberOfPassengers,
                items: List.generate(10, (index) => index + 1) // Allows 1 to 10 passengers
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
                  prefixIcon: Icon(Icons.people_outline, color: textColor.withOpacity(0.7)),
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
                onPressed: _searchBuses,
                child: const Text('Search Buses', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}