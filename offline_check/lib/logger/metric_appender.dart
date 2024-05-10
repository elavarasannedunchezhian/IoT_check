import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class MetricApiAppender {
  MetricApiAppender({
    required this.server,
    required this.username,
    required this.password,
    required this.labels,
  })  : labelsString = _createLabelsString(labels),
        authHeader = _createAuthHeader(username, password);

  final String server;
  final String username;
  final String password;
  final String authHeader;
  final Map<String, String> labels;
  final String labelsString;

  static String _createLabelsString(Map<String, String> labels) {
    return '{${labels.entries.map((entry) => '${entry.key}="${entry.value}"').join(',')}}';
  }

  static _createAuthHeader(String username, String password) {
    return 'Basic ${base64.encode(utf8.encode('$username:$password'))}';
  }

  static final DateFormat _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

  Dio? _clientInstance;

  Dio get _client => _clientInstance ??= Dio();

  dynamic _metricEntryToJson(dynamic obj) {
    if (obj is MetricEntry) {
        return {
          'ts': _dateFormat.format(DateTime.now().toUtc()),
          'line': '{${obj.event.entries.map((entry) { 
            final value = entry.value;
            final stringValue = value is String ? '"$value"' : value.toString();
            return '"${entry.key}": $stringValue';
            }).join(',')}}',
        };
      }
  }

  Future<void> sendMetricEventsWithDio(List<MetricEntry> entries, CancelToken cancelToken) async {
    final jsonObject = LokiPushBody([LokiStream(labelsString, entries)]).toJson();
    final jsonBody = json.encode(jsonObject, toEncodable: _metricEntryToJson);
    
    try {
      await _client.post<dynamic>('http://$server/api/prom/push',
        data: jsonBody,
        options: Options(
          headers: <String, String>{HttpHeaders.authorizationHeader: authHeader},
          contentType: ContentType.json.value,
        ),
      );
      log('Metrics sent to loki successfully');
    } catch (e, stackTrace) {
      if(e is DioException) {
        final message = e.response != null ? 'response: ${e.response!.data}' : null;
        log('$message');
        throw Future.error(e, stackTrace);
      } else {
        throw Future.error(e, stackTrace);
      }
    }
}
}

class LokiPushBody {
  LokiPushBody(this.streams);

  final List<LokiStream> streams;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'streams':
            streams.map((stream) => stream.toJson()).toList(growable: false),
      };
}

class LokiStream {
  LokiStream(this.labels, this.entries);

  final String labels;
  final List<MetricEntry> entries;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'labels': labels, 'entries': entries};
}

class MetricEntry {
  MetricEntry({
    required this.type,
    required this.event,
  });

  final String type;
  final Map<String, dynamic> event; 
}
