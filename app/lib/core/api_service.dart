import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final _box = GetStorage();
  String? get token => _box.read('token');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _u(String p) => Uri.parse('${AppConst.baseUrl}$p');

  Future<Map<String, dynamic>> _run(
      Future<http.Response> Function() call) async {
    try {
      final r = await call()
          .timeout(const Duration(seconds: 40)); // Render cold start
      final body = r.body.isNotEmpty
          ? jsonDecode(r.body) as Map<String, dynamic>
          : <String, dynamic>{};
      if (r.statusCode >= 200 && r.statusCode < 300) return body;
      if (r.statusCode == 401) _box.remove('token');
      throw ApiException(body['message']?.toString() ?? 'Something went wrong');
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Server timed out, try again');
    }
  }

  Future<Map<String, dynamic>> get(String p) =>
      _run(() => http.get(_u(p), headers: _headers));
  Future<Map<String, dynamic>> post(String p, Map body) =>
      _run(() => http.post(_u(p), headers: _headers, body: jsonEncode(body)));
  Future<Map<String, dynamic>> put(String p, Map body) =>
      _run(() => http.put(_u(p), headers: _headers, body: jsonEncode(body)));
}
