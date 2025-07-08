import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/screens/payment_screen.dart';
import 'flight_results_screen.dart'; // For Flight class definition

class FlightSeatSelectionScreen extends StatefulWidget {
  final Flight flight;
  final int numberOfSeatsToSelect; // Added

  const FlightSeatSelectionScreen({
    super.key,
    required this.flight,
    required this.numberOfSeatsToSelect, // Added
  });

  @override
  State<FlightSeatSelectionScreen> createState() => _FlightSeatSelectionScreenState();
}

class _FlightSeatSelectionScreenState extends State<FlightSeatSelectionScreen> {
  final List<String> _selectedSeats = []; // Changed to List
  final int _totalRows = 10;
  final int _seatsPerRow = 6; // A-F

  void _toggleSeatSelection(String seatId) {
    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length < widget.numberOfSeatsToSelect) {
          _selectedSeats.add(seatId);
        } else {
          // Optionally show a message if trying to select more than allowed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select ${widget.numberOfSeatsToSelect} seat(s).'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Widget _buildSeat(String seatId, bool isDarkMode) {
    final bool isSelected = _selectedSeats.contains(seatId);
    // You might want to add a state for 'unavailable' seats in a real app
    // final bool isAvailable = true;

    Color seatColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    Color borderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    double borderWidth = 1;

    if (isSelected) {
      seatColor = AppTheme.accentColor;
      borderColor = AppTheme.primaryColor;
      borderWidth = 2;
    }
    // else if (!isAvailable) {
    //   seatColor = isDarkMode ? Colors.black45 : Colors.grey.shade500;
    //   borderColor = isDarkMode ? Colors.black45 : Colors.grey.shade500;
    // }

    final Color textColor = isSelected
        ? Colors.white
        : (isDarkMode ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () => _toggleSeatSelection(seatId), // Updated onTap
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: borderWidth)
        ),
        child: Center(
          child: Text(
            seatId.substring(seatId.indexOf('-') + 1),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color screenTextColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final double totalPrice = widget.flight.price * _selectedSeats.length;
    final bool canProceed = _selectedSeats.length == widget.numberOfSeatsToSelect;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Your Seat(s)'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: screenTextColor,
        iconTheme: IconThemeData(color: screenTextColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '${widget.flight.airline} ${widget.flight.flightNumber}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: screenTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select ${widget.numberOfSeatsToSelect} seat(s)',
                  style: TextStyle(fontSize: 16, color: screenTextColor.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Reduced vertical margin
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode? Colors.grey.shade800.withOpacity(0.5) : Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDarkMode? Colors.grey.shade700 : Colors.grey.shade300)
            ),
            child: const Text("✈️ FRONT OF CABIN ✈️", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder( // Similar GridView as before
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _seatsPerRow + 2, // Seats + RowNum + Aisle
                  childAspectRatio: 1.0, // Adjust for better visual
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: (_totalRows +1) * (_seatsPerRow + 2), // +1 for header row
                itemBuilder: (context, index) {
                  int effectiveSeatsPerRow = _seatsPerRow;
                  int colsWithLabelsAndAisle = effectiveSeatsPerRow + 2;

                  int r = index ~/ colsWithLabelsAndAisle;
                  int c = index % colsWithLabelsAndAisle;

                  if (r == 0) { // Header Row
                    if (c == 0) return Container();
                    if (c == (effectiveSeatsPerRow ~/ 2) + 1) return Container(); // Aisle
                    int seatCharIndex = c -1;
                    if (c > (effectiveSeatsPerRow ~/ 2) + 1) seatCharIndex--;
                    if (seatCharIndex < effectiveSeatsPerRow) {
                       return Center(child: Text(String.fromCharCode('A'.codeUnitAt(0) + seatCharIndex), style: TextStyle(color: screenTextColor, fontWeight: FontWeight.bold)));
                    }
                    return Container();
                  }
                  int actualRow = r;
                  if (c == 0) { // Row Number
                    return Center(child: Text(actualRow.toString(), style: TextStyle(color: screenTextColor, fontWeight: FontWeight.bold)));
                  }
                  if (c == (effectiveSeatsPerRow ~/ 2) + 1) { // Aisle
                    return Container();
                  }
                  int seatIndexInRow = c -1;
                  if (c > (effectiveSeatsPerRow ~/ 2) + 1) seatIndexInRow--;
                  if (seatIndexInRow < 0 || seatIndexInRow >= effectiveSeatsPerRow) return Container();

                  String seatId = '$actualRow-${String.fromCharCode('A'.codeUnitAt(0) + seatIndexInRow)}';
                  return _buildSeat(seatId, isDarkMode);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Seats (${_selectedSeats.length}/${widget.numberOfSeatsToSelect}):',
                  style: TextStyle(fontSize: 16, color: screenTextColor.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedSeats.isEmpty ? 'None' : _selectedSeats.join(', '),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: screenTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppTheme.primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canProceed
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            prefilledIdentifier: '4a6fbd6f-d3cc-4cee-a888-2ab6184dd17c',
                            identifierIsUserId: true,
                            amount: totalPrice,
                            description: "Flight Ticket: ${widget.flight.airline} ${widget.flight.flightNumber}\nSeats: ${_selectedSeats.join(', ')}\nDeparture: ${widget.flight.departureTime}",
                          ),
                        ),
                      );
                    }
                  : null, // Disable button if not all seats are selected
              child: Text(
                canProceed
                  ? 'Proceed to Pay ₹${totalPrice.toStringAsFixed(2)}'
                  : 'Select ${widget.numberOfSeatsToSelect - _selectedSeats.length} more seat(s)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}