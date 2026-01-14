import 'package:flutter/services.dart';

class BleGattService {
  static const MethodChannel _channel =
      MethodChannel('ble_gatt_channel');

  static Future<void> startSOS() async {
    await _channel.invokeMethod('startSOS');
  }
}
