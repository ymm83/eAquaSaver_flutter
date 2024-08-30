import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import 'device_charts.dart';
import 'device_screen.dart';
import 'scan_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int pageChanged = 0;
  String _pageTitle = 'Scan Devices';
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleBloc, BleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: state.showDetails
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _pageTitle = 'Manager';
                      });
                      _pageController.jumpToPage(0);
                      context.read<BleBloc>().add(const DetailsClose());
                    },
                  )
                : null,
            actions: state.showDetails
                ? [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        setState(() {
                          _pageTitle = 'Manager';
                        });
                        _pageController.jumpToPage(1);
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
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.bluetooth),
                      onPressed: () {
                        setState(() {
                          _pageTitle = 'Scan Devices';
                        });
                        _pageController.jumpToPage(0);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        setState(() {
                          _pageTitle = 'Manager';
                        });
                        _pageController.jumpToPage(2);
                      },
                    ),
                  ],
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: Text(_pageTitle),
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            pageSnapping: true,
            controller: _pageController,
            onPageChanged: (index) {
              pageChanged = index;
              if (index == 0) {
                setState(() {
                  _pageTitle = 'Scan Devices';
                });
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
              const Center(child: Text('Settings BLE')),
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
