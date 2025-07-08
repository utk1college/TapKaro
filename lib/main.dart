import 'package:flutter/material.dart';
import 'package:payment_app/screens/authentication_screen.dart';
import 'package:payment_app/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'TapKaro',
            theme: themeProvider.currentTheme,
            home: const AuthenticationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}