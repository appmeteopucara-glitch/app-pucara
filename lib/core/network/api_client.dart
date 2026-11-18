import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode, $message)';
}

class ApiClient {
  final String baseUrl;
  final http.Client client;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
  }) : client = client ?? http.Client(),
       defaultHeaders =
           defaultHeaders ??
           {'Content-Type': 'application/json', 'Accept': '*/*'},
       timeout = timeout ?? const Duration(seconds: 20);

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse(baseUrl).resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: queryParameters.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...defaultHeaders, if (headers != null) ...headers};
  }

  dynamic _handleResponse(http.Response response) {
    final code = response.statusCode;
    if (code < 200 || code >= 300) {
      throw ApiException(
        code,
        response.body.isEmpty ? 'Error $code' : response.body,
      );
    }
    if (response.body.isEmpty) return null;
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      return json.decode(response.body);
    }
    return response.body;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final res = await client
        .get(uri, headers: _mergeHeaders(headers))
        .timeout(timeout);
    return _handleResponse(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final res = await client
        .post(
          uri,
          headers: _mergeHeaders(headers),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
    return _handleResponse(res);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final res = await client
        .put(
          uri,
          headers: _mergeHeaders(headers),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
    return _handleResponse(res);
  }

  Future<dynamic> delete(
    String path, {
    String? id,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final fullPath = id == null || id.isEmpty ? path : '$path/$id';
    final uri = _buildUri(fullPath, queryParameters);
    final res = await client
        .delete(uri, headers: _mergeHeaders(headers))
        .timeout(timeout);
    return _handleResponse(res);
  }
}
