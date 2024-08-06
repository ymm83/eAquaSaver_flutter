// EXCLUDE_FROM_GALLERY_DOCS_START
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
// EXCLUDE_FROM_GALLERY_DOCS_END
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  State<DeviceCharts> createState() => _DeviceChartsState();

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

class _DeviceChartsState extends State<DeviceCharts> {
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
    switch (charName) {
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
    }
  }

  void _updateChart() {
    _seriesList = [
      charts.Series<TimeSeriesValue, DateTime>(
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
      ),
    ];
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
    for (BluetoothService service in widget.device.servicesList) {
      if (service.serviceUuid.toString() == '40cddba8-0e58-47b1-b2fa-a93c4993d81d') {
        debugPrint('${service.serviceUuid.toString()}');
        debugPrint('${service.characteristics.asMap()}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (_characteristicNames.containsValue(characteristic.uuid.toString())) {
            _targetCharacteristics.add(characteristic);
            characteristic.setNotifyValue(true);
            var sub = characteristic.lastValueStream.listen((value) {
              setState(() {
                String charName = _characteristicNames.entries
                    .firstWhere((entry) => entry.value == characteristic.uuid.toString())
                    .key;
                int intValue = _convertData(value);
                _addData(charName, value.first);
                _updateChart();
              });
            });
            _charSubscriptions.add(sub);
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('BLE Data Chart')),
      body: charts.TimeSeriesChart(_seriesList, animate: true),
    );
    /*return Column(
      children: [
        const SizedBox(height: 20),
        charts.TimeSeriesChart(_seriesList, animate: true),
        /*SizedBox(
          width: 900,
          height: 300,
          child: charts.BarChart(
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
            widget.seriesList ?? seriesList2,
            animate: widget.animate,
            // Set a bar label decorator.
            // Example configuring different styles for inside/outside:
            //       barRendererDecorator: new charts.BarLabelDecorator(
            //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
            //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
            barRendererDecorator: charts.BarLabelDecorator<String>(),
            domainAxis: const charts.OrdinalAxisSpec(),
          ),
        ),*/
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
