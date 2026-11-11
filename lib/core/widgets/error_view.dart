import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Widget reusable untuk menampilkan status error disertai tombol "Coba Lagi".
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryButtonText;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryButtonText = 'Coba Lagi',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Terjadi Kendala',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 46),
                ),
                onPressed: onRetry,
                child: Text(retryButtonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

