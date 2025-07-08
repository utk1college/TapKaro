import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';

/// Creates a consistent app bar used across all screens.
/// 
/// Parameters:
/// - [title]: The title text to display in the app bar
/// - [context]: BuildContext for navigation
/// - [actions]: Optional list of action widgets
/// - [bottom]: Optional bottom widget for tabs
/// - [backgroundColor]: Optional background color for the AppBar
PreferredSizeWidget commonAppBar({
  required String title,
  required BuildContext context,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  Color? backgroundColor,  // Background color parameter
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  // Calculate the top padding for status bar height
  final statusBarHeight = MediaQuery.of(context).padding.top;
  
  return PreferredSize(
    preferredSize: Size.fromHeight(kToolbarHeight + (bottom != null ? bottom.preferredSize.height : 0)),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppTheme.darkPrimaryColor.withOpacity(0.9),
                  AppTheme.darkPrimaryColor.withOpacity(0.8),
                ]
              : [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent, // Use transparent to show gradient
        elevation: 0,
        leading: Navigator.of(context).canPop() 
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ) 
            : null,
        actions: actions,
        bottom: bottom,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28,
        ),
      ),
    ),
  );
}