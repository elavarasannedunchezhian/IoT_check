import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import 'level.dart';
import 'loki_appender.dart';

class Logger {
  static Future<void> _sendLogEvent(String name, Level level) async {
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

      final logEntry = LogEntry(
        ts: DateTime.now(),
        line: name,
        lineLabels: {},
      );

      await lokiAppender.sendLogEventsWithDio([logEntry], CancelToken());
      log('Logs sent Successfully');
    } catch (error, stackTrace) {
      log('Error sending logs to Loki: $error');
      log('StackTrace: $stackTrace');
    }
  }

  static Future<void> info(String name) async => _sendLogEvent(name, Level.INFO);
  static Future<void> error(String name) async => _sendLogEvent(name, Level.ERROR);
  static Future<void> debug(String name) async => _sendLogEvent(name, Level.DEBUG);
  static Future<void> warning(String name) async => _sendLogEvent(name, Level.WARNING);
}