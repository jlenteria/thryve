import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../goals/goals_hub_screen.dart';
import '../home/home_screen.dart';
import '../review/weekly_review_screen.dart';
import '../settings/settings_screen.dart';
import '../wall/my_wall_screen.dart';
import 'main_shell_view_model.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(ShellTab.home, 'Home', Icons.home_outlined, Icons.home_rounded),
    _TabSpec(
      ShellTab.goals,
      'Goals',
      Icons.track_changes_outlined,
      Icons.track_changes_rounded,
    ),
    _TabSpec(
      ShellTab.wall,
      'Wall',
      Icons.grid_view_outlined,
      Icons.grid_view_rounded,
    ),
    _TabSpec(
      ShellTab.review,
      'Review',
      Icons.auto_stories_outlined,
      Icons.auto_stories_rounded,
    ),
    _TabSpec(
      ShellTab.settings,
      'Settings',
      Icons.settings_outlined,
      Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainShellViewModel>(
      create: (_) => MainShellViewModel(),
      child: Consumer<MainShellViewModel>(
        builder: (BuildContext context, MainShellViewModel shell, _) {
          final ColorScheme colors = Theme.of(context).colorScheme;
          return Scaffold(
            body: IndexedStack(
              index: shell.tab.index,
              // IndexedStack keeps every tab mounted, so a looping animation on
              // a hidden tab would run frames forever. TickerMode stops them.
              children: <Widget>[
                for (final (int index, Widget tab) in const <Widget>[
                  HomeScreen(),
                  GoalsHubScreen(),
                  MyWallScreen(),
                  WeeklyReviewScreen(),
                  SettingsScreen(),
                ].indexed)
                  TickerMode(enabled: index == shell.tab.index, child: tab),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.tab.index,
              onDestinationSelected: (int index) =>
                  shell.select(ShellTab.values[index]),
              backgroundColor: colors.surfaceContainerLowest,
              indicatorColor: colors.primary.withValues(alpha: 0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: <Widget>[
                for (final _TabSpec tab in _tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon, color: colors.primary),
                    label: tab.label,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.tab, this.label, this.icon, this.selectedIcon);

  final ShellTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
