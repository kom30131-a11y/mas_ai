import 'dart:convert';

import 'package:http/http.dart' as http;

class AiClient {
  AiClient._();

  static final instance = AiClient._();

  static const _timeout =
      Duration(seconds: 60);

  static const gatewayUrl =
      String.fromEnvironment(
    'MAS_AI_AI_URL',
    defaultValue: '',
  );

  String get baseUrl => gatewayUrl;

  Future<String> send({
    required Map<String, dynamic> request,
  }) async {
    if (baseUrl.trim().isEmpty) {
      throw const AiClientException(
        'AI service URL is not configured.',
      );
    }

    final uri = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/ai',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type':
                  'application/json',
              'Accept':
                  'application/json',
            },
            body: jsonEncode(request),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw AiClientException(
          'AI service returned '
          '${response.statusCode}.',
        );
      }

      final data =
          jsonDecode(response.body);

      if (data is! Map ||
          data['result'] == null) {
        throw const AiClientException(
          'Invalid AI service response.',
        );
      }

      return data['result'].toString();
    } on AiClientException {
      rethrow;
    } on FormatException {
      throw const AiClientException(
        'Invalid response format from AI service.',
      );
    } catch (e) {
      throw AiClientException(
        'AI request failed: $e',
      );
    }
  }
}

class AiClientException
    implements Exception {
  final String message;

  const AiClientException(
    this.message,
  );

  @override
  String toString() => message;
}
