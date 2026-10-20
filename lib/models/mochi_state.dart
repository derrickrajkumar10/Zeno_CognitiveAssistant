import 'package:flutter/material.dart';
import 'package:zeno/theme/app_theme.dart';

enum MochiMoodState { thriving, balanced, drifting, struggling }

extension MochiMoodStateX on MochiMoodState {
  static MochiMoodState fromScore(int score) {
    if (score >= 80) return MochiMoodState.thriving;
    if (score >= 55) return MochiMoodState.balanced;
    if (score >= 30) return MochiMoodState.drifting;
    return MochiMoodState.struggling;
  }

  String get label {
    switch (this) {
      case MochiMoodState.thriving:   return 'Thriving';
      case MochiMoodState.balanced:   return 'Balanced';
      case MochiMoodState.drifting:   return 'Drifting';
      case MochiMoodState.struggling: return 'Struggling';
    }
  }

  /// One full breath (in and out) of Mochi's idle loop: quick and bouncy
  /// when thriving, slow and heavy when struggling.
  Duration get breathPeriod {
    switch (this) {
      case MochiMoodState.thriving:   return const Duration(milliseconds: 1800);
      case MochiMoodState.balanced:   return const Duration(milliseconds: 2500);
      case MochiMoodState.drifting:   return const Duration(milliseconds: 3400);
      case MochiMoodState.struggling: return const Duration(milliseconds: 4500);
    }
  }

  Color get bodyColor {
    switch (this) {
      case MochiMoodState.thriving:   return AppTheme.mochiThriving;
      case MochiMoodState.balanced:   return AppTheme.mochiBalanced;
      case MochiMoodState.drifting:   return AppTheme.mochiDrifting;
      case MochiMoodState.struggling: return AppTheme.mochiStruggling;
    }
  }

  Color get glowColor {
    switch (this) {
      case MochiMoodState.thriving:   return AppTheme.mochiThriving.withValues(alpha: 0.4);
      case MochiMoodState.balanced:   return AppTheme.mochiBalanced.withValues(alpha: 0.3);
      case MochiMoodState.drifting:   return AppTheme.mochiDrifting.withValues(alpha: 0.15);
      case MochiMoodState.struggling: return AppTheme.mochiStruggling.withValues(alpha: 0.1);
    }
  }
}
