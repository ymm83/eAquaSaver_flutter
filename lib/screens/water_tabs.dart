import 'package:eaquasaver_flutter_app/screens/device_charts.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final waterTabsController = Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            onPressed: () {
              setState(() {
                pageTitle = 'Water';
                pageChanged = 0;
              });
              _pageController.jumpToPage(0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {
              setState(() {
                pageTitle = 'Location';
                pageChanged = 1;
              });
              _pageController.jumpToPage(1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_sharp),
            onPressed: () {
              setState(() {
                pageTitle = 'Charts';
                pageChanged = 2;
              });
              _pageController.jumpToPage(2);
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
        children: [
          const WaterScreen(),
          const MapScreen(),
          DeviceCharts.withSampleData(),
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