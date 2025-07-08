import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payment_app/utils/theme.dart';
import 'bus_seat_selection_screen.dart'; // We will create this next

// Mock data structure for a Bus
class Bus {
  final String operatorName;
  final String busType; // e.g., "AC Seater (2+2)", "Volvo Multi-Axle", "AC Sleeper (2+1)"
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double pricePerSeat;
  final double rating; // Optional
  final List<String> amenities; // e.g., ["AC", "WiFi", "Charging Point"]

  Bus({
    required this.operatorName,
    required this.busType,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.pricePerSeat,
    this.rating = 4.0,
    this.amenities = const [],
  });
}

class BusResultsScreen extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final DateTime journeyDate;
  final int numberOfPassengers;

  const BusResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.journeyDate,
    required this.numberOfPassengers,
  });

  // Mock bus data
  List<Bus> _getMockBuses() {
    return [
      Bus(operatorName: 'Sharma Travels', busType: 'AC Seater (2+2)', departureTime: '09:00 PM', arrivalTime: '06:00 AM', duration: '9h 0m', pricePerSeat: 750.00, rating: 4.2, amenities: ['AC', 'Charging Point']),
      Bus(operatorName: 'VRL Travels', busType: 'Volvo Multi-Axle AC Semi-Sleeper', departureTime: '10:30 PM', arrivalTime: '07:15 AM', duration: '8h 45m', pricePerSeat: 950.00, rating: 4.5, amenities: ['AC', 'WiFi', 'Blankets']),
      Bus(operatorName: 'KSRTC (Karnataka)', busType: 'Non-AC Seater/Sleeper', departureTime: '11:00 PM', arrivalTime: '08:30 AM', duration: '9h 30m', pricePerSeat: 550.00, rating: 3.8),
      Bus(operatorName: 'Orange Travels', busType: 'AC Sleeper (2+1)', departureTime: '09:45 PM', arrivalTime: '05:30 AM', duration: '7h 45m', pricePerSeat: 1100.00, rating: 4.7, amenities: ['AC', 'TV', 'Water Bottle']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final List<Bus> buses = _getMockBuses(); // In real app, filter by route/date

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Available Buses ($numberOfPassengers Pax)'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '$fromCity to $toCity on ${DateFormat('dd MMM, yyyy').format(journeyDate)}',
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
            ),
          ),
        ),
      ),
      body: buses.isEmpty
          ? Center(
              child: Text(
              'No buses found for this route on ${DateFormat('dd MMM').format(journeyDate)}.',
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                return Card(
                  color: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell( // Make the whole card tappable
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusSeatSelectionScreen(
                            bus: bus,
                            numberOfSeatsToSelect: numberOfPassengers,
                            journeyDate: journeyDate, // Pass date for display or logic
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bus.operatorName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: textColor, fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (bus.rating > 0)
                                Chip(
                                  avatar: Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                                  label: Text(bus.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                                  backgroundColor: isDarkMode ? Colors.black38 : Colors.amber.shade100,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  labelPadding: const EdgeInsets.only(left: 2),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )
                            ],
                          ),
                          Text(bus.busType, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bus.departureTime, style: TextStyle(fontWeight: FontWeight.w500, color: textColor, fontSize: 15)),
                                  Text('Departure', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.arrow_forward, color: textColor.withOpacity(0.5), size: 18),
                                  Text(bus.duration, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(bus.arrivalTime, style: TextStyle(fontWeight: FontWeight.w500, color: textColor, fontSize: 15)),
                                  Text('Arrival', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          if (bus.amenities.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: bus.amenities.map((amenity) => Chip(
                                label: Text(amenity, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.9))),
                                backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                            )
                          ],
                           const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '₹${bus.pricePerSeat.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                                  fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}