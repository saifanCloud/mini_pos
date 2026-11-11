import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../utils/rupiah_formatter.dart';

enum PriceSize { small, medium, large }

/// Widget penampil teks harga terformat Rupiah secara konsisten.
class PriceText extends StatelessWidget {
  final int amount;
  final PriceSize size;
  final Color? color;
  final bool isBold;

  const PriceText(
    this.amount, {
    super.key,
    this.size = PriceSize.medium,
    this.color,
    this.isBold = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetColor = color ?? theme.colorScheme.primary;

    TextStyle baseStyle;
    switch (size) {
      case PriceSize.large:
        baseStyle = AppTextStyles.priceLarge;
        break;
      case PriceSize.medium:
        baseStyle = AppTextStyles.priceMedium;
        break;
      case PriceSize.small:
        baseStyle = AppTextStyles.priceSmall;
        break;
    }

    final finalStyle = baseStyle.copyWith(
      color: targetColor,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
    );

    return Text(
      RupiahFormatter.format(amount),
      style: finalStyle,
    );
  }
}

