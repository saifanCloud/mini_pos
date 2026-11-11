import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Tombol utama standar aplikasi POS (tinggi minimal 52 dp, sudut membulat, support loading).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    } else {
      content = Text(label);
    }

    final button = FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: Size(width ?? double.infinity, height),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: content,
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

