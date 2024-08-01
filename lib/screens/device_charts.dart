// EXCLUDE_FROM_GALLERY_DOCS_START
import 'dart:math';
// EXCLUDE_FROM_GALLERY_DOCS_END
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';

class DeviceCharts extends StatefulWidget {
  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  DeviceCharts(this.seriesList, {this.animate = false});

  /// Creates a [BarChart] with sample data and no transition.
  factory DeviceCharts.withSampleData() {
    return DeviceCharts(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  // EXCLUDE_FROM_GALLERY_DOCS_START
  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory DeviceCharts.withRandomData() {
    return DeviceCharts(_createRandomData());
  }

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
  // EXCLUDE_FROM_GALLERY_DOCS_END
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
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
            widget.seriesList,
            animate: widget.animate,
            // Set a bar label decorator.
            // Example configuring different styles for inside/outside:
            //       barRendererDecorator: new charts.BarLabelDecorator(
            //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
            //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
            barRendererDecorator: charts.BarLabelDecorator<String>(),
            domainAxis: const charts.OrdinalAxisSpec(),
          ),
        ),
      ],
    );
  }
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}
