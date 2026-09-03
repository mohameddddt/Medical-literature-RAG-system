import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class AboutScreen extends StatefulWidget {
  final ApiClient client;
  const AboutScreen({super.key, required this.client});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool? _healthy;
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final ok = await widget.client.checkHealth();
    if (!mounted) return;
    setState(() {
      _healthy = ok;
      _checking = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          _ConnectionCard(
            baseUrl: widget.client.baseUrl,
            healthy: _healthy,
            checking: _checking,
            onRecheck: _check,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _Section(
            title: 'How it works',
            children: [
              _Step(
                number: 1,
                title: 'Your question is embedded',
                body: 'A MedCPT query encoder turns the question into a '
                    '768-dimension vector tuned for biomedical text.',
              ),
              _Step(
                number: 2,
                title: 'Similar passages are retrieved',
                body: 'That vector is matched against PubMed abstract passages '
                    'stored in Postgres with pgvector, ranked by cosine similarity.',
              ),
              _Step(
                number: 3,
                title: 'An answer is composed',
                body: 'A language model writes an answer using only the '
                    'retrieved passages, citing each claim by number.',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _Section(
            title: 'Limitations',
            children: [
              _Bullet(
                text: 'Answers are limited to what is in the indexed corpus. '
                    'If the evidence is not retrieved, the model will say so '
                    'rather than guess.',
              ),
              _Bullet(
                text: 'Retrieval quality varies. Always read the source '
                    'passages before relying on an answer.',
              ),
              _Bullet(
                text: 'Abstracts only. Full texts, figures and tables are not '
                    'indexed.',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: scheme.error),
                const SizedBox(width: AppTheme.spacingSm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not medical advice',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This tool is for research and education. It is not a '
                        'diagnostic device and must not be used to guide '
                        'patient care. Consult a qualified clinician.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Center(
            child: Text(
              'Clinical Evidence Search · v0.1.0',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final String baseUrl;
  final bool? healthy;
  final bool checking;
  final VoidCallback onRecheck;

  const _ConnectionCard({
    required this.baseUrl,
    required this.healthy,
    required this.checking,
    required this.onRecheck,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok = healthy == true;
    final color = checking
        ? scheme.outline
        : ok
            ? const Color(0xFF15803D)
            : scheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  checking
                      ? 'Checking connection…'
                      : ok
                          ? 'Connected'
                          : 'Not reachable',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, color: color),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Re-check',
                  icon: const Icon(Icons.refresh, size: 19),
                  onPressed: checking ? null : onRecheck,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            SelectableText(
              baseUrl,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (healthy == false) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Start the API and embedding service, then relaunch with '
                '--dart-define=API_URL=http://<your-computer-ip>:8080',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm + 2),
        ...children,
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 4,
              height: 4,
              decoration:
                  BoxDecoration(color: scheme.outline, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
