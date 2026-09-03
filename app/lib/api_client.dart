import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/answer.dart';

class ApiClient {
  final String baseUrl;

  const ApiClient({required this.baseUrl});

  Future<Answer> query(String question) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/query'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
    return Answer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
