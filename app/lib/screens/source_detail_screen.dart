import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/answer.dart';
import '../theme.dart';

/// Full text of a single retrieved passage, with a link out to PubMed.
class SourceDetailScreen extends StatelessWidget {
  final Source source;
  final int index;

  const SourceDetailScreen({
    super.key,
    required this.source,
    required this.index,
  });

  Future<void> _openPubMed(BuildContext context) async {
    final uri = Uri.parse(source.pubmedUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the browser'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matchColor = AppTheme.similarityColor(source.similarity, scheme);

    return Scaffold(
      appBar: AppBar(title: Text('Source $index')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        'PubMed ${source.pubid}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: matchColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          AppTheme.similarityLabel(source.similarity),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: matchColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        '${source.similarityPercent} similarity',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: source.similarity.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(matchColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'PASSAGE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SelectableText(
            source.snippet,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(height: 1.65, color: scheme.onSurface),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'This is the excerpt the model was given. Open the full record on '
            'PubMed for the complete abstract.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          FilledButton.icon(
            onPressed: () => _openPubMed(context),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View on PubMed'),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: source.snippet));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passage copied'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy passage'),
          ),
        ],
      ),
    );
  }
}
