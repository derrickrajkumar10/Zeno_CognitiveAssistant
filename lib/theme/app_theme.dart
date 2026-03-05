import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Per-screen backgrounds (FLAT, no gradients) ─────────────────────────
  static const Color backgroundHome               = Color(0xFFF2F5EF);
  static const Color backgroundOnboardingWelcome   = Color(0xFFD6EAF8);
  static const Color backgroundOnboardingFeature   = Color(0xFFFFFFFF);
  static const Color backgroundOnboardingStats     = Color(0xFFD5F5E3);
  static const Color backgroundOnboardingPet       = Color(0xFFEAE6F0);
  static const Color backgroundOnboardingRating    = Color(0xFFFEF9E7);
  static const Color backgroundOnboardingReminders = Color(0xFFFEF0E8);
  static const Color backgroundScan                = Color(0xFFFFF8F0);
  static const Color backgroundInsights            = Color(0xFFEAF4FB);
  static const Color backgroundProfile             = Color(0xFFF4F0FF);

  // ── Accent colours ──────────────────────────────────────────────────────
  static const Color primaryButton     = Color(0xFF1A1A1A);
  static const Color selectedGreen     = Color(0xFF7AB87A);
  static const Color selectedGreenTint = Color(0xFFE8F5E8);
  static const Color textPrimary       = Color(0xFF1A1A1A);
  static const Color textSecondary     = Color(0xFF888888);

  // ── Legacy aliases (keep widgets compiling) ─────────────────────────────
  static const Color backgroundDeep   = backgroundHome;
  static const Color backgroundMid    = Color(0xFFEFF3EC);
  static const Color cardSurface      = Color(0xFFFAFCF8);
  static const Color cardSurfaceLight = Color(0xFFF4F7F2);
  static const Color primaryAccent    = selectedGreen;
  static const Color warmAccent       = Color(0xFFD4A574);
  static const Color successMint      = Color(0xFF5BBF8A);
  static const Color warningAmber     = Color(0xFFE8A84A);
  static const Color selectedTint     = selectedGreenTint;
  static const Color selectedBorder   = Color(0xFF5BBF8A);
  static const Color buttonDark       = primaryButton;

  // Mochi mood accent colours
  static const Color mochiBalanced   = Color(0xFF7AB87A);
  static const Color mochiThriving   = Color(0xFFD4A574);
  static const Color mochiDrifting   = Color(0xFF8BA89B);
  static const Color mochiStruggling = Color(0xFF7A8B84);

  // ── Ambient gradient per CogniPulse score ───────────────────────────────
  static List<Color> ambientGradient(int score) {
    if (score >= 80) {
      return [const Color(0xFFE8F0E8), const Color(0xFFEFF3EC), const Color(0xFFEAF2EA)];
    } else if (score >= 55) {
      return [const Color(0xFFEFF3EC), const Color(0xFFF2F5EF), const Color(0xFFEFF3EC)];
    } else if (score >= 30) {
      return [const Color(0xFFEDF0EC), const Color(0xFFF2F5EF), const Color(0xFFEDF0EE)];
    } else {
      return [const Color(0xFFF5EFE8), const Color(0xFFF2F5EF), const Color(0xFFF0EDE8)];
    }
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: backgroundHome,
      colorScheme: const ColorScheme.light(
        surface: cardSurface,
        primary: selectedGreen,
        secondary: warmAccent,
        onSurface: textPrimary,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shadowColor: const Color(0x0F000000),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: selectedGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: selectedGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSurface,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
