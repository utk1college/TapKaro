import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/screens/payment_screen.dart';
import 'bus_results_screen.dart'; // For Bus class definition

class BusSeatSelectionScreen extends StatefulWidget {
  final Bus bus;
  final int numberOfSeatsToSelect;
  final DateTime journeyDate;

  const BusSeatSelectionScreen({
    super.key,
    required this.bus,
    required this.numberOfSeatsToSelect,
    required this.journeyDate,
  });

  @override
  State<BusSeatSelectionScreen> createState() => _BusSeatSelectionScreenState();
}

class _BusSeatSelectionScreenState extends State<BusSeatSelectionScreen> {
  final List<String> _selectedSeats = [];

  // Bus layout configuration (Example: 2x2 seater with 10 rows + last row of 5)
  final int _rows = 10;
  final int _colsRegular = 4; // 2 seats | Aisle (implicit) | 2 seats
  final int _colsLastRow = 5; // Last row
  final int _totalRegularSeats = 10 * 4; // 10 rows of 2+2
  // final int _totalSeats = (10*4) + 5; // 10 rows of 2+2 and last row of 5

  // Mock booked/ladies seats for UI demo
  final Set<String> _bookedSeats = {"2A", "3D", "5C", "LR2", "9B"};
  final Set<String> _ladiesSeats = {"1A", "1B"}; // Typically first few seats

  void _toggleSeatSelection(String seatId) {
    // Cannot select booked seats
    if (_bookedSeats.contains(seatId)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This seat is already booked.'), duration: Duration(seconds: 2)));
      return;
    }

    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length < widget.numberOfSeatsToSelect) {
          _selectedSeats.add(seatId);
        } else {
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

  Widget _buildSeatIcon(String seatId, bool isDarkMode) {
    bool isSelected = _selectedSeats.contains(seatId);
    bool isBooked = _bookedSeats.contains(seatId);
    bool isLadies = _ladiesSeats.contains(seatId);

    Color seatColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    Color borderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    IconData? iconData; // For Ladies/Special seats

    if (isBooked) {
      seatColor = isDarkMode ? Colors.black38 : Colors.grey.shade500;
      borderColor = seatColor;
    } else if (isSelected) {
      seatColor = AppTheme.accentColor; // Or your theme's selection color
      borderColor = AppTheme.primaryColor;
    } else if (isLadies) {
      seatColor = isDarkMode ? Colors.pink.shade700.withOpacity(0.5) : Colors.pink.shade100;
      borderColor = isDarkMode ? Colors.pink.shade400 : Colors.pink.shade300;
      iconData = Icons.female_outlined;
    }

    return GestureDetector(
      onTap: () => _toggleSeatSelection(seatId),
      child: Container(
        margin: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
        ),
        child: Center(
          child: iconData != null
              ? Icon(iconData, size: 16, color: isDarkMode ? Colors.pink.shade100 : Colors.pink.shade700)
              : Text(
                  seatId,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                  ),
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
    final double totalPrice = widget.bus.pricePerSeat * _selectedSeats.length;
    final bool canProceed = _selectedSeats.length == widget.numberOfSeatsToSelect;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.bus.operatorName),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: screenTextColor,
        iconTheme: IconThemeData(color: screenTextColor),
         bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '${widget.bus.busType} - ${DateFormat('dd MMM').format(widget.journeyDate)}',
              style: TextStyle(color: screenTextColor.withOpacity(0.8), fontSize: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Driver and Door indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.person_pin_circle_outlined, color: screenTextColor.withOpacity(0.7)),
                  const SizedBox(width:4),
                  Text("Driver", style: TextStyle(fontSize: 12, color: screenTextColor.withOpacity(0.7))),
                ]),
                Text("Door", style: TextStyle(fontSize: 12, color: screenTextColor.withOpacity(0.7))),
              ],
            ),
          ),
          // Simple steering wheel icon at the top left of the grid area
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.settings_input_svideo_outlined , size: 30, color: screenTextColor.withOpacity(0.5)), // Steering wheel like icon
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 2 seats | Aisle | 2 seats (5 columns in total for visual spacing)
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: (_rows + 1) * 5, // 10 normal rows + 1 last row, 5 columns each visual cell
                itemBuilder: (context, index) {
                  int row = index ~/ 5; // 0 to 10
                  int col = index % 5;  // 0 to 4

                  if (row < _rows) { // Regular 2x2 rows
                    if (col == 2) return Container(); // Aisle
                    String seatLetter = "";
                    if (col == 0) {
                      seatLetter = "A";
                    } else if (col == 1) seatLetter = "B";
                    else if (col == 3) seatLetter = "C";
                    else if (col == 4) seatLetter = "D";
                    String seatId = "${row + 1}$seatLetter";
                    return _buildSeatIcon(seatId, isDarkMode);
                  } else { // Last row (row == _rows)
                    // Example: LR1 LR2 LR3 LR4 LR5  (Last Row seats)
                    if (col < _colsLastRow) {
                         String seatId = "LR${col + 1}";
                         return _buildSeatIcon(seatId, isDarkMode);
                    }
                    return Container(); // Empty if more cells than seats in last row
                  }
                },
              ),
            ),
          ),
          // Legend for seat types
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                _legendItem(isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300, "Available", isDarkMode),
                _legendItem(AppTheme.accentColor, "Selected", isDarkMode),
                _legendItem(isDarkMode ? Colors.black38 : Colors.grey.shade500, "Booked", isDarkMode),
                _legendItem(isDarkMode ? Colors.pink.shade700.withOpacity(0.5) : Colors.pink.shade100, "Ladies", isDarkMode, icon: Icons.female_outlined),
              ],
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
                  maxLines: 2, overflow: TextOverflow.ellipsis,
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
                            prefilledIdentifier: 'f11e0a77-366f-48a0-9f1e-51594b7f0c03',
                            identifierIsUserId: true, // Important: tells PaymentScreen this is a user ID
                            amount: totalPrice,
                            description: "Bus Ticket: ${widget.bus.operatorName}\nSeats: ${_selectedSeats.join(', ')}\nJourney Date: ${DateFormat('dd MMM yyyy').format(widget.journeyDate)}",
                          ),
                        ),
                      );
                    }
                  : null,
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

  Widget _legendItem(Color color, String text, bool isDarkMode, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18, height: 18,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
          ),
          child: icon != null ? Icon(icon, size: 12, color: isDarkMode ? Colors.pink.shade100 : Colors.pink.shade700) : null,
        ),
        Text(text, style: TextStyle(fontSize: 11, color: isDarkMode ? AppTheme.textPrimaryColorDark.withOpacity(0.8) : AppTheme.textPrimaryColorLight.withOpacity(0.8))),
      ],
    );
  }
}