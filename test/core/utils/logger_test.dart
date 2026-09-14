import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mine_flow/core/utils/logger.dart';

void main() {
  test('redacts sensitive headers from log output', () async {
    String capturedOutput = '';
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        capturedOutput += message;
      }
    };

    try {
      configureLogging();
      final logger = buildLogger('TestLogger');

      const logMessage =
          'Request failed with Authorization: Bearer abcdef12345';
      logger.warning(logMessage);

      await Future.delayed(Duration.zero);

      expect(capturedOutput.contains('abcdef12345'), isFalse);
      expect(
        capturedOutput.contains('Authorization: Bearer <redacted>'),
        isTrue,
      );

      capturedOutput = '';
      logger.warning('Error', 'Headers: apiKey=my_secret_key');
      await Future.delayed(Duration.zero);

      expect(capturedOutput.contains('my_secret_key'), isFalse);
      expect(capturedOutput.contains('apiKey=<redacted>'), isTrue);
    } finally {
      debugPrint = originalDebugPrint;
      Logger.root.clearListeners();
    }
  });
}
