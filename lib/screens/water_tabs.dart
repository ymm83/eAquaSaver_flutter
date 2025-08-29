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
  late final PageController _pageController;
  String pageTitle = 'Water';
  int pageChanged = 0;
  late ConnectivityBloc connectivityBloc;

  @override
  void initState() {
    super.initState();
    connectivityBloc = BlocProvider.of<ConnectivityBloc>(context);
    _pageController = PageController(initialPage: 0); // 👈 se crea solo una vez
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
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        pageTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.science_outlined, color: Colors.blue[900], size: 30),
                    onPressed: () => _navigateToPage(0),
                  ),
                  IconButton(
                    icon: Icon(Icons.location_on_outlined, color: Colors.blue[900], size: 30),
                    onPressed: () => _navigateToPage(1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    pageChanged = index; // solo afecta la UI
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
        ),
      ),
    );
  }
}
