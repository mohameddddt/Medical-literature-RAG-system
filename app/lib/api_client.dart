import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'models/answer.dart';

/// Error carrying a message already phrased for display to the user.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  const ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 45),
  });

  Future<Answer> query(String question) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/query'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question}),
          )
          .timeout(timeout);

      if (res.statusCode == 200) {
        return Answer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      if (res.statusCode == 400) {
        throw const ApiException(
          'That question could not be processed. Try rephrasing it.',
        );
      }
      throw ApiException(
        'The server returned an error (${res.statusCode}). '
        'Check that the API and embedding service are both running.',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. The model may be under heavy load — try again.',
      );
    } on SocketException {
      throw ApiException(
        'Could not reach the server at $baseUrl.\n\n'
        'On a physical device, make sure the phone and computer are on the '
        'same Wi-Fi network and that the app was launched with '
        '--dart-define=API_URL pointing at the computer\'s local IP address.',
      );
    } on FormatException {
      throw const ApiException('The server sent a response the app could not read.');
    }
  }

  /// Lightweight reachability probe used by the connection banner.
  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
