import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Pushed screens fade and drift in from the right, while the screen
/// underneath eases a little to the left. Skipped when motion is reduced.
class ThryvePageTransitionsBuilder extends PageTransitionsBuilder {
  const ThryvePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }
    final Animatable<double> ease = CurveTween(curve: Curves.easeOutCubic);
    return SlideTransition(
      position: secondaryAnimation.drive(
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.05, 0),
        ).chain(ease),
      ),
      child: FadeTransition(
        opacity: animation.drive(ease),
        child: SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).chain(ease),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Our transition on Android and desktop; the native swipe-back transition
/// on Apple platforms.
const PageTransitionsTheme thryvePageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: ThryvePageTransitionsBuilder(),
    TargetPlatform.fuchsia: ThryvePageTransitionsBuilder(),
    TargetPlatform.linux: ThryvePageTransitionsBuilder(),
    TargetPlatform.windows: ThryvePageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);
