import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import 'device_allow.dart';
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
  final List<String> _pageTitle = ['Scan Devices', 'Manager', 'Settings', 'Statistics', 'Users'];
  final PageController _pageController = PageController();

  List<Widget> _scanButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.bluetooth),
        onPressed: () {
          _pageController.jumpToPage(0);
        },
      ),
    ];
  }

  List<Widget> _managerButtons(BuildContext context) {
    return [
      IconButton(
        icon: (pageIndex == 2)
            ? Icon(Icons.settings_sharp, color: Colors.blue.shade900)
            : const Icon(Icons.settings_outlined),
        onPressed: () {
          _pageController.jumpToPage(2); //Settings
        },
      ),
      IconButton(
        icon: (pageIndex == 3)
            ? Icon(
                Icons.bar_chart,
                color: Colors.blue.shade900,
                size: 28,
              )
            : const Icon(
                Icons.bar_chart_outlined,
                size: 28,
              ),
        onPressed: () {
          _pageController.jumpToPage(3); //Statics
        },
      ),
      IconButton(
        icon: (pageIndex == 4)
            ? Icon(
                Icons.manage_accounts_sharp,
                color: Colors.blue.shade900,
                size: 28,
              )
            : const Icon(
                Icons.manage_accounts_outlined,
                size: 28,
              ),
        onPressed: () {
          _pageController.jumpToPage(4); //Users
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleBloc, BleState>(
      builder: (context, state) {
        return Scaffold(
          // a==b ? a : ? a==c ? c : b
          appBar: AppBar(
            leading: state is BleConnected && state.showDetails && [2, 3, 4].contains(pageIndex)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      _pageController.jumpToPage(1); // manager
                    },
                  )
                : (pageIndex == 1)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _pageController.jumpToPage(0); // Scan
                          context.read<BleBloc>().add(const DetailsClose());
                        },
                      )
                    : null,
            actions: state is BleConnected && state.showDetails ? _managerButtons(context) : _scanButtons(context),
            backgroundColor: Colors.green[100],
            elevation: 0,
            title: Text(_pageTitle[pageIndex]),
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            pageSnapping: true,
            controller: _pageController,
            onPageChanged: (index) {
              pageIndex = index;
              setState(() {});
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
              ),
              BlocBuilder<BleBloc, BleState>(
                builder: (context, state) {
                  if (state is BleConnected) {
                    return DeviceAllow(device: state.device);
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
