import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/widgets/thryve_card.dart';
import '../../core/widgets/thryve_page.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String url =
      'https://jlenteria.onrender.com/thryve-privacy.html';
  static const String contact = 'jlenteria98@gmail.com';
  static const List<(String, String)> sections = <(String, String)>[
    (
      'About this policy',
      'Thryve (com.bling.thryve) is developed by Bling. Updated October 27, '
          '2026. Privacy contact: $contact.',
    ),
    (
      'Your goals and local data',
      'Your name, big dream, anchor, profile photo, goals, milestones, '
          'logged earnings, daily practices, Wall items, weekly reviews, '
          'activity history, reminder time and appearance choice are stored '
          'in the app’s private storage on your device. Thryve has no '
          'accounts, ads, developer-run server or analytics service. Android '
          'cloud backup is disabled for this data.',
    ),
    (
      'Photos',
      'Photo-library access is used only when you choose a profile photo, '
          'anchor image or Wall image. The picked photo is resized and copied '
          'into the app’s private folder. Photos are never uploaded by '
          'Thryve, and replaced or removed photos are deleted from that '
          'folder.',
    ),
    (
      'Image links',
      'If you add a Wall image by pasting a web link, Thryve downloads that '
          'image directly from the website you linked. That website can see '
          'standard request details such as your IP address and handles them '
          'under its own policy. Thryve sends nothing else with the request.',
    ),
    (
      'Notifications',
      'The optional daily reminder is scheduled on your device and may '
          'include your name and anchor, which can appear on your lock '
          'screen depending on your system settings. No notification '
          'content passes through a server.',
    ),
    (
      'Support',
      'Optional support payments take place through your chosen wallet or '
          'bank app. Thryve does not receive payment credentials or grant '
          'features for contributions.',
    ),
    (
      'Retention and deletion',
      'Your data remains until you change or delete it. Activity history '
          'older than 400 days is removed automatically. Reset all local data '
          'in Settings, clearing app storage, or uninstalling Thryve deletes '
          'all app records and stored photos. Payment records remain with '
          'their recipients.',
    ),
    (
      'Your choices and contact',
      'You may revoke photo or notification permissions in system settings, '
          'turn off the daily reminder, delete any goal or Wall item, and '
          'choose whether to contribute. Revoking permissions may prevent '
          'picking photos or receiving reminders. Thryve has no online '
          'account to delete. For privacy questions, contact $contact. '
          'Material changes will be reflected in the policy available in '
          'Settings and on the public policy page.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme text = context.text;
    return ThryveDetailPage(
      title: 'Privacy policy',
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: colors.primary.withValues(alpha: 0.07),
            shape: StadiumBorder(
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.link, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(child: SelectableText(url, style: text.labelMedium)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (String title, String body) in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ThryveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(
                    body,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
