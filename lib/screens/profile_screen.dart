import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/theme_provider.dart';
import 'package:payment_app/utils/common_widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payment_app/screens/authentication_screen.dart';
import 'package:payment_app/screens/qr_code_screen.dart'; // Import QR code screen
import 'package:payment_app/screens/coming_soon_screen.dart'; // Import coming soon screen
import 'dart:convert'; // Import for jsonDecode

class ProfileScreen extends StatefulWidget { // Changed to StatefulWidget
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState(); // Create state
}

class _ProfileScreenState extends State<ProfileScreen> { // Create state class
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final String? userDataString = await _storage.read(key: 'user_data');
      final String? token = await _storage.read(key: 'auth_token');

      if (userDataString != null && token != null) {
        final Map<String, dynamic> storedUser = jsonDecode(userDataString);
        // Optionally: Re-fetch from an API to ensure data is fresh
        // For now, we'll use stored data and supplement if needed.
        // final apiUser = await getUserProfile(token); // Assuming you have such a function
        // setState(() => _userData = apiUser);
        setState(() => _userData = storedUser);
      } else {
        // Handle case where user data or token is not found (e.g., navigate to login)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print('Error loading user data for profile: $e');
      // Optionally show an error message to the user
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        appBar: commonAppBar(title: 'Profile', context: context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use _userData to populate the UI
    final String displayName = _userData?['username'] ?? _userData?['first_name'] ?? 'User';
    final String email = _userData?['email'] ?? 'No email available';
    final String displayInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: commonAppBar(title: 'Profile', context: context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? AppTheme.darkGradientColors  // Use dark gradient in dark mode
                : AppTheme.gradientColors,     // Use purple gradient in light mode
          ),
        ),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader( // Pass data to _ProfileHeader
                displayName: displayName,
                email: email,
                displayInitial: displayInitial,
              ),
              const SizedBox(height: 24),
              const _QuickActions(),
              const SizedBox(height: 24),
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Personal Information')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.security,
                    title: 'Security Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Security Settings')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Payment Methods')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuSection(
                title: 'Preferences',
                items: [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Notification Settings')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Language Settings')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.color_lens_outlined,
                    title: 'Change Color Theme',
                    onTap: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Help Center')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Privacy Policy')),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      // Logout functionality
                      final storage = FlutterSecureStorage();
                      await storage.deleteAll(); // Clear all secure storage
                      
                      // Navigate to authentication screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthenticationScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String displayInitial;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.displayInitial,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDarkMode 
                  ? [Colors.white24, Colors.white10] // Neutral colors for dark mode
                  : [Colors.purple.shade400, Colors.blue.shade400], // Purple gradient for light mode
            ),
          ),
          child: Center(
            child: Text(
              displayInitial, // Use dynamic initial
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName, // Use dynamic display name
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.white, // Ensure visibility in both themes
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email, // Use dynamic email
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.white.withOpacity(0.7), // Improved visibility
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionItem(
          icon: Icons.qr_code,
          label: 'QR Code',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRCodeScreen()),
          ),
        ),
        _QuickActionItem(
          icon: Icons.share,
          label: 'Share',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Share')),
          ),
        ),
        _QuickActionItem(
          icon: Icons.edit,
          label: 'Edit',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen(featureName: 'Profile Edit')),
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 28,
              color: Colors.white, // White icon color for better visibility
            ),
            const SizedBox(height:.8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white, // White text for better visibility
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.white, // Ensure visibility in both themes
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          color: isDarkMode 
              ? Colors.white.withOpacity(0.1) // Semi-transparent for dark mode
              : Colors.white, // Fully opaque for light mode for better contrast
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive 
            ? Colors.red 
            : (isDarkMode ? Colors.white70 : Colors.purple.shade800),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive 
              ? Colors.red 
              : (isDarkMode ? Colors.white : Colors.purple.shade900),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white54 : Colors.purple.shade800,
      ),
      onTap: onTap,
    );
  }
}
