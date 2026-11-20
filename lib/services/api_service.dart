import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import 'auth_service.dart';

/// Error from the backend, with a message to show the user
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  static const _timeout = Duration(seconds: 60);

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> get(String path) async {
    try {
      final res = await http
          .get(_url(path), headers: await _headers())
          .timeout(_timeout);
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Please try again.');
    }
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http
          .post(_url(path), headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Please try again.');
    }
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http
          .put(_url(path), headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Please try again.');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await http
          .delete(_url(path), headers: await _headers())
          .timeout(_timeout);
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server. Please try again.');
    }
  }

  dynamic _handle(http.Response res) {
    final data = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    final message = (data is Map && data['error'] != null)
        ? data['error'] as String
        : 'Server error (${res.statusCode})';
    throw ApiException(message);
  }
}