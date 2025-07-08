import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payment_app/services/api_service.dart';
import 'package:payment_app/screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payment_app/utils/theme.dart'; // Ensure AppTheme is imported
// import 'package:shared_preferences/shared_preferences.dart'; // Keep if used for theme toggle
import 'package:intl/intl.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _isLoading = false;
  bool _isLogin = true;
  bool _passwordVisible = false; // Keep track of password visibility

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _storage = const FlutterSecureStorage(); // Instance for storage

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly faster fade
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // Smoother curve
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final ThemeData currentTheme = Theme.of(context);
    final bool isDarkMode = currentTheme.brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? AppTheme.darkAccentColor : AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? AppTheme.darkAccentColor : AppTheme.primaryColor,
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date of Birth'; // More descriptive hint
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _submitForm() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }

    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> response;

      if (_isLogin) {
        response = await loginUser(
          _usernameController.text.trim(), // Trim input
          _passwordController.text,
        );
      } else {
        final dobString = _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : null; // Get formatted date or null


        // Handle case where DOB might be required but wasn't selected
        if (dobString == null) {
             throw Exception('Please select your date of birth.');
        }


        final userData = {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'date_of_birth': dobString, // Use formatted string
        };

        response = await registerUser(userData);
      }

      // --- Store Token AND User ID ---
      final String? token = response['token'] as String?;
      final dynamic userMap = response['user']; // Get user object

      if (token == null || token.isEmpty) {
        throw Exception('Authentication failed: Missing token.');
      }
      if (userMap == null || userMap is! Map || userMap['id'] == null) {
         throw Exception('Authentication failed: Missing user ID.');
      }

      final String userId = userMap['id'] as String;

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id', value: userId); // *** SAVE USER ID ***
      await _storage.write(key: 'user_data', value: jsonEncode(userMap)); // Store full user data too

      print("Stored user_id: $userId"); // Confirm in logs


      // TODO: Handle theme preference persistence if needed globally
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('isDark', false);

      if (mounted) {
        // Navigate with fade transition
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600), // Slightly faster transition
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Use theme for error snackbar
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating, // Optional: floating snackbar
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add this function at class level
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ThemeData currentTheme = Theme.of(context); // Get current theme
    final bool isDarkMode = currentTheme.brightness == Brightness.dark;

    // Determine text/icon color that contrasts with the gradient background
    final Color onGradientColor = isDarkMode ? AppTheme.textPrimaryColorDark : Colors.white;
     final Color hintColorOnGradient = isDarkMode ? AppTheme.textSecondaryColorDark : Colors.white70;


    return Scaffold(
       // Use scaffoldBackgroundColor from the active theme
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Apply the gradient from AppTheme constants
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, // Adjusted gradient angle
            end: Alignment.bottomRight,
            colors: isDarkMode ? AppTheme.darkGradientColors : AppTheme.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Center( // Center content vertically
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition( // Apply fade animation to the entire form column
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                   constraints: BoxConstraints(
                     maxWidth: 500, // Max width for larger screens
                   ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header Section
                        Icon(
                         Icons.account_balance_wallet_outlined, // Updated Icon
                          size: 70,
                          color: onGradientColor,
                        ),
                        const SizedBox(height: 16),
                         Text(
                          'TapKaro',
                          style: currentTheme.textTheme.displaySmall?.copyWith( // Use text theme
                            color: onGradientColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Digital Payment Partner',
                           style: currentTheme.textTheme.titleMedium?.copyWith( // Use text theme
                            color: hintColorOnGradient,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- Form Fields using AppTheme.inputDecoration ---
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: onGradientColor), // Text input color on gradient
                            decoration: AppTheme.inputDecoration(
                              hintText: 'Email Address',
                              labelText: 'Email',
                              isDarkMode: isDarkMode,
                              prefixIcon: Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Email is required';
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value!)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _usernameController,
                           style: TextStyle(color: onGradientColor),
                          decoration: AppTheme.inputDecoration(
                            hintText: _isLogin ? 'Username or Email' : 'Choose a Username',
                            labelText: 'Username',
                            isDarkMode: isDarkMode,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Username is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: onGradientColor),
                          obscureText: !_passwordVisible,
                          decoration: AppTheme.inputDecoration(
                            hintText: _isLogin ? 'Password' : 'Password (8+ chars: A-Z, a-z, 0-9, symbol)',
                            labelText: 'Password',
                            isDarkMode: isDarkMode,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: hintColorOnGradient,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Password is required';
                            if (!_isLogin) {
                              if (!_isPasswordStrong(value!)) {
                                return 'Password must have 8+ characters with at least:\n• 1 uppercase letter\n• 1 lowercase letter\n• 1 number\n• 1 special character';
                              }
                            }
                            return null;
                          },
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                             style: TextStyle(color: onGradientColor),
                            decoration: AppTheme.inputDecoration(
                              hintText: 'Phone Number (e.g., +91... or 10 digits)',
                              labelText: 'Phone',
                              isDarkMode: isDarkMode,
                              prefixIcon: Icons.phone_iphone_rounded,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits potentially
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Phone number is required';
                               if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(value!)) return 'Enter a valid phone number'; // Basic validation
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                         Row( // First and Last name side-by-side
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  style: TextStyle(color: onGradientColor),
                                  decoration: AppTheme.inputDecoration(
                                    hintText: 'First Name',
                                    labelText: 'First Name',
                                    isDarkMode: isDarkMode,
                                    prefixIcon: null, // Remove icon if label is present
                                  ),
                                   textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Required'; // Short error
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  style: TextStyle(color: onGradientColor),
                                  decoration: AppTheme.inputDecoration(
                                    hintText: 'Last Name',
                                    labelText: 'Last Name',
                                    isDarkMode: isDarkMode,
                                      prefixIcon: null,
                                  ),
                                   textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                     if (value?.isEmpty ?? true) return 'Required'; // Short error
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Date of Birth Field Redesigned
                          TextFormField(
                             readOnly: true, // Make it read-only
                            controller: TextEditingController(text: _formatDate(_dateOfBirth)),
                            style: TextStyle(color: onGradientColor),
                             decoration: AppTheme.inputDecoration(
                              hintText: 'Date of Birth', // Hint will show if controller is empty
                              labelText: 'Date of Birth',
                              isDarkMode: isDarkMode,
                              prefixIcon: Icons.calendar_today_outlined,
                               suffixIcon: Icon(Icons.arrow_drop_down, color: hintColorOnGradient) // Indicate tappable
                            ).copyWith(
                              // Ensure contentPadding is sufficient
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            onTap: () => _selectDate(context), // Call date picker on tap
                             validator: (value) { // Validation still works
                              if (_dateOfBirth == null) return 'Date of birth is required';
                              return null;
                            },
                           ),
                        ],
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            // Use theme for button, potentially override for primary action emphasis
                            style: currentTheme.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300; // Disabled color
                                  }
                                   // Use a contrasting color for the button itself on top of the gradient
                                   return Colors.white.withOpacity(0.9);
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.grey.shade500;
                                  }
                                   // Use primary app color for text on white button
                                  return AppTheme.primaryColor;
                                },
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      // Use contrasting color for spinner
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Login Now' : 'Create Account',
                                   // Style taken from ElevatedButton's theme
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Toggle Button
                        TextButton(
                          onPressed: _isLoading ? null : () { // Disable during loading
                            setState(() {
                              _isLogin = !_isLogin;
                              // Optionally clear fields, or keep them for user convenience
                              // _formKey.currentState?.reset();
                              _passwordController.clear(); // Clear password when toggling
                            });
                          },
                          child: Text(
                            _isLogin
                                ? "Don't have an account? Sign Up"
                                : 'Already have an account? Login',
                            // Use a clearly visible color on the gradient
                            style: TextStyle(color: onGradientColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                          ),
                        ),
                         const SizedBox(height: 20), // Add some bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}