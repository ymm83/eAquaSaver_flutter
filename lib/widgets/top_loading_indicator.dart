import 'package:flutter/material.dart';

class TopLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final Color? progressColor; // Color opcional para el indicador de progreso
  final Color? backgroundColor; // Color opcional para el fondo del indicador
  final Color? boxColor; // Color de fondo para el SizedBox

  const TopLoadingIndicator({
    Key? key,
    required this.isLoading,
    this.progressColor,
    this.backgroundColor,
    this.boxColor, // Color predeterminado para el SizedBox
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: LinearProgressIndicator(
              color: progressColor ?? Colors.green.shade800, 
              backgroundColor: backgroundColor ?? Colors.green.shade200, 
            ),
          )
        : Container(
            height: 4,
            color: boxColor ?? Colors.green.shade200, 
          );
  }
}