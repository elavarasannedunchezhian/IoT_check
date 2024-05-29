import 'dart:developer';
import 'dart:io';

import 'package:logging/logging.dart';
import '../test_logger/loki_appender.dart';

class Logger {
  static Future<void> _sendLogEvent(String name, Level level,{StackTrace? stackTrace, bool isError = false}) async {
    try {
      final lokiAppender = LokiApiAppender(
        server: '172.208.58.149:3100',
        username: 'admin',
        password: 'admin',
        labels: {
          'app': 'Checking',
          'Platform': Platform.operatingSystem,
          'level': '$level',
        },
      );

      await lokiAppender.log(level,DateTime.now(),name,{});
      log('Logs sent to loki_appender');
    } catch (error, stackTrace) {
      log('Error sending logs to batch: $error');
      log('StackTrace: $stackTrace');
    }
  }

  static Future<void> info(String name) async => _sendLogEvent(name, Level.INFO);
  static Future<void> error(String name, StackTrace stackTrace) async => _sendLogEvent('Error occurred: $name', Level.SEVERE, stackTrace: stackTrace, isError: true);
  static Future<void> debug(String name) async => _sendLogEvent(name, Level.CONFIG);
  static Future<void> warning(String name) async => _sendLogEvent(name, Level.WARNING);
}