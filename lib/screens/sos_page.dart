import 'package:flutter/services.dart';

class EmergencyBleService {
  static const _channel = MethodChannel('emergency_ble');

  static Future<void> sendEmergency() async {
    await _channel.invokeMethod('startEmergency');
  }
}
