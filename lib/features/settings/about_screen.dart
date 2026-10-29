import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/thryve_card.dart';
import '../../core/widgets/thryve_page.dart';
import 'about_view_model.dart';

/// What Thryve is, the installed version and how data is kept.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AboutViewModel>(
      create: (BuildContext context) => AboutViewModel(),
      child: const _AboutView(),
    );
  }
}

class _AboutView extends StatelessWidget {
  const _AboutView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.text;
    final TextStyle? paragraph = text.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
      height: 1.6,
    );
    return ThryveDetailPage(
      title: 'About',
      children: <Widget>[
        ThryveCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionLabel('About', color: colors.primary),
              const SizedBox(height: 4),
              Text(AppConstants.appName, style: text.headlineSmall),
              const SizedBox(height: 4),
              Consumer<AboutViewModel>(
                builder:
                    (BuildContext context, AboutViewModel about, Widget? _) =>
                        Text(
                          'Version ${about.version}',
                          style: text.labelMedium?.copyWith(
                            color: colors.outline,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              Text(
                'Turn a meaningful dream into small daily actions. Track '
                'personal and financial goals, keep daily practices and a '
                'streak, pin inspiration to your Wall and reflect each week.',
                style: paragraph,
              ),
              const SizedBox(height: 16),
              Text(
                'No ads or accounts. Your goals, reflections and photos stay '
                'on your phone and are never uploaded by Thryve. The Privacy '
                'policy explains what leaves the device and when.',
                style: paragraph,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const CalloutCard(
          icon: Icons.shield_outlined,
          title: 'Zero data collection',
          message: 'Everything is stored locally on this device.',
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Thryve · Grow with intention', style: text.bodySmall),
        ),
      ],
    );
  }
}
