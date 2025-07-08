import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/screens/payment_screen.dart';
import 'train_results_screen.dart'; // For Train class definition

class TrainSeatSelectionScreen extends StatefulWidget {
  final Train train;
  final int numberOfSeatsToSelect;
  final String selectedCoachType;
  final double pricePerSeat;

  const TrainSeatSelectionScreen({
    super.key,
    required this.train,
    required this.numberOfSeatsToSelect,
    required this.selectedCoachType,
    required this.pricePerSeat,
  });

  @override
  State<TrainSeatSelectionScreen> createState() => _TrainSeatSelectionScreenState();
}

class _TrainSeatSelectionScreenState extends State<TrainSeatSelectionScreen> {
  final List<String> _selectedSeats = [];
  late List<String> _availableCoachNumbers;
  late String _currentDisplayCoachNumber;

  int _gridColumns = 3;
  int _slotsPerBay = 3;
  int _numberOfBaysToDisplay = 9;
  int _numberOfRowsUntukChairCar = 15;

  final Set<String> _mockBookedSeatIds = {};

  @override
  void initState() {
    super.initState();
    _updateCoachLayoutConfig();
    _generateMockBookedSeatsForCurrentCoach();
  }

  void _updateCoachLayoutConfig() {
    // Determine available coach numbers and layout based on selectedCoachType
    switch (widget.selectedCoachType) {
      case "SL":
        _availableCoachNumbers = ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9"];
        _gridColumns = 3; // Main (LB,MB,UB) | Aisle | Side (SL,gap,SU)
        _slotsPerBay = 3; // Vertical slots for UB, MB, LB
        _numberOfBaysToDisplay = 9; // Standard SL coaches have 9 bays of 8 berths = 72
        break;
      case "3A":
      case "3E":
        _availableCoachNumbers = widget.selectedCoachType == "3A"
            ? ["B1", "B2", "B3", "B4", "B5"]
            : ["M1", "M2", "M3"]; // Using M for 3E as BE sometimes clashes
        _gridColumns = 3;
        _slotsPerBay = 3;
        _numberOfBaysToDisplay = 8; // Typically 8 bays of 8 berths = 64 (or more in LHB)
        if (widget.selectedCoachType == "3E") _numberOfBaysToDisplay = 9; // 3E might have more
        break;
      case "2A":
        _availableCoachNumbers = ["A1", "A2", "A3", "H1"]; // H1 for First AC/2AC combo
        _gridColumns = 3; // Main (LB,UB) | Aisle | Side (SL,SU)
        _slotsPerBay = 2; // Vertical slots for UB, LB
        _numberOfBaysToDisplay = 8; // Approx 8 bays of 6 berths = 48 (or more in LHB e.g. 52, 54)
        break;
      case "CC": // AC Chair Car
        _availableCoachNumbers = ["C1", "C2", "C3", "C4", "C5"];
        _gridColumns = 7; // W M A | Aisle | W M A (Actual 3x3, so 7 cols with aisle)
        _slotsPerBay = 1; // Single row of seats
        _numberOfRowsUntukChairCar = 13; // Approx 13 rows * 6 seats = 78
        break;
      case "2S": // Second Sitting
         _availableCoachNumbers = ["D1", "D2", "D3", "D4", "D5", "D6", "D7"];
        _gridColumns = 7; // W M A | Aisle | W M A (or similar 3x3 or 3x2)
        _slotsPerBay = 1;
        _numberOfRowsUntukChairCar = 18; // Approx 18 rows * 6 seats = 108
        break;
      default:
        _availableCoachNumbers = ["G1", "G2"];
        _gridColumns = 3;
        _slotsPerBay = 3;
        _numberOfBaysToDisplay = 9;
        break;
    }
    if (_availableCoachNumbers.isNotEmpty) {
      _currentDisplayCoachNumber = _availableCoachNumbers.first;
    } else {
      _currentDisplayCoachNumber = "N/A"; // Fallback
      _availableCoachNumbers = ["N/A"];
    }
    _selectedSeats.clear();
  }

  void _generateMockBookedSeatsForCurrentCoach() {
    _mockBookedSeatIds.clear();
    final String coach = _currentDisplayCoachNumber;
    if (coach == "N/A") return;

    // Generate some pseudo-random booked seats for visual effect
    // These IDs must match the format generated in _buildBerthOrSeatWidget
    if (widget.selectedCoachType == "SL") {
      _mockBookedSeatIds.addAll(["$coach-5MB", "$coach-12UB", "$coach-23SL", "$coach-30MB", "$coach-45MB", "$coach-50UB", "$coach-60SL"]);
    } else if (widget.selectedCoachType == "3A" || widget.selectedCoachType == "3E") {
      _mockBookedSeatIds.addAll(["$coach-2MB", "$coach-10UB", "$coach-19SL", "$coach-28MB", "$coach-35MB"]);
    } else if (widget.selectedCoachType == "2A") {
      _mockBookedSeatIds.addAll(["$coach-1LB", "$coach-6SU", "$coach-10UB", "$coach-15LB", "$coach-22SU"]);
    } else if (widget.selectedCoachType == "CC" || widget.selectedCoachType == "2S") {
      // Seat numbers are S<number><type>, e.g., S5A, S12W
      // Note: The seat number generation for CC/2S was S<number><type> e.g. "C1-S5A"
      _mockBookedSeatIds.addAll(["$coach-S3A", "$coach-S8W", "$coach-S12M", "$coach-S20A", "$coach-S25W"]);
    }
  }

  void _toggleSeatSelection(String fullSeatId) {
    setState(() {
      if (_selectedSeats.contains(fullSeatId)) {
        _selectedSeats.remove(fullSeatId);
      } else {
        if (_selectedSeats.length < widget.numberOfSeatsToSelect) {
          _selectedSeats.add(fullSeatId);
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

  Widget _buildBerthOrSeatWidget({
    required String coachNumber,
    required int itemIndex,
    required bool isDarkMode,
  }) {
    String berthTypeLabel = ""; // e.g., UB, MB, LB, SL, SU, W, M, A
    String displayLabel = "";   // e.g., "7 UB", "15 SL", "10W"
    String fullSeatId = "";     // Unique ID for selection, e.g., "S1-7UB"
    bool isWindow = false;
    bool isEmptyCell = false;
    bool isAisleVisual = false;

    int actualGridColumn = itemIndex % _gridColumns;
    int gridRowAbsolute = itemIndex ~/ _gridColumns;

    if (widget.selectedCoachType == "SL" || widget.selectedCoachType == "3A" || widget.selectedCoachType == "3E") {
      int logicalBayIndex = gridRowAbsolute ~/ _slotsPerBay; // Bay number (0-indexed)
      int verticalSlotInBay = gridRowAbsolute % _slotsPerBay; // Position in bay (0=Upper, 1=Middle, 2=Lower)
      int berthNumBase = logicalBayIndex * 8; // Each bay has 8 berths

      if (actualGridColumn == 0) { // Main Berths (one side of compartment)
        if (verticalSlotInBay == 0) { berthTypeLabel = "UB"; displayLabel = "${berthNumBase + 3} UB"; }
        else if (verticalSlotInBay == 1) { berthTypeLabel = "MB"; displayLabel = "${berthNumBase + 2} MB"; }
        else { berthTypeLabel = "LB"; displayLabel = "${berthNumBase + 1} LB"; }
      } else if (actualGridColumn == 1) { // Aisle
        isEmptyCell = true; isAisleVisual = true;
      } else if (actualGridColumn == 2) { // Side Berths
        isWindow = true;
        if (verticalSlotInBay == 0) { berthTypeLabel = "SU"; displayLabel = "${berthNumBase + 8} SU"; } // SU
        else if (verticalSlotInBay == 2) { berthTypeLabel = "SL"; displayLabel = "${berthNumBase + 7} SL"; } // SL
        else { isEmptyCell = true; } // No Side Middle Berth
      } else { isEmptyCell = true; } // Should not happen with _gridColumns = 3
      if (!isEmptyCell) fullSeatId = "$coachNumber-${displayLabel.replaceAll(' ', '')}";

    } else if (widget.selectedCoachType == "2A") {
      int logicalBayIndex = gridRowAbsolute ~/ _slotsPerBay; // Bay number (0-indexed)
      int verticalSlotInBay = gridRowAbsolute % _slotsPerBay; // Position in bay (0=Upper, 1=Lower)
      int berthNumBase = logicalBayIndex * 6; // Each bay has 6 berths (4 main, 2 side)

      if (actualGridColumn == 0) { // Main Berths (one side of compartment)
        if (verticalSlotInBay == 0) { berthTypeLabel = "UB"; displayLabel = "${berthNumBase + 2} UB"; }
        else { berthTypeLabel = "LB"; displayLabel = "${berthNumBase + 1} LB"; }
      } else if (actualGridColumn == 1) { // Aisle
        isEmptyCell = true; isAisleVisual = true;
      } else if (actualGridColumn == 2) { // Side Berths
        isWindow = true;
        if (verticalSlotInBay == 0) { berthTypeLabel = "SU"; displayLabel = "${berthNumBase + (4 + 2)} SU"; } // Side Upper (e.g., 6 for bay 0)
        else { berthTypeLabel = "SL"; displayLabel = "${berthNumBase + (4 + 1)} SL"; } // Side Lower (e.g., 5 for bay 0)
      } else { isEmptyCell = true; }
      if (!isEmptyCell) fullSeatId = "$coachNumber-${displayLabel.replaceAll(' ', '')}";

    } else if (widget.selectedCoachType == "CC" || widget.selectedCoachType == "2S") {
      // Layout W M A | Aisle | W M A (_gridColumns = 7)
      int seatsInRowSegment = 3;
      int aisleColumnIndex = 3;
      int seatNumberInRowLayout = -1;

      if (actualGridColumn < aisleColumnIndex) { // Left segment
        seatNumberInRowLayout = actualGridColumn;
      } else if (actualGridColumn > aisleColumnIndex) { // Right segment
        seatNumberInRowLayout = seatsInRowSegment + (actualGridColumn - aisleColumnIndex - 1);
      }

      if (actualGridColumn == 0 || actualGridColumn == aisleColumnIndex + 1) { berthTypeLabel = "W"; isWindow = true; }
      else if (actualGridColumn == 1 || actualGridColumn == aisleColumnIndex + 2) { berthTypeLabel = "M"; }
      else if (actualGridColumn == 2 || actualGridColumn == aisleColumnIndex + 3) { berthTypeLabel = "A"; }
      else if (actualGridColumn == aisleColumnIndex) { isEmptyCell = true; isAisleVisual = true; }
      else { isEmptyCell = true; } // Should not happen

      if (!isEmptyCell) {
        int totalSeatsBeforeThisRow = gridRowAbsolute * (2 * seatsInRowSegment); // 6 seats per full row
        int seatNumber = totalSeatsBeforeThisRow + seatNumberInRowLayout + 1;
        displayLabel = "$seatNumber$berthTypeLabel";
        fullSeatId = "$coachNumber-S$seatNumber$berthTypeLabel";
      }
    } else { // Default/Unknown
      displayLabel = "G${itemIndex + 1}";
      isEmptyCell = false; // Assuming it's a seat
      fullSeatId = "$coachNumber-$displayLabel";
    }

    if (isEmptyCell) {
      return Container(
        margin: const EdgeInsets.all(1.5), // Smaller margin for aisles
        child: isAisleVisual ? Center(child: Icon(Icons.more_vert_rounded, size: 14, color: Colors.grey.withOpacity(0.2))) : null,
      );
    }

    final bool isSelected = _selectedSeats.contains(fullSeatId);
    final bool isBooked = _mockBookedSeatIds.contains(fullSeatId);

    Color seatColor = isDarkMode ? Colors.grey.shade700 : Colors.blueGrey.shade50; // Available
    Color borderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300;
    Color textColor = isDarkMode ? Colors.white70 : Colors.black87;
    double borderWidth = 1;
    FontWeight fontWeight = FontWeight.normal;
    TextDecoration? textDecoration;

    if (isBooked && !isSelected) {
      seatColor = isDarkMode ? Colors.black38 : Colors.grey.shade400;
      borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade500;
      textColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700;
      textDecoration = TextDecoration.lineThrough;
    }
    if (isSelected) {
      seatColor = AppTheme.accentColor;
      borderColor = AppTheme.primaryColor;
      textColor = Colors.white;
      borderWidth = 1.5;
      fontWeight = FontWeight.bold;
    }

    bool isChairCar = widget.selectedCoachType == "CC" || widget.selectedCoachType == "2S";
    BorderRadius borderRadius = isChairCar ? BorderRadius.circular(6) : BorderRadius.circular(4);
    EdgeInsets margin = isChairCar ? const EdgeInsets.all(2.5) : const EdgeInsets.all(2.0);


    return GestureDetector(
      onTap: (isBooked && !isSelected) ? null : () => _toggleSeatSelection(fullSeatId),
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isWindow && !isBooked && !isSelected ? [
             BoxShadow( color: Colors.blueAccent.withOpacity(isDarkMode ? 0.2 : 0.1), blurRadius: 3, spreadRadius: 0.5)
          ] : null,
        ),
        child: Center(
          child: Text(
            displayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: isChairCar ? 9 : 7.5, // Smaller for berths to fit number + type
                decoration: textDecoration,
            ),
            overflow: TextOverflow.clip,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDarkMode) {
    final Color availableColor = isDarkMode ? Colors.grey.shade700 : Colors.blueGrey.shade50;
    final Color selectedColor = AppTheme.accentColor;
    final Color bookedColor = isDarkMode ? Colors.black38 : Colors.grey.shade400;
    final Color windowBorderColor = Colors.blueAccent.withOpacity(0.5);
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black87;

    Widget legendItem(Color color, String text, {bool isWindow = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: isWindow ? windowBorderColor : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400), width: isWindow ? 1.5: 1),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isWindow ? [BoxShadow(color: windowBorderColor.withOpacity(0.5), blurRadius: 2)] : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontSize: 10, color: textColor)),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4.0,
      runSpacing: 2.0,
      children: [
        legendItem(availableColor, "Available"),
        legendItem(selectedColor, "Selected"),
        legendItem(bookedColor, "Booked"),
        if (widget.selectedCoachType != "CC" && widget.selectedCoachType != "2S")
          legendItem(availableColor, "Window", isWindow: true),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color screenTextColor =
        isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final double totalPrice = widget.pricePerSeat * _selectedSeats.length;
    final bool canProceed = _selectedSeats.length == widget.numberOfSeatsToSelect;

    int itemCountForGrid;
    double childAspectRatio;

    bool isChairCar = widget.selectedCoachType == "CC" || widget.selectedCoachType == "2S";

    if (isChairCar) {
        itemCountForGrid = _numberOfRowsUntukChairCar * _gridColumns;
        childAspectRatio = 1.5; // Wider for chair car seats
    } else { // Berth coaches
        int totalVisualRows = _numberOfBaysToDisplay * _slotsPerBay;
        itemCountForGrid = totalVisualRows * _gridColumns;
        childAspectRatio = (widget.selectedCoachType == "2A") ? 1.2 : 1.0; // Taller for 2A berths, squarer for 3-tier
    }


    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('${widget.selectedCoachType} - ${widget.train.name}'),
        backgroundColor:
            isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        foregroundColor: screenTextColor,
        iconTheme: IconThemeData(color: screenTextColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _currentDisplayCoachNumber,
                        items: _availableCoachNumbers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: screenTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != _currentDisplayCoachNumber) {
                            setState(() {
                              _currentDisplayCoachNumber = newValue;
                              _selectedSeats.clear();
                              _generateMockBookedSeatsForCurrentCoach();
                            });
                          }
                        },
                        dropdownColor: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
                        iconEnabledColor: isDarkMode ? Colors.white70: Colors.black54,
                        underline: Container(height:1, color: screenTextColor.withOpacity(0.3)),
                        style: TextStyle(color: screenTextColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Select ${widget.numberOfSeatsToSelect} seat(s)',
                      style: TextStyle(fontSize: 13, color: screenTextColor.withOpacity(0.9)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildLegend(isDarkMode),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text("⬅️ ENGINE / FRONT", style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                 Text("REAR / GUARD ➡️", style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0), // Reduced horizontal padding
              child: GridView.builder(
                key: ValueKey(_currentDisplayCoachNumber), // Ensures GridView rebuilds on coach change
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridColumns,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 1, // Minimal spacing
                  mainAxisSpacing: 1,  // Minimal spacing
                ),
                itemCount: itemCountForGrid,
                itemBuilder: (context, index) {
                  return _buildBerthOrSeatWidget(
                    coachNumber: _currentDisplayCoachNumber,
                    itemIndex: index,
                    isDarkMode: isDarkMode
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if (_selectedSeats.isNotEmpty) ...[
                  Text(
                    'Selected (${_selectedSeats.length}/${widget.numberOfSeatsToSelect}):',
                    style: TextStyle(fontSize: 14, color: screenTextColor.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                     _selectedSeats.map((e) => e.split('-').sublist(1).join('-')).join(', '), // Show only seat part
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: screenTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                 ] else ... [
                    Text(
                    'No seats selected yet.',
                    style: TextStyle(fontSize: 13, color: screenTextColor.withOpacity(0.7)),
                  ),
                 ]
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppTheme.primaryColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                foregroundColor: canProceed ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canProceed
                  ? () {
                      String trainNumber = widget.train.trainNumber ?? "N/A";
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            prefilledIdentifier: '7d6db31f-f7e7-4655-a0ec-ba12aa329646',
                            identifierIsUserId: true,
                            amount: totalPrice,
                            description: "Train: ${widget.train.name} ($trainNumber)\nCoach: $_currentDisplayCoachNumber (${widget.selectedCoachType})\nSeats: ${_selectedSeats.map((e) => e.split('-').sublist(1).join('-')).join(', ')}\nDept: ${widget.train.departureTime}",
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text(
                canProceed
                  ? 'Proceed to Pay ₹${totalPrice.toStringAsFixed(0)}'
                  : (_selectedSeats.length < widget.numberOfSeatsToSelect
                        ? 'Select ${widget.numberOfSeatsToSelect - _selectedSeats.length} more seat(s)'
                        : 'Select Seats'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}