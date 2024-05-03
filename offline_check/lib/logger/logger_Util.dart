import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:offline_check/logger/loki_appender.dart';

import 'level.dart';

class LoggerUtil {

  static Future<void> sendLogsToLoki(
    Level loglevel,
    String name, 
    String status,
    String line, 
    CancelToken cancelToken ) async {
        
    try {
      final baseURL = 'company_BaseURL';
      final storecode = 'CORESTORECODE';
      final tillcode = 'terminalCode';
      final user = 'loginUsername';
      final system = 'localHostname';

      if(baseURL.isNotEmpty && storecode.isNotEmpty && tillcode.isNotEmpty && 
                  user.isNotEmpty && system.isNotEmpty)
        {

        final lokiAppender = LokiApiAppender(
        server: '172.208.58.149:3100',
        username: 'admin',
        password: 'admin',
        labels: {
          'app': 'DGR POS',
          'os': Platform.operatingSystem, 
          'system_name': system,
          'base_url': baseURL,
          'store_code': storecode,
          'till_code': tillcode,
          'user': user,
          'level': '$loglevel',
            },
        );

        final logEntry = LogEntry(
          ts: DateTime.now(),
          line: '$line',
          lineLabels: {'$name': '$status'},
         );

      await lokiAppender.sendLogEventsWithDio([logEntry], cancelToken);
      log('Logs sent Successfully');
      }
    } catch (error, stackTrace) {
      log('Error sending logs to Loki: $error');
      log('StackTrace: $stackTrace');
    }
  }
}
