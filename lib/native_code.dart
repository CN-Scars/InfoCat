import 'package:flutter/services.dart';

class NativeCode {
  static const _channel = MethodChannel('GetGatewayMACAddress');

  static Future<String> getGatewayMACAddress(String gatewayAddress) async {
    final String result = await _channel.invokeMethod('getGatewayMACAddress', {'gatewayAddress': gatewayAddress});
    final processedResult = result.replaceAll(':', '').toUpperCase();
    return processedResult;
  }
}
