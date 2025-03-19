import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EasState with ChangeNotifier {
  late BluetoothDevice device;

  bool _isBonded = false;

  bool get isBonded => _isBonded;

  void toggleIsBonded(bool value) {
    _isBonded = value;
    notifyListeners(); 
  }
}
