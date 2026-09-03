import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models/search_entry.dart';
import '../services/history_service.dart';
import '../theme.dart';
import '../widgets/state_views.dart';
import 'results_screen.dart';

class HistoryScreen extends StatelessWidget {
  final ApiClient client;
  final HistoryService history;

  const HistoryScreen({
    super.key,
    required this.client,
    required this.history,
  });

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(ts);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes every saved search from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await history.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          ListenableBuilder(
            listenable: history,
            builder: (context, _) => history.entries.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear history',
                    icon: const Icon(Icons.delete_outline, size: 22),
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          final entries = history.entries;
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No searches yet',
              message:
                  'Questions you ask will be saved here so you can revisit '
                  'the answers and their sources.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (context, i) => _HistoryTile(
              entry: entries[i],
              subtitle: _formatTimestamp(entries[i].timestamp),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultsScreen(
                    client: client,
                    question: entries[i].question,
                    cachedAnswer: entries[i].answer,
                  ),
                ),
              ),
              onDelete: () => history.remove(entries[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SearchEntry entry;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('${entry.question}-${entry.timestamp.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  entry.answer.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm + 2),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: scheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: scheme.outline),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Icon(Icons.library_books_outlined,
                        size: 13, color: scheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.answer.sources.length} sources',
                      style: TextStyle(fontSize: 11.5, color: scheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
