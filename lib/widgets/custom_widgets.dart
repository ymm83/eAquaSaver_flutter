import 'package:flutter/material.dart';

Widget buildRoleIcon(String? role) {
  ///debugPrint('role: $role');
  IconData iconData;
  if (role == 'Admin') {
    iconData = Icons.admin_panel_settings;
  } else if (role == 'Member') {
    iconData = Icons.person;
  } else if (role == 'Credits') {
    iconData = Icons.credit_card;
  } else if (role == 'Recerved') {
    iconData = Icons.calendar_month;
  } else {
    iconData = Icons.lock_outline;
  }

  return role != null ? Icon(iconData) : const SizedBox.shrink();
}

// Función para construir un widget de carga circular
Widget buildLoadingCircular({
  String? text,
  TextStyle? style,
  Color? color,
  Color? backgroundColor,
}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 5),
          child: CircularProgressIndicator(
            color: color ?? Colors.green.shade800,
            backgroundColor: backgroundColor ?? Colors.green.shade200,
          ),
        ),
        if (text != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: style ?? TextStyle(),
            ),
          ),
      ],
    ),
  );
}

// Función para construir un widget de carga lineal
Widget buildLoadingLinear({
  String? text,
  TextStyle? style,
  Color? color,
  Color? backgroundColor,
}) {
  return Center(
    child: Column(
      children: [
        if (text != null)
          Center(
            child: Text(
              text,
              style: style ?? TextStyle(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 5),
          child: LinearProgressIndicator(
            color: color ?? Colors.green.shade800,
            backgroundColor: backgroundColor ?? Colors.green.shade200,
          ),
        ),
      ],
    ),
  );
}
