import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../motion/entrance.dart';

/// The app icon, as shown in the tab header.
class ThryveLogo extends StatelessWidget {
  const ThryveLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final int cacheSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Image.asset(
      'assets/icons/thryve_icon.png',
      width: size,
      height: size,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      excludeFromSemantics: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          Icon(
            Icons.eco,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

/// Scaffold for the bottom-nav tabs: pinned brand header + padded content.
class ThryveTabPage extends StatelessWidget {
  const ThryveTabPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ThryveLogo(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppConstants.appName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              // Cards settle in one after another the first time a tab opens.
              // The wrapper key tracks the card rather than its slot, so adding
              // a card above doesn't replay or skip the ones below. A GlobalKey
              // can't be reused here: the child still owns it, and one key on
              // two widgets is a hard framework error.
              children: <Widget>[
                for (final (int index, Widget child) in children.indexed)
                  Entrance(
                    key: child.key is GlobalKey ? null : child.key,
                    delay: Entrance.stagger(index),
                    child: child,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scaffold for pushed detail pages with a back button.
class ThryveDetailPage extends StatelessWidget {
  const ThryveDetailPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: children,
        ),
      ),
    );
  }
}
