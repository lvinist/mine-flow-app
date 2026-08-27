import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forces the app into an offline or online state.
/// This intercepts the MethodChannel used by connectivity_plus.
void forceOffline(bool offline) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return offline ? ['none'] : ['wifi'];
        }
        return null;
      });
}
