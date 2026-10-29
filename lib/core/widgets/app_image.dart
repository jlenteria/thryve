import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../motion/shimmer.dart';
import '../services/image_store.dart';

/// Renders any image reference Thryve stores: a `local:` file, a legacy
/// `data:` URI, or a remote URL. Shows a neutral placeholder on failure.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Announced by screen readers. When null the image is decorative.
  final String? semanticLabel;

  /// Decodes at (about) display size instead of the stored 1600px, which
  /// keeps lists of large photos from exhausting memory.
  static ImageProvider<Object> _downscaled(
    BuildContext context,
    ImageProvider<Object> provider, {
    double? width,
    double? height,
  }) {
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    int? pixels(double? logical) =>
        logical != null && logical.isFinite ? (logical * ratio).ceil() : null;
    final int? cacheWidth = pixels(width);
    final int? cacheHeight = pixels(height);
    if (cacheWidth == null && cacheHeight == null) {
      return provider;
    }
    return ResizeImage(
      provider,
      width: cacheWidth,
      height: cacheHeight,
      policy: ResizeImagePolicy.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget placeholder = Container(
      width: width,
      height: height,
      color: colors.surfaceContainer,
      child: Icon(Icons.image_outlined, color: colors.outline),
    );
    final ImageProvider<Object>? provider = ImageStore.provider(source);
    Widget image = provider == null
        ? placeholder
        : Container(
            width: width,
            height: height,
            color: colors.surfaceContainer,
            child: Image(
              image: _downscaled(
                context,
                provider,
                width: width,
                height: height,
              ),
              width: width,
              height: height,
              fit: fit,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => placeholder,
              // Fade the picture in once it has decoded instead of popping.
              frameBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    int? frame,
                    bool wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: Motion.of(context, Motion.medium),
                      curve: Motion.standard,
                      child: child,
                    );
                  },
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? progress,
                  ) {
                    if (progress == null) {
                      return child;
                    }
                    return SkeletonBox(width: width, height: height, radius: 0);
                  },
            ),
          );
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.source, this.radius = 16});

  final String? source;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ImageProvider<Object>? full = ImageStore.provider(source);
    final ImageProvider<Object>? image = full == null
        ? null
        : AppImage._downscaled(
            context,
            full,
            width: radius * 2,
            height: radius * 2,
          );
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary.withValues(alpha: 0.1),
      backgroundImage: image,
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Icon(
              Icons.person_outline,
              size: radius * 1.2,
              color: colors.primary,
            )
          : null,
    );
  }
}
