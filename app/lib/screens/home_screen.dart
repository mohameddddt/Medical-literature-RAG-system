import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models/answer.dart';
import '../models/search_entry.dart';
import '../services/history_service.dart';
import '../theme.dart';
import '../widgets/state_views.dart';
import 'results_screen.dart';

const _exampleQuestions = [
  'Does aspirin reduce the risk of recurrent stroke?',
  'Are statins effective for primary prevention?',
  'Does metformin improve cardiovascular outcomes?',
  'Is screening colonoscopy associated with reduced mortality?',
];

class HomeScreen extends StatefulWidget {
  final ApiClient client;
  final HistoryService history;

  const HomeScreen({super.key, required this.client, required this.history});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty || _submitting) return;

    _focusNode.unfocus();
    setState(() => _submitting = true);

    final result = await Navigator.of(context).push<Answer>(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          client: widget.client,
          question: question,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      await widget.history.add(
        SearchEntry(
          question: question,
          timestamp: DateTime.now(),
          answer: result,
        ),
      );
      if (mounted) _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  const SizedBox(height: AppTheme.spacingSm),
                  _Header(scheme: scheme),
                  const SizedBox(height: AppTheme.spacingXl),
                  _SearchField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !_submitting,
                    onSubmit: _search,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : () => _search(),
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('Search the evidence'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  const _SectionLabel(
                    icon: Icons.lightbulb_outline,
                    text: 'Try an example',
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ..._exampleQuestions.map(
                    (q) => _ExampleTile(
                      question: q,
                      onTap: _submitting ? null : () => _search(q),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _RecentSection(
                    history: widget.history,
                    onTap: (entry) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResultsScreen(
                          client: widget.client,
                          question: entry.question,
                          cachedAnswer: entry.answer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const DisclaimerBar(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme scheme;
  const _Header({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.biotech_outlined,
            color: scheme.onPrimaryContainer,
            size: 26,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Clinical Evidence',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Ask a question and get an answer grounded in retrieved PubMed '
          'abstracts, with every claim cited.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String?> onSubmit;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(null),
      style: const TextStyle(fontSize: 16, height: 1.4),
      decoration: InputDecoration(
        hintText: 'e.g. Does early mobilisation improve ICU outcomes?',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 4, right: 4),
          child: Icon(Icons.search, size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: controller.clear,
                  tooltip: 'Clear',
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      ],
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final String question;
  final VoidCallback? onTap;

  const _ExampleTile({required this.question, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.north_east,
                  size: 15,
                  color: scheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppTheme.spacingSm + 2),
                Expanded(
                  child: Text(
                    question,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  final HistoryService history;
  final ValueChanged<SearchEntry> onTap;

  const _RecentSection({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final recent = history.entries.take(3).toList();
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(icon: Icons.history, text: 'Recent'),
            const SizedBox(height: AppTheme.spacingSm),
            ...recent.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onTap(entry),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
