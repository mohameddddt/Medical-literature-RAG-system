import 'package:flutter/material.dart';
import '../theme.dart';

/// Neutral placeholder for screens with nothing to show yet.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error presentation with a retry affordance.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off, size: 36, color: scheme.error),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton shown while a query is in flight. Pulsing blocks read as
/// "content is coming" more clearly than a bare spinner.
class LoadingSkeleton extends StatefulWidget {
  final String label;
  const LoadingSkeleton({super.key, this.label = 'Searching the literature…'});

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final opacity = 0.35 + (_controller.value * 0.35);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(scheme, opacity, widthFactor: 1.0),
                  _bar(scheme, opacity, widthFactor: 0.95),
                  _bar(scheme, opacity, widthFactor: 0.7),
                  const SizedBox(height: AppTheme.spacingLg),
                  _bar(scheme, opacity, widthFactor: 0.4, height: 14),
                  const SizedBox(height: AppTheme.spacingSm),
                  _card(scheme, opacity),
                  const SizedBox(height: AppTheme.spacingSm),
                  _card(scheme, opacity),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bar(
    ColorScheme scheme,
    double opacity, {
    required double widthFactor,
    double height = 12,
  }) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: opacity * 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _card(ColorScheme scheme, double opacity) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: opacity * 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Persistent, low-key reminder that this is not clinical advice.
class DisclaimerBar extends StatelessWidget {
  const DisclaimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 13, color: scheme.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Research and education only. Not medical advice.',
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
