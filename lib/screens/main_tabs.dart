import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ble/ble_bloc.dart';
import 'device_screen.dart';
import 'scan_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _pageChanged = 0;
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
                        _pageTitle = 'Scan Devices';
                      });
                      _pageController.jumpToPage(0);
                      context.read<BleBloc>().add(const DetailsClose());
                    },
                  )
                : null,
            actions: state.showDetails
                ? []
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
                          _pageTitle = 'Device Details';
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
              setState(() {
                _pageChanged = index;
                _pageTitle = index == 0 ? 'Scan Devices' : 'Device Details';
              });
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
              const Center(child: Text('Settings BLE'))
            ],
            
          ),
        );
      },
    );
  }
}
