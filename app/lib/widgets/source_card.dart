import 'package:flutter/material.dart';
import '../models/answer.dart';
import '../theme.dart';

/// Compact, tappable representation of one retrieved passage.
class SourceCard extends StatelessWidget {
  final Source source;
  final int index;
  final VoidCallback onTap;

  const SourceCard({
    super.key,
    required this.source,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matchColor = AppTheme.similarityColor(source.similarity, scheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CitationBadge(index: index),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'PubMed ${source.pubid}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: scheme.outline),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                source.snippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: source.similarity.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(matchColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    source.similarityPercent,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: matchColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CitationBadge extends StatelessWidget {
  final int index;
  const _CitationBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
