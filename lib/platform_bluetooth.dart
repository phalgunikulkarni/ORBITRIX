import 'package:flutter/services.dart';

class PlatformBluetooth {
  static const MethodChannel _channel = MethodChannel('orbitrx/bluetooth');

  /// Requests the system Bluetooth enable prompt. Returns true when the
  /// user enabled Bluetooth, false otherwise.
  static Future<bool> requestEnableBluetooth() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestEnableBluetooth');
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}
