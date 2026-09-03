import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/about_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'services/history_service.dart';
import 'theme.dart';

// Override at build time:
//   flutter run --dart-define=API_URL=http://192.168.x.x:8080
const _apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClinicalRagApp());
}

class ClinicalRagApp extends StatefulWidget {
  const ClinicalRagApp({super.key});

  @override
  State<ClinicalRagApp> createState() => _ClinicalRagAppState();
}

class _ClinicalRagAppState extends State<ClinicalRagApp> {
  final _client = const ApiClient(baseUrl: _apiBaseUrl);
  final _history = HistoryService();

  @override
  void initState() {
    super.initState();
    _history.load();
  }

  @override
  void dispose() {
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinical Evidence Search',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: AppShell(client: _client, history: _history),
    );
  }
}

/// Bottom-navigation shell. Each tab keeps its own state across switches.
class AppShell extends StatefulWidget {
  final ApiClient client;
  final HistoryService history;

  const AppShell({super.key, required this.client, required this.history});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(client: widget.client, history: widget.history),
      HistoryScreen(client: widget.client, history: widget.history),
      AboutScreen(client: widget.client),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.history,
        builder: (context, _) {
          final count = widget.history.entries.length;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: count == 0
                    ? const Icon(Icons.history_outlined)
                    : Badge.count(
                        count: count,
                        child: const Icon(Icons.history_outlined),
                      ),
                selectedIcon: const Icon(Icons.history),
                label: 'History',
              ),
              const NavigationDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: 'About',
              ),
            ],
          );
        },
      ),
    );
  }
}
