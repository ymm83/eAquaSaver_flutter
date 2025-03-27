import 'package:flutter/material.dart';

final ThemeData darkAppTheme = ThemeData.dark().copyWith(
  brightness: Brightness.dark,
  primaryColor: Colors.amber.shade100,
  scaffoldBackgroundColor: Color(0xFF0D0B02),
  primaryColorDark: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF0D0B02),
    foregroundColor: Colors.white,
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.amber,
    disabledColor: Colors.grey,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.green,
    ),
  ),
);

final ThemeData lightAppTheme = ThemeData.light().copyWith(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: Colors.blue.shade200,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.grey.shade900,
  ),
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    secondary: Colors.black,
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blue,
    disabledColor: Colors.grey,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.green,
    ),
  ),
);
