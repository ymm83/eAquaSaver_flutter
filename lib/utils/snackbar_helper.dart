import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SnackBarTheme {
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  SnackBarTheme({required this.bgColor, required this.textColor, this.icon});
}

final Map<String, SnackBarTheme> snackBarThemes = {
  'warning': SnackBarTheme(
    bgColor: Colors.yellow.shade700,
    textColor: Colors.black87,
    icon: Icons.warning,
  ),
  'error': SnackBarTheme(
    bgColor: Colors.red.shade100,
    textColor: Colors.red.shade900,
    icon: Icons.error_outline,
  ),
  'success': SnackBarTheme(
    bgColor: Colors.green.shade200,
    textColor: Colors.green.shade900,
    icon: Icons.check_circle_outlined,
  ),
  'info': SnackBarTheme(
    bgColor: Colors.blue.shade200,
    textColor: Colors.blue.shade900,
    icon: Icons.info_outline,
  ),
  'notify': SnackBarTheme(
    bgColor: Colors.grey.shade200,
    textColor: Colors.grey.shade900,
    icon: Icons.notifications_active,
  ),
  'default': SnackBarTheme(
    bgColor: Colors.blue.shade200,
    textColor: Colors.blue.shade900,
    icon: null,
  ),
};

void showSnackBar(
  String message, {
  BuildContext? context, // Hacer contexto opcional
  Duration? duration,
  String? theme,
  SnackBarAction? action,
  VoidCallback? onHideCallback,
  IconData? icon,
  bool showCloseIcon = false,
}) {
  final SnackBarTheme myTheme = snackBarThemes[theme] ?? snackBarThemes['default']!;
  final IconData? selectedIcon = icon ?? myTheme.icon;

  Duration snackBarDuration = duration ?? const Duration(seconds: 3);
  //debugPrint('------- icon: ${icon.toString()}');

  final Widget snackBarContent = Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedIcon != null) ...[
          Icon(selectedIcon, color: myTheme.textColor),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: myTheme.textColor),
          ),
        ),
      ],
    ),
  );

  final snackBar = SnackBar(
    content: snackBarContent,
    backgroundColor: myTheme.bgColor,
    duration: snackBarDuration,
    showCloseIcon: showCloseIcon,
    action: action,
    padding: const EdgeInsets.only(left: 10, right: 10, top: 7, bottom: 7),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(left: 10.0, right: 10.0),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: myTheme.textColor, width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Usa el contexto si se proporciona, de lo contrario usa el scaffoldMessengerKey
  if (context != null) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  } else {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  Future.delayed(snackBarDuration, () {
    if (onHideCallback != null) {
      onHideCallback();
    }
  });
}
