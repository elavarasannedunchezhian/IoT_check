import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:offline_check/logger/level.dart';
import 'package:offline_check/logger/logger.dart';
import 'package:offline_check/logger/metric_appender.dart';

class Telemetry {
  static final DateFormat _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final Map<String, _SpanInfo> _spanTree = {};

  static Future<void> _sendMetric(String name, _SpanInfo spanInfo, {bool isStop = false, String? status}) async {
    try {
      final metricAppender = MetricApiAppender(
        server: '172.208.58.149:3100',
        username: 'admin',
        password: 'admin',
        labels: {
          'app': 'Checking',
          'Platform': Platform.operatingSystem,
          'level': '${Level.DEBUG}'
        },
      );

      final metricEntry = MetricEntry(
        type: 'event', 
        event: {
          'type': 'event',
          'event': name,
          'startTime': spanInfo.startTime,
          if (isStop)...{
            'stopTime': spanInfo.stopTime!,
            'duration': DateTime.parse(spanInfo.stopTime!).difference(DateTime.parse(spanInfo.startTime)).inMilliseconds,
            'status': status
          }
        },
        );

      await metricAppender.sendMetricEventsWithDio([metricEntry], CancelToken());
      log('Metrics sent Successfully');
    } catch (error, stackTrace) {
      log('Error sending logs to Loki: $error');
      log('StackTrace: $stackTrace');
      Logger.error('$error',stackTrace);
    }
  }

  static Future<void> startSpan(String spanName) async {
    if(_spanTree.containsKey(spanName)) {
      return log('Span $spanName is already started');
    }
    if (spanName.isNotEmpty) {
      final startTime = _dateFormat.format(DateTime.now().toUtc());
      final spanInfo = _SpanInfo(startTime: startTime);
      _spanTree[spanName] = spanInfo;
      await _sendMetric(spanName, spanInfo);
    } else {
      return log('SpanName cannot be empty');
    }
    
  }

  static Future<void> stopSpan(String spanName, String status) async {
    if(!_spanTree.containsKey(spanName)) {
      return log('Span $spanName is not started');
    }
    if (spanName.isNotEmpty) {
      final spanInfo = _spanTree[spanName];
      final stopTime = _dateFormat.format(DateTime.now().toUtc());
      spanInfo!.stopTime = stopTime;
      await _sendMetric(spanName, spanInfo, isStop: true, status: status);
      _spanTree.remove(spanName);
    } else {
      return log('spanName cannot be empty');
    }

  }
}

class _SpanInfo {
  String startTime;
  String? stopTime;

  _SpanInfo({required this.startTime});
}