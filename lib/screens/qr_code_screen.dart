import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:payment_app/screens/payment_screen.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/common_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QRCodeScreen extends StatefulWidget {
  final int initialTabIndex;
  const QRCodeScreen({ super.key, this.initialTabIndex = 0, });
  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> with SingleTickerProviderStateMixin {
  String? _userId;
  String? _displayName;
  bool _isLoadingUser = true;
  String? _userError;
  bool _isScanning = false;
  // *** Initialize MobileScannerController with more specific settings ***
  final MobileScannerController _scannerController = MobileScannerController(
    // Consider setting detection speed and timeout
    detectionSpeed: DetectionSpeed.normal, // Or .noDuplicates
    // detectionTimeoutMs: 500, // Timeout for duplicate detection
    // facing: CameraFacing.back, // Default is back
    // torchEnabled: false, // Default is off
  );
  TabController? _tabController;
  final _storage = const FlutterSecureStorage();
  bool _processingScan = false; // Flag to prevent multiple navigations


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadUserData();
     _tabController?.addListener(_handleTabChange); // Use named function
  }

  // Separate listener function for clarity
  void _handleTabChange() {
    if (!mounted) return;
    if (_tabController?.index == 0 && _isScanning) {
        _stopScanning(); // Stop scanning if user switches away manually
    }
  }


  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange); // Remove listener
    _tabController?.dispose();
    _scannerController.dispose(); // Ensure scanner controller is disposed
    super.dispose();
  }

   Future<void> _loadUserData() async {
    // ... (Keep existing _loadUserData logic) ...
    setState(() { _isLoadingUser = true; _userError = null; });
    try {
      final storedUserId = await _storage.read(key: 'user_id');
      final storedUserData = await _storage.read(key: 'user_data');
      if (storedUserId == null || storedUserId.isEmpty) throw Exception("User ID not found.");
      String name = "User";
      if (storedUserData != null) { final user = jsonDecode(storedUserData); name = user['first_name'] ?? user['username'] ?? storedUserId.substring(0,6); }
      else { name = storedUserId.substring(0,6); }
      if (mounted) { setState(() { _userId = storedUserId; _displayName = name; _isLoadingUser = false; }); }
    } catch (e) { if (mounted) { setState(() { _isLoadingUser = false; _userError = e.toString().replaceFirst("Exception: ", ""); }); } }
  }

 Future<void> _requestCameraPermissionAndStartScan() async {
    if (_isScanning) return; // Already scanning

    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
        status = await Permission.camera.request();
    }

    if (status.isGranted) {
      if (mounted) {
         setState(() {
             _isScanning = true;
             _processingScan = false; // Reset processing flag
         });
         // *** Explicitly start camera if needed ***
         // Might not be necessary if using the widget, but can sometimes help
          // Ensure camera is started if stopped previously
         Future.delayed(Duration.zero, () async {
           if (mounted && !_scannerController.isStarting) {
              await _scannerController.start();
           }
         });
      }
    } else if (status.isPermanentlyDenied) {
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Camera access denied. Please enable in settings.'), action: SnackBarAction( label: 'Settings', onPressed: openAppSettings), backgroundColor: Theme.of(context).colorScheme.error, )); }
    } else {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('Camera permission is required to scan.'), backgroundColor: Theme.of(context).colorScheme.error, )); }
    }
 }

  void _stopScanning() {
     if(mounted) {
        // *** Explicitly stop camera ***
        // Should ensure camera resources are released promptly
        _scannerController.stop();
        setState(() {
            _isScanning = false;
            _processingScan = false; // Reset flag
        });
     }
  }

 void _handleDetectedBarcode(BarcodeCapture capture) {
     // Use the processing flag to avoid handling multiple detections for one scan session
     if (!mounted || !_isScanning || _processingScan) return;


     final List<Barcode> barcodes = capture.barcodes;
     if (barcodes.isNotEmpty) {
       final String? scannedValue = barcodes.first.rawValue;

       if (scannedValue != null && scannedValue.isNotEmpty) {
          setState(() { _processingScan = true; }); // Set flag to true
          print('Barcode found! Value: $scannedValue');

         // Stop camera stream immediately
         _scannerController.stop(); // Stop camera *before* navigation

          // Short delay before navigation can sometimes help UI responsiveness
          Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) { // Check again before navigating
                   Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                       prefilledIdentifier: scannedValue,
                       identifierIsUserId: true, // Assume QR contains User ID
                    )
                  )).then((_) {
                     // When returning from PaymentScreen, ensure scanning is stopped
                     _stopScanning();
                  });
              }
          });
       } else {
           print ("Detected empty barcode value.");
       }
     }
 }

  @override
  Widget build(BuildContext context) {
    // ... (Keep the existing build method structure for Scaffold, AppBar, TabBar, Gradient) ...
    final ThemeData currentTheme = Theme.of(context);
    final bool isDarkMode = currentTheme.brightness == Brightness.dark;
    final Color indicatorColor = isDarkMode ? Colors.white : AppTheme.accentColor;
    final Color labelColor = Colors.white;
    final Color unselectedLabelColor = Colors.white.withOpacity(0.7);

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: commonAppBar(
        title: 'QR Payment', context: context,
        bottom: TabBar(
           controller: _tabController, tabs: const [ Tab(text: 'My Code'), Tab(text: 'Scan Code'), ],
           indicatorColor: indicatorColor, indicatorWeight: 3.0, labelColor: labelColor, unselectedLabelColor: unselectedLabelColor,
           labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
           unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: Container(
        decoration: BoxDecoration( gradient: LinearGradient( begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors, ), ),
        child: _isLoadingUser ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _userError != null ? Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text("Error: Could not load user QR data.\n$_userError", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center,)))
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MyQRView( userId: _userId!, displayName: _displayName!, ),
                    // Pass updated scanner to _ScanQRView
                    _ScanQRView(
                      isScanning: _isScanning,
                      onRequestScan: _requestCameraPermissionAndStartScan,
                      onStopScan: _stopScanning,
                      scannerController: _scannerController, // Pass the configured controller
                      onDetect: _handleDetectedBarcode,
                    ),
                  ],
                ),
      ),
    );
  }
}


// --- "My QR" Tab View (Remains the same) ---
// ... (Keep _MyQRView code as is) ...
class _MyQRView extends StatelessWidget {
  final String userId;
  final String displayName;
  const _MyQRView({ required this.userId, required this.displayName, });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center( child: SingleChildScrollView( padding: const EdgeInsets.all(24.0),
           child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                 Card( elevation: 8, color: Colors.white, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(20), ),
                    child: Padding( padding: const EdgeInsets.all(24.0),
                       child: Column( mainAxisSize: MainAxisSize.min, children: [
                             Container( padding: const EdgeInsets.all(10), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12), ),
                                child: QrImageView( data: userId, version: QrVersions.auto, size: MediaQuery.of(context).size.width * 0.6, gapless: false, backgroundColor: Colors.white, foregroundColor: Colors.black, errorStateBuilder: (cxt, err) { return const Center(child: Text("Uh oh! Something went wrong.", textAlign: TextAlign.center,), ) ;},), // Added error builder
                             ),
                             const SizedBox(height: 20),
                             Text( displayName, style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.black87 : AppTheme.primaryColor, ), ),
                             const SizedBox(height: 6),
                             Text( 'Scan this code to pay me', style: TextStyle( color: Colors.grey.shade700, fontSize: 14, ), ),
                          ],
                       ),
                    ),
                 ),
                 const SizedBox(height: 32),
                 Text( 'Others can scan this using the TapKaro app\nto send you money instantly.', textAlign: TextAlign.center, style: TextStyle( color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.4), ),
              ],
           ),
      ),
    );
  }
}


// --- "Scan QR" Tab View (MODIFIED) ---
// --- "Scan QR" Tab View (MODIFIED) ---
// --- "Scan QR" Tab View (CORRECTED for common MobileScanner versions) ---
class _ScanQRView extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onRequestScan;
  final VoidCallback onStopScan;
  final MobileScannerController scannerController;
  final Function(BarcodeCapture) onDetect;
  const _ScanQRView({ required this.isScanning, required this.onRequestScan, required this.onStopScan, required this.scannerController, required this.onDetect, });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color overlayBorderColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    // Define the scan window size based on screen width
    final double scanWindowSize = MediaQuery.of(context).size.width * 0.7; // Adjust percentage as needed

    return Column( children: [
        Expanded( child: Center(
            child: isScanning
              ? SizedBox( // Container to define the overall scanner area size
                  width: MediaQuery.of(context).size.width * 0.85, // Container slightly larger than scan window
                  height: MediaQuery.of(context).size.width * 0.85,
                  child: Stack( // Use Stack to layer scanner and overlay
                    alignment: Alignment.center, // Center overlay on scanner
                    children: [
                      // Camera Preview - Clipped to Rounded Rectangle
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: MobileScanner(
                          controller: scannerController,
                          onDetect: onDetect,
                           // Fit the camera preview within the available space
                           fit: BoxFit.cover,
                           // scanWindow: Rect.fromCenter( // Removed by default, can add back if needed
                           // center: Offset(boxConstraints.maxWidth / 2, boxConstraints.maxHeight / 2),
                           // width: scanWindowSize * 0.8, // Scan area slightly smaller than visual window
                           // height: scanWindowSize * 0.8,
                          //),
                        ),
                      ),

                      // --- The Overlay Widget ---
                      // This widget draws the semi-transparent border and aiming reticle
                      Container(
                         decoration: ShapeDecoration(
                            shape: QrScannerOverlayShape( // Use the shape class
                                overlayColor: Colors.black.withOpacity(0.6),
                                borderColor: overlayBorderColor,
                                borderRadius: 18, // Should ideally match ClipRRect
                                borderLength: 35, // Length of corner lines
                                borderWidth: 8, // Thickness of corner lines
                                cutOutSize: scanWindowSize, // Size of the inner transparent square
                                // cutOutBottomOffset: 0, // Adjust vertical position
                            )
                         ),
                      ),
                       // Optional: Add a scanning animation line if desired (more complex)
                       // _buildScanAnimationLine(scanWindowSize), // Example placeholder
                    ],
                  ),
                )
              : _buildScanPlaceholder(context, isDarkMode),
          ),
        ),
         // Button section remains the same
         Padding( padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
           child: SizedBox( width: double.infinity, height: 50,
             child: ElevatedButton.icon(
               style: ElevatedButton.styleFrom( backgroundColor: isScanning ? AppTheme.errorColor.withOpacity(0.8) : (isDarkMode ? Colors.white.withOpacity(0.15) : AppTheme.primaryColor), foregroundColor: Colors.white, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), ), ),
               onPressed: isScanning ? onStopScan : onRequestScan,
               icon: Icon(isScanning ? Icons.stop_circle_outlined : Icons.qr_code_scanner_rounded),
               label: Text(isScanning ? 'Stop Scanning' : 'Scan QR Code'),
             ),
           ),
         ),
      ],
    );
  }

  // Placeholder remains the same
  Widget _buildScanPlaceholder(BuildContext context, bool isDarkMode) {
      return Column( mainAxisAlignment: MainAxisAlignment.center, children: [
        Container( padding: const EdgeInsets.all(24), decoration: BoxDecoration( color: (isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor).withOpacity(0.15), shape: BoxShape.circle, ),
          child: Icon( Icons.qr_code_scanner_rounded, size: 60, color: isDarkMode ? Colors.white : AppTheme.accentColor, ), ),
        const SizedBox(height: 24),
        Text( 'Scan to Pay', style: TextStyle( color: isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white, fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize, fontWeight: FontWeight.bold ), ),
        const SizedBox(height: 12),
        Padding( padding: const EdgeInsets.symmetric(horizontal: 40.0), child: Text( 'Point your camera at a QR code to quickly send payments.', textAlign: TextAlign.center, style: TextStyle( color: isDarkMode ? AppTheme.textSecondaryColorDark : Colors.white70, fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize, height: 1.4 ), ), ),
      ],
    );
  }
}


// --- ADD THIS HELPER CLASS (usually placed at the bottom of the file or in a separate utility file) ---
/// A ShapeBorder that draws the typical QR scanner overlay.
class QrScannerOverlayShape extends ShapeBorder {
  final Color overlayColor;
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80), // Default semi-transparent black
    this.borderColor = Colors.blue,
    this.borderRadius = 10.0,
    this.borderLength = 40.0,
    this.borderWidth = 10.0,
    required this.cutOutSize,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect); // Not used for drawing the overlay itself
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
     Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.top + borderRadius)
        ..arcToPoint(
          Offset(rect.left + borderRadius, rect.top),
          radius: Radius.circular(borderRadius),
          clockwise: false,
        )
        ..lineTo(rect.left + borderRadius, rect.top);
    }

    // Create the path for the entire screen rectangle
    // Then create the path for the cut-out square
    // Subtract the cut-out path from the screen path to get the overlay shape
     return Path.combine(
        PathOperation.difference,
        Path()..addRect(rect), // Outer rectangle (full screen)
        _getCutOutPath(rect), // Inner cut-out rectangle
     );
  }

   Path _getCutOutPath(Rect rect) {
    // Calculate the center and the cut-out rectangle bounds
    double cutOutWidth = cutOutSize;
    double cutOutHeight = cutOutSize;
    // Adjust center based on offset - allows moving the scan window up/down
    double TcenterX = rect.left + rect.width / 2;
    double TcenterY = rect.top + rect.height / 2 + cutOutBottomOffset;

    Rect cutOutRect = Rect.fromLTWH(
      TcenterX - cutOutWidth / 2,
      TcenterY - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    // Create the rounded rectangle path for the cut-out
     return Path()
       ..addRRect(
          RRect.fromRectAndCorners(
            cutOutRect,
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
       );
  }


  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

     final Paint overlayPaint = Paint()..color = overlayColor;

     // Calculate the cut-out rectangle bounds like in getOuterPath
     double cutOutWidth = cutOutSize;
     double cutOutHeight = cutOutSize;
     double TcenterX = rect.left + rect.width / 2;
     double TcenterY = rect.top + rect.height / 2 + cutOutBottomOffset;
     Rect cutOutRect = Rect.fromLTWH( TcenterX - cutOutWidth / 2, TcenterY - cutOutHeight / 2, cutOutWidth, cutOutHeight, );
     // Create the rounded rectangle for clipping and drawing borders
     RRect cutOutRRect = RRect.fromRectAndCorners( cutOutRect, topLeft: Radius.circular(borderRadius), topRight: Radius.circular(borderRadius), bottomLeft: Radius.circular(borderRadius), bottomRight: Radius.circular(borderRadius), );


     // Draw the overlay background (semi-transparent color outside the cut-out)
    canvas.drawPath(
       Path.combine( PathOperation.difference, Path()..addRect(rect), Path()..addRRect(cutOutRRect),),
       overlayPaint,
    );


    // --- Draw the border corners ---
     // Calculate corner lengths (make sure they don't exceed half the side length)
     double adjustedBorderLength = borderLength > cutOutSize/2 ? cutOutSize/2 : borderLength;

    // Top Left Corner
     canvas.drawPath(Path()..moveTo(cutOutRect.left, cutOutRect.top + adjustedBorderLength)..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)..arcToPoint(Offset(cutOutRect.left + borderRadius, cutOutRect.top), radius: Radius.circular(borderRadius), clockwise: false)..lineTo(cutOutRect.left + adjustedBorderLength, cutOutRect.top), borderPaint);
     // Top Right Corner
     canvas.drawPath(Path()..moveTo(cutOutRect.right - adjustedBorderLength, cutOutRect.top)..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)..arcToPoint(Offset(cutOutRect.right, cutOutRect.top + borderRadius), radius: Radius.circular(borderRadius), clockwise: false)..lineTo(cutOutRect.right, cutOutRect.top + adjustedBorderLength), borderPaint);
    // Bottom Left Corner
    canvas.drawPath(Path()..moveTo(cutOutRect.left, cutOutRect.bottom - adjustedBorderLength)..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius)..arcToPoint(Offset(cutOutRect.left + borderRadius, cutOutRect.bottom), radius: Radius.circular(borderRadius), clockwise: true)..lineTo(cutOutRect.left + adjustedBorderLength, cutOutRect.bottom), borderPaint);
    // Bottom Right Corner
     canvas.drawPath(Path()..moveTo(cutOutRect.right - adjustedBorderLength, cutOutRect.bottom)..lineTo(cutOutRect.right - borderRadius, cutOutRect.bottom)..arcToPoint(Offset(cutOutRect.right, cutOutRect.bottom - borderRadius), radius: Radius.circular(borderRadius), clockwise: true)..lineTo(cutOutRect.right, cutOutRect.bottom - adjustedBorderLength), borderPaint);
    //--- End Draw border corners ---
  }

  @override
  ShapeBorder scale(double t) {
    // Required override, simple scaling might not be accurate for complex shape
    return QrScannerOverlayShape(
       overlayColor: overlayColor, borderColor: borderColor, borderRadius: borderRadius * t, borderLength: borderLength * t, borderWidth: borderWidth * t, cutOutSize: cutOutSize * t, cutOutBottomOffset: cutOutBottomOffset * t,
    );
  }
}