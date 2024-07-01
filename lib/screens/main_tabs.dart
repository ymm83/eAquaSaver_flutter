import 'package:flutter/material.dart';
import 'scan_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

int pageChanged = 0;
String pageTitle = 'Water';

class _MainTabsState extends State<MainTabs> {
  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController();
    final BLETabsController = DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  icon: const Icon(Icons.bluetooth),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'bluetooth';
                    });
                    pageController.animateToPage(0, duration: Duration(milliseconds: 250), curve: Curves.bounceInOut);
                  }),
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    setState(() {
                      pageTitle = 'settings';
                    });
                    pageController.animateToPage(1, duration: Duration(milliseconds: 250), curve: Curves.bounceInOut);
                  }),
            ],
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: const TabBar(
              /* labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  color: Colors.white),
              dividerHeight: 50,
              indicatorColor: Colors.red,*/
              tabs: [
                Tab(
                  icon: Icon(Icons.bluetooth),
                ),
                Tab(
                  icon: Icon(Icons.settings),
                )
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ScanScreen(),
              Center(child: Text('Content for Tab 2')),
            ],
          ),
        ));
    return Scaffold(
      body: BLETabsController,
    );
  }
}
