import 'package:flutter/material.dart';
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
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'Water';
                    });
                    pageController.animateToPage(0, duration: Duration(milliseconds: 250), curve: Curves.bounceInOut);
                  }),
              IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'Location';
                    });
                    pageController.animateToPage(1, duration: Duration(milliseconds: 250), curve: Curves.bounceInOut);
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
          ), /*const TabBarView(
            children: [
              WaterScreen(),
              MapScreen(),
            ],
          ),*/
        ));
    return Scaffold(
      body: WaterTabsController,
    );
  }
}
