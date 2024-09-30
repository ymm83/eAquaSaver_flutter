import 'package:flutter/material.dart';

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
    bgColor: Colors.grey.shade400,
    textColor: Colors.grey.shade900,
    icon: Icons.notifications_active,
  ),
  'default': SnackBarTheme(
    bgColor: Colors.blue.shade200,
    textColor: Colors.blue.shade900,
  ),
};

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showSnackBar(
  String message, {
  Duration? duration, // Hacer duración opcional
  String? theme,
  SnackBarAction? action,
  VoidCallback? onHideCallback, // Parámetro para el callback
  IconData? icon,
  bool showCloseIcon = false,
}) {
  final SnackBarTheme myTheme = snackBarThemes[theme] ?? snackBarThemes['default']!;

  final IconData? selectedIcon = icon ?? myTheme.icon;

  // Si no se proporciona duración, usa el valor por defecto
  Duration snackBarDuration = duration ?? const Duration(seconds: 3);

  // Crea el contenido del SnackBar: si se pasa un ícono, lo muestra junto al texto
  final Widget snackBarContent = Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedIcon != null) ...[
          Icon(selectedIcon, color: myTheme.textColor),
          const SizedBox(width: 10),
        ],
        Text(
          message,
          style: TextStyle(color: myTheme.textColor), // Aplica el color del texto
        ),
      ],
    ),
  );

  // Crea el SnackBar
  final snackBar = SnackBar(
    content: snackBarContent,
    backgroundColor: myTheme.bgColor,
    duration: snackBarDuration,
    showCloseIcon: showCloseIcon,
    action: action,
    padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 10.0),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: myTheme.textColor, width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Muestra el SnackBar
  scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  scaffoldMessengerKey.currentState?.showSnackBar(snackBar);

  Future.delayed(snackBarDuration, () {
    if (onHideCallback != null) {
      onHideCallback();
    }
  });
}
