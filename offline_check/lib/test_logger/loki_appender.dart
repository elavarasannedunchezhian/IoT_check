import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'base_remote_appende.dart';
import 'dummy_logger.dart';

final _logger = DummyLogger('logging_appenders.loki_appender');

/// Appender used to push logs to [Loki](https://github.com/grafana/loki).
class LokiApiAppender extends BaseDioLogSender {
  LokiApiAppender({
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

  static final DateFormat _dateFormat =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

  late final Dio _client = Dio();

  static String _encodeLineLabelValue(String value) {
    if (value.contains(' ')) {
      return json.encode(value);
    }
    return value;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    _client.close();
  }

  @override
  Future<void> sendLogEventsWithDio(List<LogEntry> entries,
      Map<String, String> userProperties, CancelToken cancelToken) async {
    final jsonObject = LokiPushBody([LokiStream(labelsString, entries)]).toJson();
    final jsonBody = json.encode(jsonObject, toEncodable: _logEntryToJson);
    try {
      await _client.post<dynamic>('http://$server/api/prom/push',
        data: jsonBody,
        options: Options(
          headers: <String, String>{HttpHeaders.authorizationHeader: authHeader},
          contentType: ContentType.json.value,
        ),
      );
      print('log sent to loki successfully');
    } catch (e, stackTrace) {
      if(e is DioException) {
        final message = e.response != null ? 'response: ${e.response!.data}' : null;
        print('$message');
        throw Future.error(e, stackTrace);
      } else {
        throw Future.error(e, stackTrace);
      }
    }
  }

  dynamic _logEntryToJson(dynamic obj) {
    if (obj is LogEntry) {
      return {
          'ts': _dateFormat.format(obj.ts.toUtc()),
          'line': [
            obj.lineLabels.entries
                .map((entry) =>
                    '${entry.key}=${_encodeLineLabelValue(entry.value)}')
                .join(' '),
            obj.line,
          ].join(' - ')
        };
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
  final List<LogEntry> entries;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'labels': labels, 'entries': entries};
}