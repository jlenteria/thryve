import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/thryve_card.dart';
import '../../../data/models/models.dart';

/// The pinned (or newest) Wall item, or a prompt to start the Wall.
class FeaturedWallCard extends StatelessWidget {
  const FeaturedWallCard({
    super.key,
    required this.item,
    required this.onOpenWall,
  });

  final WallItem? item;
  final VoidCallback onOpenWall;

  @override
  Widget build(BuildContext context) {
    final WallItem? item = this.item;
    if (item == null) {
      return CalloutCard(
        icon: Icons.photo_library_outlined,
        title: 'Your Wall is empty',
        message:
            'Add a photo of what you are working toward. '
            'It will appear here as a daily reminder.',
        onTap: onOpenWall,
      );
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String body = item.nextStep.isNotEmpty
        ? 'Next: ${item.nextStep}'
        : (item.note.isNotEmpty ? item.note : item.category);

    return ThryveCard(
      padding: EdgeInsets.zero,
      onTap: onOpenWall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppImage(
            source: item.image,
            semanticLabel: item.title,
            height: 180,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionLabel(
                  item.isPinned ? 'Pinned reminder' : 'From your Wall',
                  color: colors.primary,
                ),
                const SizedBox(height: 6),
                Text(item.title, style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text(
                      'Open My Wall',
                      style: text.titleMedium?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18, color: colors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
