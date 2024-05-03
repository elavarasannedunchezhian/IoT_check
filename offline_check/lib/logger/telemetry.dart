import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:offline_check/logger/metric_appender.dart';

class Telemetry {
  static final DateFormat _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static bool _isSpanStarted = false;
  static String _spanName = '';
  static String? _startTime;
  static String? _stopTime;

  static Future<void> _sendMetric(String name, {bool isStop = false}) async {
    try {
      final lokiAppender = MetricApiAppender(
        server: '172.208.58.149:3100',
        username: 'admin',
        password: 'admin',
        labels: {
          'app': 'Checking',
          'Platform': Platform.operatingSystem,
        },
      );

      final metricEntry = MetricEntry(
        type: 'event', 
        event: {
          'type': 'event',
          'event': name,
          'screen': 'screenchange',
          'startTime': '$_startTime',
          if (isStop)...{
            'stopTime': '$_stopTime',
            'duration': '${DateTime.parse(_stopTime!).difference(DateTime.parse(_startTime!)).inMilliseconds}',
            'status': 'success'
          }
        },
        );

      await lokiAppender.sendLogEventsWithDio([metricEntry], CancelToken());
      log('Logs sent Successfully');

      if(isStop) {
        _isSpanStarted = false;
        _spanName = '';
      }
    } catch (error, stackTrace) {
      log('Error sending logs to Loki: $error');
      log('StackTrace: $stackTrace');
    }
  }

  static Future<void> startSpan(String spanName) async {
    log('$_isSpanStarted');
    if(!_isSpanStarted) {
      _isSpanStarted = true;
      _spanName = spanName;
      _startTime = _dateFormat.format(DateTime.now());
      await _sendMetric(spanName);
    }
  }
  static Future<void> stopSpan(String spanName) async {
    log('$_isSpanStarted');
    if(_isSpanStarted && _spanName == spanName) {
      _stopTime = _dateFormat.format(DateTime.now());
      await _sendMetric(spanName, isStop: true);
    }
  }
}