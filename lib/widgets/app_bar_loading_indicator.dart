import 'package:flutter/material.dart';
import 'top_loading_indicator.dart';

class AppBarLoadingIndicator extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final Color? progressColor;
  final Color? backgroundColor;
  final Color? boxColor;

  const AppBarLoadingIndicator({
    Key? key,
    required this.isLoading,
    this.progressColor,
    this.backgroundColor,
    this.boxColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /* AppBar(
          title: Text('Mi AppBar Personalizada'),
          // Aquí puedes agregar más propiedades de la AppBar si lo deseas
        ),*/
        TopLoadingIndicator(
          isLoading: isLoading,
          progressColor: progressColor,
          backgroundColor: backgroundColor,
          boxColor: boxColor,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(4); // Altura de la AppBar + el LoadingIndicator
}
