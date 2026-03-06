import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zeno/theme/app_theme.dart';

/// A reusable frosted-glass card with configurable blur, tint, and border.
///
/// Uses [BackdropFilter] for the glassmorphism effect. Wraps any child
/// content with frosted translucency and a subtle border highlight.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? tint;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = AppTheme.glassBlur,
    this.tint,
    this.borderRadius = AppTheme.cardRadius,
    this.padding,
    this.margin,
    this.borderWidth = AppTheme.glassBorderWidth,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tint ?? AppTheme.surfaceGlass;
    final effectiveBorder = borderColor ?? AppTheme.surfaceBorder;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveTint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorder,
              width: borderWidth,
            ),
          ),
          padding: padding ?? const EdgeInsets.all(AppTheme.md),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}

/// A compact glass card variant for small inline elements (chips, tags, badges).
class GlassChip extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassChip({
    super.key,
    required this.child,
    this.padding,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: AppTheme.glassBlurLight,
      borderRadius: AppTheme.cardRadiusSm,
      tint: tint ?? AppTheme.surfaceGlassLite,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onTap,
      child: child,
    );
  }
}
