import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/constants/app_constants.dart';
import 'core/motion/motion.dart';
import 'core/motion/shimmer.dart';
import 'core/state/app_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'features/goals/goals_view_model.dart';
import 'features/home/home_view_model.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_view_model.dart';
import 'features/shell/main_shell.dart';
import 'features/wall/wall_view_model.dart';

class ThryveApp extends StatelessWidget {
  const ThryveApp({super.key, this.store});

  /// Injectable for tests; production builds create and load their own.
  final AppStore? store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<ThemeManager>(create: (_) => ThemeManager()),
        // Shared persistence, then one view model per feature on top of it.
        ChangeNotifierProvider<AppStore>(
          create: (_) => store ?? (AppStore()..load()),
        ),
        // Refreshes day-based state when the app returns to the foreground
        // (e.g. the next morning). Eager, since nothing else reads it.
        Provider<AppLifecycleListener>(
          lazy: false,
          create: (BuildContext c) {
            final AppStore store = c.read<AppStore>();
            return AppLifecycleListener(
              onResume: () {
                if (store.isLoaded) {
                  store.refreshDay();
                }
              },
              // Most actions commit without awaiting the write, so leaving the
              // app settles the queue: a change still in flight would
              // otherwise be lost if the OS suspends or kills the process.
              onInactive: store.flush,
              onPause: store.flush,
            );
          },
          dispose: (_, AppLifecycleListener listener) => listener.dispose(),
        ),
        // A device asleep through midnight wakes into a new day without ever
        // reporting `resumed`, so the day also rolls over on a tick.
        Provider<Timer>(
          lazy: false,
          create: (BuildContext c) {
            final AppStore store = c.read<AppStore>();
            return Timer.periodic(const Duration(minutes: 1), (_) {
              if (store.isLoaded) {
                store.refreshDay();
              }
            });
          },
          dispose: (_, Timer timer) => timer.cancel(),
        ),
        ChangeNotifierProvider<GoalsViewModel>(
          create: (BuildContext c) => GoalsViewModel(c.read<AppStore>()),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (BuildContext c) => HomeViewModel(c.read<AppStore>()),
        ),
        ChangeNotifierProvider<WallViewModel>(
          create: (BuildContext c) => WallViewModel(c.read<AppStore>()),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (BuildContext c) => SettingsViewModel(c.read<AppStore>()),
        ),
      ],
      child: Consumer<ThemeManager>(
        builder: (BuildContext context, ThemeManager theme, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          builder: (BuildContext context, Widget? child) =>
              _SystemChrome(child: _SaveFailureBanner(child: child!)),
          home: const _AppGate(),
        ),
      ),
    );
  }
}

/// Shows onboarding or the main shell.
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final AppStore app = context.watch<AppStore>();
    if (app.loadFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "We couldn't open your saved data.",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: app.load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!app.isLoaded) {
      return const LoadingSkeleton();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: app.onboardingComplete
          ? const MainShell(key: ValueKey<String>('shell'))
          : const OnboardingScreen(key: ValueKey<String>('onboarding')),
    );
  }
}

/// Slides in over the top of the app when the last save failed, so the user
/// knows a change may not survive a restart. Retry writes the state again.
class _SaveFailureBanner extends StatelessWidget {
  const _SaveFailureBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool failed = context.select<AppStore, bool>(
      (AppStore store) => store.saveFailed,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        child,
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: IgnorePointer(
              ignoring: !failed,
              child: AnimatedSlide(
                duration: Motion.of(context, Motion.medium),
                curve: Motion.standard,
                offset: failed ? Offset.zero : const Offset(0, -1.5),
                child: AnimatedOpacity(
                  duration: Motion.of(context, Motion.medium),
                  opacity: failed ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: colors.errorContainer,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline,
                              color: colors.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your latest changes couldn't be saved.",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onErrorContainer),
                              ),
                            ),
                            TextButton(
                              onPressed: context.read<AppStore>().retrySave,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps status/navigation bar icons legible in both themes.
class _SystemChrome extends StatelessWidget {
  const _SystemChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = colors.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: colors.surfaceContainerLowest,
          ),
      child: child,
    );
  }
}
