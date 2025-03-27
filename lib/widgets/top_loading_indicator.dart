import 'package:flutter/material.dart';

class TopLoadingIndicator extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final Color? progressColor; // Color opcional para el indicador de progreso
  final Color? backgroundColor; // Color opcional para el fondo del indicador
  final Color? boxColor; // Color de fondo para el SizedBox
  final double? height;

  const TopLoadingIndicator({
    Key? key,
    required this.isLoading,
    this.progressColor,
    this.backgroundColor,
    this.boxColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: LinearProgressIndicator(
              color: progressColor ?? Colors.green.shade800,
              backgroundColor: backgroundColor ?? Colors.green.shade200,
              minHeight: height ?? 1,
            ),
          )
        : Container(
            height: height ?? 1,
            color: boxColor ?? Colors.green.shade200,
          );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 1);
}