import 'package:flutter/material.dart';

import 'bar_item.dart';
import 'build_icon_button.dart';
import 'build_running_drop.dart';

typedef OnButtonPressCallback = void Function(int index);

class WaterDropNavBar extends StatefulWidget {
  /// Background Color of the bar.
  final Color backgroundColor;

  /// Callback When individual barItem is pressed.
  final OnButtonPressCallback onItemSelected;

  /// Current selected index of the bar item (prop from parent).
  final int selectedIndex;

  /// List of bar items that shows horizontally, Minimum 2 and maximum 4 items.
  final List<BarItem> barItems;

  /// Color of water drop which is also the active icon color.
  final Color waterDropColor;

  /// Inactive icon color by default it will use water drop color.
  final Color inactiveIconColor;

  /// Each active & inactive icon size, default value is 30 don't make it too big or small.
  final double iconSize;

  /// Bottom padding of the bar. If nothing is provided the it will use
  /// [MediaQuery.of(context).padding.bottom] value.
  final double? bottomPadding;

  const WaterDropNavBar({
    required this.barItems,
    required this.selectedIndex,
    required this.onItemSelected,
    this.bottomPadding,
    this.backgroundColor = Colors.white,
    this.waterDropColor = const Color(0xFF5B75F0),
    this.iconSize = 28,
    Color? inactiveIconColor,
    Key? key,
  })  : inactiveIconColor = inactiveIconColor ?? waterDropColor,
        assert(barItems.length > 1, 'You must provide minimum 2 bar items'),
        assert(barItems.length < 5, 'Maximum bar items count is 4'),
        super(key: key);

  @override
  _WaterDropNavBarState createState() => _WaterDropNavBarState();
}

class _WaterDropNavBarState extends State<WaterDropNavBar> with TickerProviderStateMixin {
  late int _previousIndex;
  late int _currentIndex; // estado visual interno
  int? _pendingIndex; // si el padre pide cambio mientras anima

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _previousIndex = widget.selectedIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Ponemos el controller en 1.0 (estado "idle" final) para evitar animar al iniciar.
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant WaterDropNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el padre cambió el selectedIndex desde fuera (p. ej. PageController),
    // debemos animar la barra para reflejar ese cambio.
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final int newIndex = widget.selectedIndex;
      if (newIndex == _currentIndex) return;

      if (_controller.isAnimating) {
        // Si ya se está animando, encolamos la petición
        _pendingIndex = newIndex;
      } else {
        // Guardamos indice previo y arrancamos animación.
        _previousIndex = _currentIndex;
        _controller.forward(from: 0.0).whenComplete(() {
          if (!mounted) return;
          setState(() {
            _currentIndex = newIndex;
          });

          // Si hubo una petición pendiente durante la animación, la procesamos:
          if (_pendingIndex != null && _pendingIndex != _currentIndex) {
            final pending = _pendingIndex!;
            _pendingIndex = null;
            _previousIndex = _currentIndex;
            _controller.forward(from: 0.0).whenComplete(() {
              if (!mounted) return;
              setState(() {
                _currentIndex = pending;
              });
            });
          }
        });
      }
    }
  }

  void _onTap(int index) {
    if (!mounted) return;
    if (_controller.isAnimating) return;

    if (_currentIndex == index) {
      // mismo índice: notificar al padre inmediatamente (comportamiento anterior)
      widget.onItemSelected(index);
      return;
    }

    // guardamos desde dónde animar
    _previousIndex = _currentIndex;
    // arrancamos animación y, al terminar, actualizamos estado y notificamos al padre
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
      });

      // notificamos al padre sólo cuando la animación terminó
      widget.onItemSelected(index);

      // si durante la animación hubo otra petición (por ejemplo, padre cambió),
      // la procesamos en cadena:
      if (_pendingIndex != null && _pendingIndex != _currentIndex) {
        final pending = _pendingIndex!;
        _pendingIndex = null;
        _previousIndex = _currentIndex;
        _controller.forward(from: 0.0).whenComplete(() {
          if (!mounted) return;
          setState(() {
            _currentIndex = pending;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _currentIndex;
    final Color backgroundColor = widget.backgroundColor;
    final Color dropColor = widget.waterDropColor;
    final List<BarItem> items = widget.barItems;
    final double iconSize = widget.iconSize;
    final Color inactiveIconColor = widget.inactiveIconColor;
    final double bottomPadding = widget.bottomPadding ?? MediaQuery.of(context).padding.bottom;
    final double barHeight = 60 + bottomPadding;

    return Container(
      height: barHeight,
      color: backgroundColor,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.map(
                  (BarItem item) {
                    final int index = items.indexOf(item);
                    return BuildIconButton(
                      bottomPadding: bottomPadding,
                      barHeight: barHeight,
                      barColor: backgroundColor,
                      inactiveColor: inactiveIconColor,
                      color: dropColor,
                      index: index,
                      iconSize: iconSize,
                      seletedIndex: selectedIndex,
                      controller: _controller,
                      selectedIcon: item.filledIcon,
                      unslectedIcon: item.outlinedIcon,
                      onPressed: () => _onTap(index),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
          BuildRunningDrop(
            itemCount: items.length,
            controller: _controller,
            selectedIndex: selectedIndex,
            previousIndex: _previousIndex,
            color: dropColor,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
