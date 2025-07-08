import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'flight_seat_selection_screen.dart';

// Mock data structure for a flight
class Flight {
  final String airline;
  final String flightNumber;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price; // Price per seat
  final String fromCity;
  final String toCity;

  Flight({
    required this.airline,
    required this.flightNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.fromCity,
    required this.toCity,
  });
}

class FlightResultsScreen extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final int numberOfPassengers; // Added

  const FlightResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.numberOfPassengers, // Added
  });

  // Mock flight data - In a real app, you'd filter/fetch based on seat availability
  List<Flight> _getMockFlights() {
    return [
      Flight(airline: 'Indigo', flightNumber: '6E 234', departureTime: '08:00 AM', arrivalTime: '10:00 AM', duration: '2h 0m', price: 4500.00, fromCity: fromCity, toCity: toCity),
      Flight(airline: 'Air India', flightNumber: 'AI 502', departureTime: '10:30 AM', arrivalTime: '12:45 PM', duration: '2h 15m', price: 5200.00, fromCity: fromCity, toCity: toCity),
      Flight(airline: 'Vistara', flightNumber: 'UK 879', departureTime: '01:15 PM', arrivalTime: '03:20 PM', duration: '2h 5m', price: 4850.00, fromCity: fromCity, toCity: toCity),
      Flight(airline: 'SpiceJet', flightNumber: 'SG 123', departureTime: '04:00 PM', arrivalTime: '06:10 PM', duration: '2h 10m', price: 4300.00, fromCity: fromCity, toCity: toCity),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final List<Flight> flights = _getMockFlights();

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Flights: $fromCity to $toCity ($numberOfPassengers Pax)'), // Show passenger count
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: flights.isEmpty
          ? Center(
              child: Text(
              'No flights found for this route.', // Ideally, also check "for $numberOfPassengers passengers"
              style: TextStyle(color: textColor, fontSize: 16),
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: flights.length,
              itemBuilder: (context, index) {
                final flight = flights[index];
                return Card(
                  color: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                        Icons.flight_takeoff_outlined,
                        color: isDarkMode ? Colors.blue.shade300 : AppTheme.primaryColor,
                        size: 40,
                    ),
                    title: Text(
                      '${flight.airline} ${flight.flightNumber}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Dep: ${flight.departureTime} - Arr: ${flight.arrivalTime}', style: TextStyle(color: textColor.withOpacity(0.8))),
                        Text('Duration: ${flight.duration}', style: TextStyle(color: textColor.withOpacity(0.8))),
                        const SizedBox(height: 2),
                        Text('Price per seat', style:TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)))
                      ],
                    ),
                    trailing: Text(
                      '₹${flight.price.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                          fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlightSeatSelectionScreen(
                            flight: flight,
                            numberOfSeatsToSelect: numberOfPassengers, // Pass passenger count
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