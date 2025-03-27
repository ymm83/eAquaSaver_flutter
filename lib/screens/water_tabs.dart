import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../utils/snackbar_helper.dart';
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
  late ConnectivityBloc connectivityBloc;

  @override
  void initState() {
    connectivityBloc = BlocProvider.of<ConnectivityBloc>(context);
    _pageController = PageController(initialPage: pageChanged);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void connectionOffMessage() {
    showSnackBar('You are offline!', theme: 'error', icon: Icons.cloud_off_outlined);
  }

  void _navigateToPage(int page) {
    if (connectivityBloc.state is ConnectivityOnline) {
      _pageController.jumpToPage(page);
    } else {
      connectionOffMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              Container(
                color: Theme.of(context).appBarTheme.backgroundColor, // Color de fondo del AppBar
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 0), // Ajusta el padding si es necesario
                        child: Text(
                          pageTitle,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.blue.shade900),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.science_outlined,
                        color: Colors.blue[900],
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          pageTitle = 'Water';
                          pageChanged = 0;
                        });
                        _navigateToPage(0);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.blue[900],
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          pageTitle = 'Location';
                          pageChanged = 1;
                        });
                        _navigateToPage(1);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
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
              ),
            ],
          )

          /*appBar: AppBar(
        actions: [
          
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
    );*/
          ),
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