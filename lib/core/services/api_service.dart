import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:muni_app/core/config/app_config.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/professional_session.dart';
import 'package:muni_app/models/share_session.dart';
import 'package:muni_app/models/shared_assessment_view.dart';

/// Never log request bodies or responses from this class.
/// Tokens are always sent in bodies or headers, never in URLs.
class ApiService {
  ApiService({http.Client? client, String? baseUrl, Duration? timeout})
      : _client = client ?? http.Client(),
        _baseUrl = _stripTrailingSlash(baseUrl ?? AppConfig.apiBaseUrl),
        _timeout = timeout ?? AppConfig.requestTimeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _stripTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _authHeaders(String sessionToken) =>
      {..._jsonHeaders, 'Authorization': 'Bearer $sessionToken'};

  // ---- Citizen ----

  Future<AssessmentResponse> submitAssessment(AssessmentRequest request) async {
    final response = await _send(() => _client.post(
          _uri('/api/assessments/'),
          headers: _jsonHeaders,
          body: jsonEncode(request.toJson()),
        ));
    return _parse(response, AssessmentResponse.fromJson);
  }

  Future<ShareSession> createShare(
    AssessmentRequest request, {
    required int consentVersion,
  }) async {
    final response = await _send(() => _client.post(
          _uri('/api/shares/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            ...request.toJson(),
            'consent_version': consentVersion,
            'consent_given': true,
          }),
        ));
    return _parse(response, ShareSession.fromJson);
  }

  /// A 404 means already revoked or expired: treated as done.
  Future<void> revokeShare(String token) async {
    try {
      await _send(() => _client.post(
            _uri('/api/shares/revoke/'),
            headers: _jsonHeaders,
            body: jsonEncode({'token': token}),
          ));
    } on ServerException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
  }

  // ---- Professional ----

  Future<ProfessionalSession> professionalLogin({
    required String username,
    required String password,
  }) async {
    final response = await _send(() => _client.post(
          _uri('/api/professional/login/'),
          headers: _jsonHeaders,
          body: jsonEncode({'username': username, 'password': password}),
        ));
    return _parse(response, ProfessionalSession.fromJson);
  }

  Future<void> professionalLogout(String sessionToken) async {
    try {
      await _send(() => _client.post(
            _uri('/api/professional/logout/'),
            headers: _authHeaders(sessionToken),
          ));
    } on UnauthorizedException {
      // Already ended on the server.
    }
  }

  Future<void> changePassword(
    String sessionToken, {
    required String currentPassword,
    required String newPassword,
  }) async {
    await _send(() => _client.post(
          _uri('/api/professional/password/'),
          headers: _authHeaders(sessionToken),
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        ));
  }

  Future<SharedAssessmentView> openShare(
    String sessionToken,
    String shareToken,
  ) async {
    final response = await _send(() => _client.post(
          _uri('/api/professional/shares/open/'),
          headers: _authHeaders(sessionToken),
          body: jsonEncode({'token': shareToken}),
        ));
    return _parse(response, SharedAssessmentView.fromJson);
  }

  // ---- Internals ----

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
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
      // JSON 400 = DRF validation. Non-JSON 400 = usually DisallowedHost.
      if (isJson) throw ValidationException(_validationDetails(response));
      throw const ServerException(400);
    }
    if (response.statusCode == 401) throw const UnauthorizedException();
    if (response.statusCode == 403) throw const ForbiddenException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(response.statusCode);
    }
    return response;
  }

  static List<String> _validationDetails(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return const [];
      final messages = <String>[];
      void collect(Object? value) {
        if (value is String) {
          messages.add(value);
        } else if (value is List) {
          for (final item in value) {
            collect(item);
          }
        } else if (value is Map) {
          for (final item in value.values) {
            collect(item);
          }
        }
      }

      collect(decoded['errors'] ?? decoded['detail']);
      return messages;
    } on FormatException {
      return const [];
    }
  }

  T _parse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root is not an object.');
      }
      return fromJson(decoded);
    } on FormatException {
      throw const InvalidResponseException();
    }
  }

  void close() => _client.close();
}