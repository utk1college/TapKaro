import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart'; // Assuming AppTheme is defined here
import 'package:payment_app/screens/payment_screen.dart'; // Ensure this path is correct

// Define SeatStatus here as it's primarily used by this screen
enum SeatStatus {
  available,
  selected,
  booked,
  space,
}

class SeatSelectionScreen extends StatefulWidget {
  final String movieName;
  final String? movieImage; // Optional
  final String theaterName;
  final String timeSlot;
  final int numberOfSeatsToSelect;

  const SeatSelectionScreen({
    super.key,
    required this.movieName,
    this.movieImage,
    required this.theaterName,
    required this.timeSlot,
    required this.numberOfSeatsToSelect,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<List<SeatStatus>> _seatLayout = [];
  final List<String> _userSelectedSeatIds = []; // Stores IDs like "A1", "B2"

  // Mock layout dimensions
  final int _seatRows = 7;
  final int _seatCols = 9;

  @override
  void initState() {
    super.initState();
    _initializeMockSeatLayout();
  }

  void _initializeMockSeatLayout() {
    _seatLayout = List.generate(_seatRows, (row) {
      return List.generate(_seatCols, (col) {
        if (col == 2 || col == _seatCols - 3) {
          return SeatStatus.space;
        }
        // Example: Make some seats booked (can be more dynamic)
        if ((row == 2 && col > 3 && col < 6) || (row == 4 && col == 4)) {
          return SeatStatus.booked;
        }
        // Example: If a specific movie is chosen, book another seat
        // This is just a placeholder for more complex backend logic
        if (widget.movieName == 'Cosmic Drift' && row == 0 && col == 0) {
            return SeatStatus.booked;
        }
        return SeatStatus.available;
      });
    });
    _userSelectedSeatIds.clear();
    if (mounted) {
      setState(() {});
    }
  }

  void _onSeatTap(int row, int col) {
    if (_seatLayout[row][col] == SeatStatus.booked || _seatLayout[row][col] == SeatStatus.space) {
      return;
    }

    final seatId = '${String.fromCharCode(65 + row)}${col + 1}';

    setState(() {
      if (_seatLayout[row][col] == SeatStatus.available) {
        if (_userSelectedSeatIds.length < widget.numberOfSeatsToSelect) {
          _seatLayout[row][col] = SeatStatus.selected;
          _userSelectedSeatIds.add(seatId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only select ${widget.numberOfSeatsToSelect} seat(s). Deselect one to choose another.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      } else if (_seatLayout[row][col] == SeatStatus.selected) {
        _seatLayout[row][col] = SeatStatus.available;
        _userSelectedSeatIds.remove(seatId);
      }
    });
  }

  void _proceedToPayment() {
    if (_userSelectedSeatIds.length != widget.numberOfSeatsToSelect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select exactly ${widget.numberOfSeatsToSelect} seat(s). You have selected ${_userSelectedSeatIds.length}.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double pricePerTicket = 150.0; // Example price
    double totalAmount = widget.numberOfSeatsToSelect * pricePerTicket;
    String paymentDescription =
        '${widget.numberOfSeatsToSelect} ticket(s) for ${widget.movieName} at ${widget.timeSlot} in ${widget.theaterName}. Seats: ${_userSelectedSeatIds.join(", ")}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
           prefilledIdentifier: '88b0eb61-79d1-4c1d-a642-5abc544e59fe', // The specific biller ID
           identifierIsUserId: true,
          amount: totalAmount,
          description: paymentDescription,
        ),
      ),
    );
  }

   Widget _buildSectionTitle(String title, Color textColor) {
    return Text( title, style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: textColor, ), );
  }


  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final Color accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final Color cardBackgroundColor = isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Select Seats for ${widget.movieName}'),
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Your Selection', primaryTextColor),
            const SizedBox(height: 8),
            Text(
              '${widget.movieName} at ${widget.theaterName}, ${widget.timeSlot}',
              style: TextStyle(fontSize: 16, color: primaryTextColor.withOpacity(0.8)),
            ),
            Text(
              'Seats to select: ${widget.numberOfSeatsToSelect}',
              style: TextStyle(fontSize: 14, color: primaryTextColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Seat Layout', primaryTextColor),
             const SizedBox(height: 12),
            Container( // Screen Indicator
              width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 10.0), padding: const EdgeInsets.symmetric(vertical: 5.0),
              decoration: BoxDecoration( color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(5), ),
              child: Text( 'SCREEN THIS WAY', textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 2), ),
            ),
            if (_seatLayout.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Container( // Seat Grid Container
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration( color: cardBackgroundColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12), ),
                child: Column(
                  children: List.generate(_seatLayout.length, (rowIndex) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_seatLayout[rowIndex].length, (colIndex) {
                        final seatId = '${String.fromCharCode(65 + rowIndex)}${colIndex + 1}';
                        return SeatWidget(
                          status: _seatLayout[rowIndex][colIndex],
                          seatId: (_seatLayout[rowIndex][colIndex] != SeatStatus.space && _seatLayout[rowIndex][colIndex] != SeatStatus.booked) ? seatId : '',
                          isDarkMode: isDarkMode,
                          onTap: () => _onSeatTap(rowIndex, colIndex),
                        );
                      }),
                    );
                  }),
                ),
              ),
            const SizedBox(height: 10),
            Wrap( // Legend
              alignment: WrapAlignment.center, spacing: 15.0, runSpacing: 8.0,
              children: [
                _SeatLegendItem(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300, text: 'Available', isDarkMode: isDarkMode),
                _SeatLegendItem(color: accentColor, text: 'Selected', isDarkMode: isDarkMode),
                _SeatLegendItem(color: isDarkMode ? Colors.red.shade800 : Colors.red.shade400, text: 'Booked', isDarkMode: isDarkMode),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Selected on Grid: ${_userSelectedSeatIds.length} / ${widget.numberOfSeatsToSelect} (${_userSelectedSeatIds.join(", ")})',
                style: TextStyle(color: primaryTextColor.withOpacity(0.8), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 70), // Space for bottom nav bar
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom( backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), ), textStyle: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, ), ),
          child: Text('Proceed to Payment (${widget.numberOfSeatsToSelect * 150.0} \u{20B9})'), // Example price
        ),
      ),
    );
  }
}

// --- SeatWidget (kept within seat_selection_screen.dart) ---
class SeatWidget extends StatelessWidget {
  final SeatStatus status;
  final VoidCallback onTap;
  final String seatId;
  final bool isDarkMode;

  const SeatWidget({
    super.key,
    required this.status,
    required this.onTap,
    this.seatId = '',
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Color seatColor;
    Widget childContent;
    final Color accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;

    switch (status) {
      case SeatStatus.available:
        seatColor = isDarkMode ? Colors.grey.shade700.withOpacity(0.7) : Colors.grey.shade300;
        childContent = Center(child: Text(seatId, style: TextStyle(fontSize: 8, color: isDarkMode ? Colors.white54 : Colors.black54)));
        break;
      case SeatStatus.selected:
        seatColor = accentColor;
        childContent = Icon(Icons.check_circle_outline, color: Colors.white, size: 16);
        break;
      case SeatStatus.booked:
        seatColor = isDarkMode ? Colors.red.shade800.withOpacity(0.8) : Colors.red.shade300;
        childContent = Icon(Icons.person_off_outlined, color: Colors.white.withOpacity(0.6), size: 16);
        break;
      case SeatStatus.space:
        return Container(width: 28, height: 28, margin: const EdgeInsets.all(2.5));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: status == SeatStatus.available
                ? (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: childContent,
      ),
    );
  }
}

// --- _SeatLegendItem (kept within seat_selection_screen.dart) ---
class _SeatLegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final bool isDarkMode;

  const _SeatLegendItem({
    // super.key, // Not strictly necessary for private widgets
    required this.color,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: isDarkMode ? AppTheme.textSecondaryColorDark.withOpacity(0.8) : AppTheme.textSecondaryColorLight),
        ),
      ],
    );
  }
}
