import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/query_screen.dart';

// Override at build time: flutter run --dart-define=API_URL=http://192.168.x.x:8080
const _apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  runApp(const ClinicalRagApp());
}

class ClinicalRagApp extends StatelessWidget {
  const ClinicalRagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinical Evidence RAG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: QueryScreen(client: ApiClient(baseUrl: _apiBaseUrl)),
    );
  }
}
