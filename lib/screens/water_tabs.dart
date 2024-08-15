import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import 'map_sceen.dart';
import 'water_sceen.dart';

class WaterTabs extends StatefulWidget {
  const WaterTabs({super.key});

  @override
  State<WaterTabs> createState() => _WaterTabsState();
}

class _WaterTabsState extends State<WaterTabs> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  String pageTitle = 'Water';

  int pageChanged = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: pageChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    // Verifica el estado de conectividad
    final connectivityState = BlocProvider.of<ConnectivityBloc>(context).state;

    if (connectivityState is ConnectivityOnline) {
      _pageController.jumpToPage(page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay conexión a Internet.'),
          backgroundColor: Colors.red,
          showCloseIcon: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterTabsController = Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.science_outlined, color: Colors.blue[900]),
            onPressed: () {
              setState(() {
                pageTitle = 'Water';
                pageChanged = 0;
              });
              _navigateToPage(0);
            },
          ),
          IconButton(
            icon:  Icon(Icons.location_on_outlined, color: Colors.blue[900]),
            onPressed: () {
              setState(() {
                pageTitle = 'Location';
                pageChanged = 1;
              });
              _navigateToPage(1);
            },
          ),
        ],
        backgroundColor: Colors.green[100],
        elevation: 0,
        title: Text(pageTitle),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        pageSnapping: true,
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            pageChanged = index;
            pageTitle = index == 0 ? 'Water' : 'Location';
          });
        },
        children: const [
          WaterScreen(),
          MapScreen(),
        ],
      ),
    );
    return Scaffold(
      body: waterTabsController,
    );
  }
}

/*import 'package:flutter/material.dart';
import 'map_sceen.dart';
import 'water_sceen.dart';

class WaterTabs extends StatefulWidget {
  const WaterTabs({super.key});

  @override
  State<WaterTabs> createState() => _WaterTabsState();
}

int pageChanged = 0;
String pageTitle = 'Water';

class _WaterTabsState extends State<WaterTabs> {
  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController();
    final WaterTabsController = DefaultTabController(
        q: 4,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'Water';
                    });
                    pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 250), curve: Curves.bounceInOut);
                  }),
              IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'Location';
                    });
                    pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 250), curve: Curves.bounceInOut);
                  }),
            ],
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: Text(pageTitle),
          ),
          body: PageView(
            pageSnapping: true,
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                pageChanged = index;
              });
              print(pageChanged);
            },
            children: [
              const WaterScreen(),
              const MapScreen(),
              Container(
                color: Colors.brown,
              ),
            ],
          ),
        ));
    return Scaffold(
      body: WaterTabsController,
    );
  }
}
*/