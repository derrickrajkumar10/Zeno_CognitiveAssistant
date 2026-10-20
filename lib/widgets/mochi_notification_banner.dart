import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';

/// Glassmorphism notification banner that slides in from top with Mochi branding.
class MochiNotificationBanner extends StatefulWidget {
  const MochiNotificationBanner({super.key});

  @override
  State<MochiNotificationBanner> createState() =>
      MochiNotificationBannerState();
}

class MochiNotificationBannerState extends State<MochiNotificationBanner>
    with SingleTickerProviderStateMixin {
  String? _message;
  bool _visible = false;

  void show(String message) {
    setState(() {
      _message = message;
      _visible = true;
    });
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return AnimatedPositioned(
      duration: 400.ms,
      curve: Curves.easeOutCubic,
      top: _visible ? pad.top + AppTheme.sm : -100,
      left: AppTheme.md,
      right: AppTheme.md,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
              border: Border.all(color: AppTheme.surfaceBorder, width: 0.5),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets_rounded,
                      size: 16, color: AppTheme.primaryLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message ?? '',
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
