import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class LokiApiAppender {
  LokiApiAppender({
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

  static String _encodeLineLabelValue(String value) {
    if (value.contains(' ')) {
      return json.encode(value);
    }
    return value;
  }
  
  static List<dynamic> batch = []; 
  static int batchSize = 3;
  Future<void> sendLogEvents(List<LogEntry> entries, CancelToken cancelToken) async {
    final jsonObject = LokiPushBody([LokiStream(labelsString, entries)]).toJson();
    final jsonBody = json.encode(jsonObject, toEncodable: _logEntryToJson);
    log('batchSize before = ${batch.length}');
    batch.add(jsonBody);
    log('$batch');
    if(batch.length >= batchSize) {
      log('batchSize after = ${batch.length}');
      for(final log in batch) {
        sendBatchesToLoki(log, CancelToken());
      }
      batch.clear();
      log('Batch size after sending to loki = ${batch.length}');
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

  Future<void> sendBatchesToLoki(String jsonBody, CancelToken cancelToken) async {
      try {
      await _client.post<dynamic>('http://$server/api/prom/push',
        data: jsonBody,
        options: Options(
          headers: <String, String>{HttpHeaders.authorizationHeader: authHeader},
          contentType: ContentType.json.value,
        ),
      );
      log('Batch of logs sent to loki successfully');
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
  final List<LogEntry> entries;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'labels': labels, 'entries': entries};
}

class LogEntry {
  LogEntry({
    required this.ts,
    required this.line,
    required this.lineLabels,
  });

  static final DateFormat _dateFormat =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  final DateTime ts;
  final String line;
  final Map<String, dynamic> lineLabels;

  String get tsFormatted => _dateFormat.format(ts.toUtc());
}
