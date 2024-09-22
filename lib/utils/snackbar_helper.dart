import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext argContext,
  String argMessage,
  String? backgroundColor, {
  Duration? duration, // Hacer duración opcional
  SnackBarAction? action,
  VoidCallback? onHideCallback, // Parámetro para el callback
}) {
  Color bgColor = Theme.of(argContext).colorScheme.primary;
  Color? textColor;

  // Determina el color de fondo y el color del texto según el tipo
  if (backgroundColor == 'warning') {
    bgColor = Colors.yellow.shade700;
    textColor = Colors.black87;
  } else if (backgroundColor == 'error') {
    bgColor = Colors.red.shade500;
    textColor = Colors.white;
  } else if (backgroundColor == 'success') {
    bgColor = Colors.green;
    textColor = Colors.white;
  } else {
    bgColor = Colors.blueAccent;
    textColor = Colors.black87;
  }

  // Si no se proporciona duración, usa el valor por defecto
  Duration snackBarDuration = duration ?? const Duration(seconds: 3);

  // Crea el SnackBar
  final snackBar = SnackBar(
    content: Text(
      argMessage,
      style: TextStyle(color: textColor),
    ),
    backgroundColor: bgColor,
    duration: snackBarDuration,
    action: action,
  );

  // Muestra el SnackBar
  ScaffoldMessenger.of(argContext).showSnackBar(snackBar);

  Future.delayed(snackBarDuration, () {
    if (onHideCallback != null) {
      onHideCallback();
    }
  });
}
