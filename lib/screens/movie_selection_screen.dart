import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart'; // Assuming AppTheme is defined here
import 'package:payment_app/screens/seat_selection_screen.dart'; // Import the new screen

class MovieSelectionScreen extends StatefulWidget {
  const MovieSelectionScreen({super.key});

  @override
  State<MovieSelectionScreen> createState() => _MovieSelectionScreenState();
}

class _MovieSelectionScreenState extends State<MovieSelectionScreen> {
  String? _selectedMovieName;
  String? _selectedMovieImage;
  String? _selectedTheater;
  String? _selectedTime;
  int _selectedSeatsCount = 1; // Number of seats the user wants

  PageController? _moviePageController;
  int _currentMovieIndex = 0;

  final List<Map<String, String?>> _movies = [
    {'name': 'Echoes of Tomorrow', 'image': 'assets/movie/movie_poster_1.jpg'},
    {'name': 'Cosmic Drift', 'image': 'assets/movie/movie_poster_2.jpg'},
    {'name': 'Neon City Raiders', 'image': 'assets/movie/movie_poster_3.jpg'},
    {'name': 'Interstellar', 'image': 'assets/movie/movie_poster_4.jpg'},
  ];
  final List<String> _theaters = ['Cineplex Alpha', 'Metro Grand', 'Vista Screens'];
  final List<String> _times = ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM'];

  @override
  void initState() {
    super.initState();
    _moviePageController = PageController(
      viewportFraction: 0.75,
      initialPage: _currentMovieIndex,
    );

    if (_movies.isNotEmpty) {
      _selectedMovieName = _movies[_currentMovieIndex]['name'];
      _selectedMovieImage = _movies[_currentMovieIndex]['image'];
    }
    if (_theaters.isNotEmpty) {
      _selectedTheater = _theaters[0]; // Default to the first theater
    }
    // _selectedTime is null by default
    // _selectedSeatsCount is 1 by default
  }

  @override
  void dispose() {
    _moviePageController?.dispose();
    super.dispose();
  }

  void _proceedToSeatSelection() {
    if (_selectedMovieName == null) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select a movie.'), backgroundColor: Colors.orangeAccent, ), );
      return;
    }
    if (_selectedTheater == null) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select a theater.'), backgroundColor: Colors.orangeAccent, ), );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select a time slot.'), backgroundColor: Colors.orangeAccent, ), );
      return;
    }
    if (_selectedSeatsCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select at least one seat.'), backgroundColor: Colors.orangeAccent, ), );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          movieName: _selectedMovieName!,
          movieImage: _selectedMovieImage, // Can be null
          theaterName: _selectedTheater!,
          timeSlot: _selectedTime!,
          numberOfSeatsToSelect: _selectedSeatsCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final Color accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final Color cardBackgroundColor = isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;
    final Color subtleTextColor = isDarkMode ? AppTheme.textSecondaryColorDark : AppTheme.textSecondaryColorLight;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Movie Tickets'),
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildSectionTitle('Now Showing', primaryTextColor),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _moviePageController,
                itemCount: _movies.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentMovieIndex = index;
                    _selectedMovieName = _movies[index]['name'];
                    _selectedMovieImage = _movies[index]['image'];
                  });
                },
                itemBuilder: (context, index) {
                  final movie = _movies[index];
                  final isSelected = index == _currentMovieIndex;
                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                      child: _MovieCard(
                        movieName: movie['name']!,
                        imageUrl: movie['image'],
                        isSelected: isSelected,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _moviePageController?.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Select Theater', primaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3), ) ],
                    ),
                    child: Wrap(
                      spacing: 10.0, runSpacing: 10.0,
                      children: _theaters.map((theater) {
                        final isSelectedTheater = _selectedTheater == theater;
                        return ChoiceChip(
                          label: Text( theater, style: TextStyle( color: isSelectedTheater ? (isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white) : primaryTextColor, fontWeight: FontWeight.w500, ), ),
                          selected: isSelectedTheater,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTheater = selected ? theater : null;
                            });
                          },
                          selectedColor: accentColor,
                          backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.5) : AppTheme.backgroundColor,
                          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide( color: isSelectedTheater ? accentColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300), ) ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Select Showtime', primaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3), ) ],
                    ),
                    child: Wrap(
                      spacing: 10.0, runSpacing: 10.0,
                      children: _times.map((time) {
                        final isSelectedTime = _selectedTime == time;
                        return ChoiceChip(
                          label: Text( time, style: TextStyle( color: isSelectedTime ? (isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white) : primaryTextColor, fontWeight: FontWeight.w500, ), ),
                          selected: isSelectedTime,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTime = selected ? time : null;
                            });
                          },
                          selectedColor: accentColor,
                          backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.5) : AppTheme.backgroundColor,
                          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide( color: isSelectedTime ? accentColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300), ) ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Number of Seats', primaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration( color: cardBackgroundColor, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3), ) ], ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text( 'Seats:', style: TextStyle( fontSize: 16, color: subtleTextColor, fontWeight: FontWeight.w500, ), ),
                        Row(
                          children: [
                            _SeatControlButton(
                              icon: Icons.remove,
                              onPressed: () {
                                if (_selectedSeatsCount > 1) {
                                  setState(() {
                                    _selectedSeatsCount--;
                                  });
                                }
                              },
                              isDarkMode: isDarkMode, accentColor: accentColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text( '$_selectedSeatsCount', style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor, ), ),
                            ),
                            _SeatControlButton(
                              icon: Icons.add,
                              onPressed: () {
                                if (_selectedSeatsCount < 10) { // Example limit
                                  setState(() {
                                    _selectedSeatsCount++;
                                  });
                                }
                              },
                              isDarkMode: isDarkMode, accentColor: accentColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 30 + 56 + 16), // Space for bottom nav bar
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _proceedToSeatSelection,
          style: ElevatedButton.styleFrom( backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), ), textStyle: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, ), ),
          child: const Text('Proceed to Seat Selection'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text( title, style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: textColor, ), );
  }
}

class _MovieCard extends StatelessWidget {
  final String movieName;
  final String? imageUrl;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _MovieCard({
    // super.key, // Not strictly necessary for private widgets unless using specific key features
    required this.movieName,
    this.imageUrl,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      ),
      child: Icon( Icons.movie_creation_outlined, color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500, size: 50, ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBgColor = isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;
    final Color textColor = isDarkMode ? AppTheme.textPrimaryColorDark : AppTheme.textPrimaryColorLight;
    final Color borderColor = isSelected ? (isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor) : Colors.transparent;

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        imageWidget = Image.network( imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(), );
      } else {
        imageWidget = Image.asset( imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) { print("Error loading asset: $imageUrl"); return _buildPlaceholderImage(); }, );
      }
    } else {
      imageWidget = _buildPlaceholderImage();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration( color: cardBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: 2.5), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(isSelected ? 0.12 : 0.06), blurRadius: isSelected ? 8 : 6, offset: Offset(0, isSelected ? 5 : 3), ) ], ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect( borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: imageWidget, ),
            Expanded( child: Padding( padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), child: Center( child: Text( movieName, style: TextStyle( fontSize: 14, fontWeight: FontWeight.w600, color: textColor, ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, ), ), ), ),
          ],
        ),
      ),
    );
  }
}

class _SeatControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color accentColor;

  const _SeatControlButton({
    // super.key,
    required this.icon,
    required this.onPressed,
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDarkMode ? AppTheme.darkSurfaceColor.withOpacity(0.8) : Color.alphaBlend(Colors.black.withOpacity(0.03), AppTheme.backgroundColor),
      borderRadius: BorderRadius.circular(8),
      child: InkWell( onTap: onPressed, borderRadius: BorderRadius.circular(8), child: Padding( padding: const EdgeInsets.all(8.0), child: Icon( icon, size: 22, color: accentColor, ), ), ),
    );
  }
}