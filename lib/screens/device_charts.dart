import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../bloc/beacon/beacon_bloc.dart';
//import '../widgets/device_bar_chart.dart';
import '../widgets/device_pie_chart.dart';

class DeviceCharts extends StatefulWidget {
  final bool animate;
  final BluetoothDevice? device;

  const DeviceCharts({super.key, this.animate = false, this.device});

  @override
  DeviceChartsState createState() => DeviceChartsState();
}

class DeviceChartsState extends State<DeviceCharts> {
  //late Timer beaconTimer;

  @override
  void initState() {
    super.initState();
    //context.read<BeaconBloc>().add(FakeData());
    //beaconTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //context.read<BeaconBloc>().add(FakeData());
    //});
  }

  @override
  void dispose() {
    //beaconTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeaconBloc, BeaconState>(
      builder: (context, state) {
        if (state is BeaconLoaded) {
          debugPrint('------ state.beaconData: ${state.beaconData.toString()}');

          if (state.beaconData.isEmpty) {
            return const Text('No hay datos para mostrar');
          } else if (state.beaconData['totalRecovered'] == 0 &&
              state.beaconData['totalHotUsed'] == 0 &&
              state.beaconData['totalColdUsed'] == 0) {
            return const Text('No hay datos para mostrar');
          } else {
            return ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 150.0),
              child: DevicePieChart(beaconData: state.beaconData),
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

/// Data model for the chart


/*
class DeviceCharts extends StatefulWidget {
  final List<charts.Series<dynamic, String>>? seriesList;
  final bool animate;
  final BluetoothDevice device;

  DeviceCharts({required this.device, this.animate = false, this.seriesList, super.key});

  /// Creates a [BarChart] with sample data and no transition.
  /*factory DeviceCharts.withSampleData() {
    return DeviceCharts(
      seriesList: _createSampleData(),
      device: super.device,
      animate: false,
  );
  }*/

  // EXCLUDE_FROM_GALLERY_DOCS_START
  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  /*factory DeviceCharts.withRandomData() {
    return DeviceCharts(_createRandomData());
  }*/

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> _createRandomData() {
    final random = Random();

    final data = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
          id: 'Sales',
          domainFn: (OrdinalSales sales, _) => sales.year,
          measureFn: (OrdinalSales sales, _) => sales.sales,
          data: data,
          // Set a label accessor to control the text of the bar label.
          labelAccessorFn: (OrdinalSales sales, _) => sales.sales.toString())
    ];
  }

  @override
  State<DeviceCharts> createState() => DeviceChartsState();

  /// Create one series with sample hard coded data.
  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final data = [
      OrdinalSales('Enero', 5),
      OrdinalSales('Febrero', 25),
      OrdinalSales('Marzo', 100),
      OrdinalSales('Abril', 75),
      OrdinalSales('Mayo', 25),
      OrdinalSales('Junio', 35),
      OrdinalSales('Julio', 16),
      OrdinalSales('Agosto', 90),
    ];

    return [
      charts.Series<OrdinalSales, String>(
          id: 'Sales',
          domainFn: (OrdinalSales sales, _) => sales.year,
          measureFn: (OrdinalSales sales, _) => sales.sales,
          data: data,
          displayName: 'ddd',
          // Set a label accessor to control the text of the bar label.
          labelAccessorFn: (OrdinalSales sales, _) => '${sales.sales.toString()}')
    ];
  }
}

class DeviceChartsState extends State<DeviceCharts> {
  final seriesList2 = DeviceCharts._createSampleData();
  StreamSubscription? _charSubscription;
  List<charts.Series<TimeSeriesValue, DateTime>> _seriesList = [];
  List<TimeSeriesValue> _data = [];
  List<BluetoothCharacteristic> _targetCharacteristics = [];
  List<StreamSubscription<List<int>>> _charSubscriptions = [];
  List<TimeSeriesValue> _dataWholeUsedWater = [];
  List<TimeSeriesValue> _dataWholeSavedWater = [];
  List<TimeSeriesValue> _dataCurrentUsedWater = [];
  List<TimeSeriesValue> _dataCurrentSavedWater = [];

  void _addData(String charName, int value) {
    DateTime now = DateTime.now();

    /*switch (charName) {
     case 'current_saved_water':
        _dataCurrentSavedWater.add(TimeSeriesValue(now, value));
        break;
      case 'current_used_water':
        _dataCurrentUsedWater.add(TimeSeriesValue(now, value));
        break;
      case 'whole_saved_water':
        _dataWholeSavedWater.add(TimeSeriesValue(now, value));
        break;
      case 'whole_used_water':
        _dataWholeUsedWater.add(TimeSeriesValue(now, value));
        break;
      default:
       
        break;
    }*/
    // _testWaterData.add(TimeSeriesValue(now, random.nextInt(100)));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesValue, DateTime>> _createSampleData2() {
    final data = [
      TimeSeriesValue(DateTime(2017, 9, 19), 5),
      TimeSeriesValue(DateTime(2017, 9, 26), 25),
      TimeSeriesValue(DateTime(2017, 10, 3), 100),
      TimeSeriesValue(DateTime(2017, 10, 10), 75),
    ];

    return [
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'SSssss',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesValue sales, _) => sales.time,
        measureFn: (TimeSeriesValue sales, _) => sales.value,
        data: data,
      )
    ];
  }

  final List<TimeSeriesValue> _testWaterData = [
    TimeSeriesValue(DateTime.now(), Random().nextInt(100)),
    TimeSeriesValue(DateTime.now(), Random().nextInt(100)),
    TimeSeriesValue(DateTime.now(), Random().nextInt(100)),
    TimeSeriesValue(DateTime.now(), Random().nextInt(100)),
    TimeSeriesValue(DateTime.now(), Random().nextInt(100)),
  ];

  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final data = [
      OrdinalSales('Enero', 5),
      OrdinalSales('Febrero', 25),
      OrdinalSales('Marzo', 100),
      OrdinalSales('Abril', 75),
      OrdinalSales('Mayo', 25),
      OrdinalSales('Junio', 35),
      OrdinalSales('Julio', 16),
      OrdinalSales('Agosto', 90),
    ];

    return [
      charts.Series<OrdinalSales, String>(
          id: 'Sales',
          domainFn: (OrdinalSales sales, _) => sales.year,
          measureFn: (OrdinalSales sales, _) => sales.sales,
          data: data,
          displayName: 'ddd',
          // Set a label accessor to control the text of the bar label.
          labelAccessorFn: (OrdinalSales sales, _) => '${sales.sales.toString()}')
    ];
  }

  void _updateChart() {
    /* _seriesList = [
      /*charts.Series<TimeSeriesValue, DateTime>(
        id: 'Current Save',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesValue values, _) => values.time,
        measureFn: (TimeSeriesValue values, _) => values.value,
        data: _dataWholeUsedWater,
      ),
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'Whole Save',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeSeriesValue values, _) => values.time,
        measureFn: (TimeSeriesValue values, _) => values.value,
        data: _dataWholeSavedWater,
      ),
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'Current Used',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeSeriesValue values, _) => values.time,
        measureFn: (TimeSeriesValue values, _) => values.value,
        data: _dataCurrentUsedWater,
      ),
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'Current Saved',
        colorFn: (_, __) => charts.MaterialPalette.yellow.shadeDefault,
        domainFn: (TimeSeriesValue values, _) => values.time,
        measureFn: (TimeSeriesValue values, _) => values.value,
        data: _dataCurrentSavedWater,
      ),**/
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'Test data',
        colorFn: (_, __) => charts.MaterialPalette.yellow.shadeDefault,
        domainFn: (TimeSeriesValue values, _) => values.time,
        measureFn: (TimeSeriesValue values, _) => values.value,
        data: _testWaterData2,
      ),
    ];*/
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _charSubscription?.cancel();
    super.dispose();
  }

  int _convertData(List<int> value) {
    // Asumiendo que los valores son enteros de 16 bits sin signo
    return ByteData.sublistView(Uint8List.fromList(value)).getUint16(0, Endian.little);
  }

  // EXCLUDE_FROM_GALLERY_DOCS_END
  @override
  Widget build(BuildContext context) {
    List<BluetoothCharacteristic> _targetCharacteristics = [];
    final Map<String, String> _characteristicNames = {
      'current_save_water': '40cddbae-0x0e58-0x47b1-0xb2fa-0xa93c4993d81d',
      'current_used_water': '40cddbaf-0x0e58-0x47b1-0xb2fa-0xa93c4993d81d',
      'whole_saved_water': '40cddbb0-0x0e58-0x47b1-0xb2fa-0xa93c4993d81d',
      'whole_used_water': '40cddbb1-0x0e58-0x47b1-0xb2fa-0xa93c4993d81d',
    };
    /*for (BluetoothService service in widget.device.servicesList) {
      // if (service.serviceUuid.toString() == '40cddba8-0e58-47b1-b2fa-a93c4993d81d') {
      debugPrint('${service.serviceUuid.toString()}');
      debugPrint('${service.characteristics.asMap()}');
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (_characteristicNames.containsValue(characteristic.uuid.toString())) {
          _targetCharacteristics.add(characteristic);
          characteristic.setNotifyValue(true);

          _addData(characteristic.uuid.toString().substring(0,4), Random().nextInt(100)); //no va aki
          _updateChart(); // no va aki
          /* var sub = characteristic.lastValueStream.listen((value) {
            setState(() {
              String charName = _characteristicNames.entries.firstWhere((entry) => entry.value == characteristic.uuid.toString()).key;
              //var intValue = String.fromCharCodes(value);
              //_addData(charName, String.fromCharCodes(value).);
              //_addData(charName, value.first);
              _addData(charName, 400);
              _updateChart();
            });
          });
          _charSubscriptions.add(sub);*/
        }
      }
      //}
    }*/

    /* return Scaffold(
      appBar: AppBar(title: Text('BLE Data Chart')),
      body: charts.TimeSeriesChart(_seriesList, animate: true),
    );*/

    return charts.TimeSeriesChart(
      _createSampleData2(),
      animate: true,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );

    /*return Column(
      children: [
        const SizedBox(height: 20),
        //charts.TimeSeriesChart(_seriesList, animate: true),
        SizedBox(
          width: 900,
          height: 300,
          child: charts.TimeSeriesChart(
            behaviors: [
              charts.ChartTitle('Litros',
                  behaviorPosition: charts.BehaviorPosition.top,
                  titleOutsideJustification: charts.OutsideJustification.start,
                  innerPadding: 18),
              charts.ChartTitle('Meses',
                  behaviorPosition: charts.BehaviorPosition.bottom,
                  titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
              /*charts.ChartTitle('Start title',
                  behaviorPosition: charts.BehaviorPosition.start,
                  titleOutsideJustification: charts.OutsideJustification.middleDrawArea),*/
              /*charts.ChartTitle('End title',
                  behaviorPosition: charts.BehaviorPosition.end,
                  titleOutsideJustification: charts.OutsideJustification.middleDrawArea),*/
            ],
            _createSampleData2(),
            //widget.seriesList ?? seriesList2,
            animate: true,
            // Set a bar label decorator.
            // Example configuring different styles for inside/outside:
            //       barRendererDecorator: new charts.BarLabelDecorator(
            //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
            //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
           // barRendererDecorator: charts.BarLabelDecorator<String>(),
            domainAxis: const charts.OrdinalAxisSpec(),
          ),
        ),
      ],
    );*/
  }
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

class TimeSeriesValue {
  final DateTime time;
  final int value;

  TimeSeriesValue(this.time, this.value);
}
*/