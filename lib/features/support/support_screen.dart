import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/widgets/thryve_card.dart';
import '../../core/widgets/thryve_page.dart';

/// Where users can support the project straight from their wallet.
class SupportDetails {
  const SupportDetails._();

  static const String qrAsset = 'docs/banks/bpi.jpg';
}

/// A no-drama way to chip in: scan, no accounts or tax forms.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.text;
    final Color muted = colors.onSurfaceVariant;
    return ThryveDetailPage(
      title: 'Support Thryve',
      children: <Widget>[
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border, color: colors.primary, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Thryve is free, with no ads and no accounts. Every feature is '
          'available to everyone. If you would like to, you can send an '
          'optional, voluntary tip directly to the developer. It unlocks '
          'nothing and gives no rewards.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 24),
        ThryveCard(
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(SupportDetails.qrAsset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan with any QR Ph app. This is a direct person-to-person '
                'transfer to the developer, not a purchase.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Never required. Thank you for using Thryve!',
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
