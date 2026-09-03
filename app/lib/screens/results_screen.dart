import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../api_client.dart';
import '../models/answer.dart';
import '../theme.dart';
import '../widgets/source_card.dart';
import '../widgets/state_views.dart';
import 'source_detail_screen.dart';

/// Runs a query and renders the grounded answer plus its sources.
///
/// When [cachedAnswer] is supplied (revisiting a history entry) no network
/// call is made.
class ResultsScreen extends StatefulWidget {
  final ApiClient client;
  final String question;
  final Answer? cachedAnswer;

  const ResultsScreen({
    super.key,
    required this.client,
    required this.question,
    this.cachedAnswer,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Answer? _answer;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cachedAnswer != null) {
      _answer = widget.cachedAnswer;
    } else {
      _run();
    }
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final answer = await widget.client.query(widget.question);
      if (!mounted) return;
      setState(() {
        _answer = answer;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unexpected error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Answer'),
          actions: [
            if (_answer != null)
              IconButton(
                tooltip: 'Copy answer',
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _answer!.answer));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Answer copied'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            const DisclaimerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingSkeleton();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _run);
    }

    final answer = _answer;
    if (answer == null) {
      return const EmptyState(
        icon: Icons.help_outline,
        title: 'No answer',
        message: 'Nothing was returned for this question.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        _QuestionCard(question: widget.question),
        const SizedBox(height: AppTheme.spacingLg),
        _AnswerBody(answer: answer),
        const SizedBox(height: AppTheme.spacingXl),
        _SourcesHeader(count: answer.sources.length),
        const SizedBox(height: AppTheme.spacingSm),
        ...answer.sources.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: SourceCard(
                  source: e.value,
                  index: e.key + 1,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SourceDetailScreen(
                        source: e.value,
                        index: e.key + 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.quiz_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: AppTheme.spacingSm + 2),
          Expanded(
            child: Text(
              question,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBody extends StatelessWidget {
  final Answer answer;
  const _AnswerBody({required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: answer.body,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        listBullet: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        strong: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          fontWeight: FontWeight.w700,
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SourcesHeader extends StatelessWidget {
  final int count;
  const _SourcesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.library_books_outlined, size: 17, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          'Sources',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
