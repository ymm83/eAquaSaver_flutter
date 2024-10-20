import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import 'device_charts.dart';
import 'device_screen.dart';
import 'device_settings.dart';
import 'scan_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int pageIndex = 0;
  String _pageTitle = 'Scan Devices';
  final PageController _pageController = PageController();


  List<Widget> _scanButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.bluetooth),
        onPressed: () {
          setState(() {
            _pageTitle = 'Scan Devices';
          });
          _pageController.jumpToPage(0);
        },
      ),
      /*IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          setState(() {
            _pageTitle = 'Manager';
          });
          _pageController.jumpToPage(2);
        },
      ),*/
    ];
  }

  List<Widget> _chartsButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          setState(() {
            _pageTitle = 'Manager';
          });
          _pageController.jumpToPage(2);
        },
      ),
      IconButton(
        icon: const Icon(Icons.bar_chart_outlined),
        onPressed: () {
          setState(() {
            _pageTitle = 'Statistics';
          });
          _pageController.jumpToPage(3);
        },
      )
    ];
  }

  List<Widget> _managerButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          setState(() {
            _pageTitle = 'Settings';
          });
          _pageController.jumpToPage(2);
        },
      ),
      IconButton(
        icon: const Icon(Icons.bar_chart_outlined),
        onPressed: () {
          setState(() {
            _pageTitle = 'Statistics';
          });
          _pageController.jumpToPage(3);
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleBloc, BleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: state.showDetails == true
                ? (pageIndex == 1)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _pageTitle = 'Scan Devices';
                          });
                          _pageController.jumpToPage(0);
                          context.read<BleBloc>().add(const DetailsClose());
                        },
                      )
                    : ([2, 3].contains(pageIndex))
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              setState(() {
                                _pageTitle = 'Manager';
                              });
                              _pageController.jumpToPage(1);
                            },
                          )
                        : null
                : null,
            actions: state.showDetails ? _managerButtons(context) : _scanButtons(context),
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: Text(_pageTitle),
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            pageSnapping: true,
            controller: _pageController,
            onPageChanged: (index) {
              pageIndex = index;
              if (index == 0) {
                _pageTitle = 'Scan Devices';
                setState(() {});
              }
            },
            children: [
              ScanScreen(pageController: _pageController),
              BlocBuilder<BleBloc, BleState>(
                builder: (context, state) {
                  if (state is BleConnected) {
                    return DeviceScreen(device: state.device);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              BlocBuilder<BleBloc, BleState>(
                builder: (context, state) {
                  if (state is BleConnected) {
                    return DeviceSettings(device: state.device);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              BlocBuilder<BleBloc, BleState>(
                builder: (context, state) {
                  if (state is BleConnected) {
                    return DeviceCharts(device: state.device);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              )
            ],
          ),
        );
      },
    );
  }
}
