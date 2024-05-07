import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class MetricApiAppender {
  MetricApiAppender({
    required this.server,
    required this.username,
    required this.password,
    required this.labels,
  })  : labelsString =
            '{${labels.entries.map((entry) => '${entry.key}="${entry.value}"').join(',')}}',
        authHeader = 'Basic ${base64.encode(utf8.encode([
          username,
          password
        ].join(':')))}';

  final String server;
  final String username;
  final String password;
  final String authHeader;
  final Map<String, String> labels;
  final String labelsString;

  static final DateFormat _dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

  Dio? _clientInstance;

  Dio get _client => _clientInstance ??= Dio();

  Future<void> sendMetricEventsWithDio(List<MetricEntry> entries, CancelToken cancelToken) {
    final jsonObject = LokiPushBody([LokiStream(labelsString, entries)]).toJson();
    final jsonBody = json.encode(jsonObject, toEncodable: (dynamic obj) {
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
      return obj.toJson();
    });
    return _client
        .post<dynamic>(
          'http://$server/api/prom/push',
          cancelToken: cancelToken,
          data: jsonBody,
          options: Options(
            headers: <String, String>{
              HttpHeaders.authorizationHeader: authHeader,
            },
            contentType: ContentType(
                    ContentType.json.primaryType, ContentType.json.subType)
                .value,
          ),
        )
        .then(
          (response) => Future<void>.value(null),
      // _logger.finest('sent logs.');
        )
        .catchError((Object err, StackTrace stackTrace) {
      // ignore: unused_local_variable
      String? message;
      if (err is DioException) {
        if (err.response != null) {
          message = 'response:${err.response!.data}';
        }
      }
      return Future<void>.error(err, stackTrace);
    });
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
