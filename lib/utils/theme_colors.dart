///import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final ThemeData darkAppTheme = ThemeData.dark().copyWith(
  brightness: Brightness.dark,
  primaryColor: Colors.amber.shade100,
  scaffoldBackgroundColor: const Color(0xFF0D0B02),
  drawerTheme: const DrawerThemeData(scrimColor: Colors.white),
  appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D0B02),
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white)),
  colorScheme: const ColorScheme.dark(
    surface: Colors.black,
    secondary: Colors.red,
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
  scaffoldBackgroundColor: Colors.blue[200],
  drawerTheme: const DrawerThemeData(scrimColor: Colors.black),
  appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Color(0xFF0D0B02),
      iconTheme: IconThemeData(color: Color(0xFF0D0B02)),
      actionsIconTheme: IconThemeData(color: Color(0xFF0D0B02))),
  colorScheme: const ColorScheme.light(
    surface: Colors.black,
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
final ThemeData darkAppTheme2 = ThemeData.dark().copyWith(
  primaryColor: Colors.amber.shade100,
  // Define the default brightness and colors.
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5E7691),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF375778),
    onPrimaryContainer: Color(0xFFFFFFFF),
    primaryFixed: Color(0xFFD1DBE5),
    primaryFixedDim: Color(0xFFAABACB),
    onPrimaryFixed: Color(0xFF111B26),
    onPrimaryFixedVariant: Color(0xFF172432),
    secondary: Color(0xFFEBA1A6),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFFAE424F),
    onSecondaryContainer: Color(0xFFFFFFFF),
    secondaryFixed: Color(0xFFF2D1D4),
    secondaryFixedDim: Color(0xFFEBB5B9),
    onSecondaryFixed: Color(0xFF400307),
    onSecondaryFixedVariant: Color(0xFF73060E),
    tertiary: Color(0xFFF4CFD1),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF96434F),
    onTertiaryContainer: Color(0xFFFFFFFF),
    tertiaryFixed: Color(0xFFF3E8E8),
    tertiaryFixedDim: Color(0xFFEAD5D7),
    onTertiaryFixed: Color(0xFF561317),
    onTertiaryFixedVariant: Color(0xFF871E25),
    error: Color(0xFFCF6679),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFFB1384E),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFF080808),
    onSurface: Color(0xFFF1F1F1),
    surfaceDim: Color(0xFF060606),
    surfaceBright: Color(0xFF2C2C2C),
    surfaceContainerLowest: Color(0xFF010101),
    surfaceContainerLow: Color(0xFF0E0E0E),
    surfaceContainer: Color(0xFF151515),
    surfaceContainerHigh: Color(0xFF1D1D1D),
    surfaceContainerHighest: Color(0xFF282828),
    onSurfaceVariant: Color(0xFFCACACA),
    outline: Color(0xFF777777),
    outlineVariant: Color(0xFF414141),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE8E8E8),
    onInverseSurface: Color(0xFF2A2A2A),
    inversePrimary: Color(0xFF303944),
    surfaceTint: Color(0xFF5E7691),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D0B02),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
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

/// Light [ColorScheme] made with FlexColorScheme v8.2.0.
/// Requires Flutter 3.22.0 or later.
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF375778),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFA4C4ED),
  onPrimaryContainer: Color(0xFF000000),
  primaryFixed: Color(0xFFD1DBE5),
  primaryFixedDim: Color(0xFFAABACB),
  onPrimaryFixed: Color(0xFF111B26),
  onPrimaryFixedVariant: Color(0xFF172432),
  secondary: Color(0xFFF98D94),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFFFFC4C6),
  onSecondaryContainer: Color(0xFF000000),
  secondaryFixed: Color(0xFFF2D1D4),
  secondaryFixedDim: Color(0xFFEBB5B9),
  onSecondaryFixed: Color(0xFF400307),
  onSecondaryFixedVariant: Color(0xFF73060E),
  tertiary: Color(0xFFF2C4C7),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFFFFE3E5),
  onTertiaryContainer: Color(0xFF000000),
  tertiaryFixed: Color(0xFFF3E8E8),
  tertiaryFixedDim: Color(0xFFEAD5D7),
  onTertiaryFixed: Color(0xFF561317),
  onTertiaryFixedVariant: Color(0xFF871E25),
  error: Color(0xFFB00020),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFCD9DF),
  onErrorContainer: Color(0xFF000000),
  surface: Color(0xFFFCFCFC),
  onSurface: Color(0xFF111111),
  surfaceDim: Color(0xFFE0E0E0),
  surfaceBright: Color(0xFFFDFDFD),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF8F8F8),
  surfaceContainer: Color(0xFFF3F3F3),
  surfaceContainerHigh: Color(0xFFEDEDED),
  surfaceContainerHighest: Color(0xFFE7E7E7),
  onSurfaceVariant: Color(0xFF393939),
  outline: Color(0xFF919191),
  outlineVariant: Color(0xFFD1D1D1),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2A2A),
  onInverseSurface: Color(0xFFF1F1F1),
  inversePrimary: Color(0xFFC3D7EB),
  surfaceTint: Color(0xFF375778),
);

/// Dark [ColorScheme] made with FlexColorScheme v8.2.0.
/// Requires Flutter 3.22.0 or later.
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5E7691),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF375778),
  onPrimaryContainer: Color(0xFFFFFFFF),
  primaryFixed: Color(0xFFD1DBE5),
  primaryFixedDim: Color(0xFFAABACB),
  onPrimaryFixed: Color(0xFF111B26),
  onPrimaryFixedVariant: Color(0xFF172432),
  secondary: Color(0xFFEBA1A6),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFFAE424F),
  onSecondaryContainer: Color(0xFFFFFFFF),
  secondaryFixed: Color(0xFFF2D1D4),
  secondaryFixedDim: Color(0xFFEBB5B9),
  onSecondaryFixed: Color(0xFF400307),
  onSecondaryFixedVariant: Color(0xFF73060E),
  tertiary: Color(0xFFF4CFD1),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF96434F),
  onTertiaryContainer: Color(0xFFFFFFFF),
  tertiaryFixed: Color(0xFFF3E8E8),
  tertiaryFixedDim: Color(0xFFEAD5D7),
  onTertiaryFixed: Color(0xFF561317),
  onTertiaryFixedVariant: Color(0xFF871E25),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  errorContainer: Color(0xFFB1384E),
  onErrorContainer: Color(0xFFFFFFFF),
  surface: Color(0xFF080808),
  onSurface: Color(0xFFF1F1F1),
  surfaceDim: Color(0xFF060606),
  surfaceBright: Color(0xFF2C2C2C),
  surfaceContainerLowest: Color(0xFF010101),
  surfaceContainerLow: Color(0xFF0E0E0E),
  surfaceContainer: Color(0xFF151515),
  surfaceContainerHigh: Color(0xFF1D1D1D),
  surfaceContainerHighest: Color(0xFF282828),
  onSurfaceVariant: Color(0xFFCACACA),
  outline: Color(0xFF777777),
  outlineVariant: Color(0xFF414141),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E8E8),
  onInverseSurface: Color(0xFF2A2A2A),
  inversePrimary: Color(0xFF303944),
  surfaceTint: Color(0xFF5E7691),
);

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.2.0.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
/*abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
      // Using FlexColorScheme built-in FlexScheme enum based colors
      scheme: FlexScheme.deepBlue,
      // Input color modifiers.
      useMaterial3ErrorColors: true,
      // Component theme configurations for light mode.
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        switchSchemeColor: SchemeColor.black,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputCursorSchemeColor: SchemeColor.onTertiary,
        inputSelectionSchemeColor: SchemeColor.onPrimaryFixed,
        inputSelectionHandleSchemeColor: SchemeColor.surfaceTint,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ));
  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // Using FlexColorScheme built-in FlexScheme enum based colors.
    scheme: FlexScheme.deepBlue,
    // Input color modifiers.
    useMaterial3ErrorColors: true,
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      switchSchemeColor: SchemeColor.black,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    useMaterial3: false,
  );
}*/
