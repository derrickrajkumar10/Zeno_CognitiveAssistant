import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiNotificationBanner extends StatelessWidget {
  final String message;
  const MochiNotificationBanner({required this.message, super.key});

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerEntry(
        message: message,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _BannerEntry extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _BannerEntry({required this.message, required this.onDismiss});

  @override
  State<_BannerEntry> createState() => _BannerEntryState();
}

class _BannerEntryState extends State<_BannerEntry> {
  @override
  void initState() {
    super.initState();
    Future.delayed(3.seconds, widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
            ],
          ),
          child: Row(children: [
            const Text('🐾', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        )
            .animate()
            .slideY(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
            .fade(),
      ),
    );
  }
}
