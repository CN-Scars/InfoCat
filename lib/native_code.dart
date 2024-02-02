import 'dart:collection';

import 'package:flutter/services.dart';

class NativeCode {
  static const platformChannel = MethodChannel('org.scars.info_cat');

  static Future<String> getGatewayMACAddress(String gatewayAddress) async {
    final String result = await platformChannel.invokeMethod(
        'getGatewayMACAddress', {'gatewayAddress': gatewayAddress});
    final processedResult = result.replaceAll(':', '').toUpperCase();
    return processedResult;
  }

  static Future<HashMap<Object?, Object?>> getFactoryConfig(
      String gatewayAddress) async {
    final HashMap<Object?, Object?> factoryConfig = HashMap.from(
        await platformChannel.invokeMethod(
            'getFactoryConfig', {'gatewayAddress': gatewayAddress}));

    return factoryConfig;
  }
}
