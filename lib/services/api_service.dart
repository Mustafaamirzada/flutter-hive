import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Endpoints of the backend running at `http://localhost:3000`.
class ApiRoutes {
  static const scores = '/scores';
  static const pdfs = '/pdfs';
  static const newCourses = '/new_courses';
}

class ApiException implements Exception {
  ApiException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ApiException: $message${cause == null ? '' : ' ($cause)'}';
}

class ApiService {
  ApiService({this.baseUrl = 'http://192.168.0.100:3000'});

  final String baseUrl;
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 5);

  Uri _uri(String route) => Uri.parse('$baseUrl$route');

  Future<List<Map<String, dynamic>>> _getJson(String route) async {
    late http.Response response;
    try {
      response = await _client
          .get(_uri(route), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
    } catch (e) {
      throw ApiException('Cannot reach $baseUrl$route', e);
    }
    if (response.statusCode != 200) {
      throw ApiException('$route responded ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final payload = _extractPayload(decoded);
    if (payload == null) throw ApiException('$route returned unexpected payload');
    return payload;
  }

  /// Accepts either a bare JSON array `[...]` or an object like
  /// `{"scores": [...]}`.
  static List<Map<String, dynamic>>? _extractPayload(Object? decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      for (final value in decoded.values) {
        if (value is List && value.isNotEmpty) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return null;
  }

  Future<List<Score>> fetchScores() async =>
      Score.fromJsonList(await _getJson(ApiRoutes.scores));

  Future<List<NewCourse>> fetchNewCourses() async =>
      NewCourse.fromJsonList(await _getJson(ApiRoutes.newCourses));

  Future<List<CoursePdf>> fetchPdfs() async =>
      CoursePdf.fromJsonList(await _getJson(ApiRoutes.pdfs));
}
