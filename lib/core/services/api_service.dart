import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:muni_app/core/config/app_config.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/assessment_response.dart';

/// Never log request bodies or responses from this class.
class ApiService {
  ApiService({http.Client? client, String? baseUrl, Duration? timeout})
      : _client = client ?? http.Client(),
        _baseUrl = _stripTrailingSlash(baseUrl ?? AppConfig.apiBaseUrl),
        _timeout = timeout ?? AppConfig.requestTimeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  static String _stripTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Future<AssessmentResponse> submitAssessment(AssessmentRequest request) async {
    final uri = Uri.parse('$_baseUrl/api/assessments/');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final bool isJson =
        (response.headers['content-type'] ?? '').contains('application/json');

    if (response.statusCode == 400) {
      // JSON 400 = DRF validation. Non-JSON 400 = usually Django
      // DisallowedHost (ALLOWED_HOSTS misconfiguration).
      if (isJson) throw const ValidationException();
      throw const ServerException(400);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(response.statusCode);
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root is not an object.');
      }
      return AssessmentResponse.fromJson(decoded);
    } on FormatException {
      throw const InvalidResponseException();
    }
  }

  void close() => _client.close();
}