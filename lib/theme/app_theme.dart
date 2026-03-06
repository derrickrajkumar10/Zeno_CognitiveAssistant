import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOUR PALETTE — Nature-inspired, premium-refined
  // ═══════════════════════════════════════════════════════════════════════════

  // Backgrounds — warm, layered sage tones
  static const Color bg = Color(0xFFF5F3EE); // warm ivory
  static const Color bgSecondary = Color(0xFFECEAE3); // slightly deeper
  static const Color bgElevated = Color(0xFFFAF9F6); // card/sheet background

  // Per-screen backgrounds (subtle tint variants)
  static const Color bgHome = Color(0xFFF3F1EB);
  static const Color bgScan = Color(0xFFF8F4EE);
  static const Color bgInsights = Color(0xFFEEF2F6);
  static const Color bgProfile = Color(0xFFF2F0F6);
  static const Color bgQuests = Color(0xFFF0F4EE);
  static const Color bgOnboarding = Color(0xFFF5F3EE);

  // Surfaces — glassmorphism layers
  static const Color surfaceGlass = Color(0xCCFFFFFF); // 80% white
  static const Color surfaceGlassLite = Color(0x99FFFFFF); // 60% white
  static const Color surfaceGlassDim = Color(0x66FFFFFF); // 40% white
  static const Color surfaceCard = Color(0xFFFAF9F6);
  static const Color surfaceBorder = Color(0x1A000000); // 10% black

  // Primary — deep sage green
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primarySoft = Color(0xFFD8F3DC);
  static const Color primaryMuted = Color(0xFFB7E4C7);

  // Accent — warm peach/terracotta
  static const Color accent = Color(0xFFD4A574);
  static const Color accentSoft = Color(0xFFFAE5D3);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFA0A0A0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFE8A84A);
  static const Color error = Color(0xFFE76F51);
  static const Color info = Color(0xFF6CAED6);

  // Mochi mood colours
  static const Color mochiThriving = Color(0xFFD4A574);
  static const Color mochiBalanced = Color(0xFF7AB87A);
  static const Color mochiDrifting = Color(0xFF8BA89B);
  static const Color mochiStruggling = Color(0xFF7A8B84);

  // ── Legacy aliases (keep old widgets compiling) ────────────────────────
  static const Color backgroundHome = bgHome;
  static const Color backgroundDeep = bg;
  static const Color backgroundMid = bgSecondary;
  static const Color backgroundInsights = bgInsights;
  static const Color backgroundProfile = bgProfile;
  static const Color backgroundScan = bgScan;
  static const Color backgroundOnboardingWelcome = bgOnboarding;
  static const Color backgroundOnboardingFeature = bgOnboarding;
  static const Color backgroundOnboardingPet = bgOnboarding;
  static const Color backgroundOnboardingReminders = bgOnboarding;
  static const Color backgroundOnboardingStats = bgOnboarding;
  static const Color backgroundOnboardingRating = bgOnboarding;
  static const Color cardSurface = surfaceCard;
  static const Color cardSurfaceLight = bgElevated;
  static const Color primaryAccent = primary;
  static const Color warmAccent = accent;
  static const Color successMint = success;
  static const Color warningAmber = warning;
  static const Color selectedGreen = primaryLight;
  static const Color selectedGreenTint = primarySoft;
  static const Color selectedTint = primarySoft;
  static const Color selectedBorder = primaryLight;
  static const Color primaryButton = textPrimary;
  static const Color buttonDark = textPrimary;

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASSMORPHISM TOKENS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double glassBlur = 24.0;
  static const double glassBlurLight = 12.0;
  static const double glassOpacity = 0.72;
  static const double glassBorderWidth = 0.5;
  static const double cardRadius = 24.0;
  static const double cardRadiusSm = 16.0;
  static const double cardRadiusLg = 28.0;
  static const double navBarBlur = 32.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (4px base)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ═══════════════════════════════════════════════════════════════════════════
  // AMBIENT GRADIENT (CogniPulse-driven)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<Color> ambientGradient(int score) {
    if (score >= 80) {
      return [
        const Color(0xFFF0F4EE),
        const Color(0xFFE8F0E8),
        const Color(0xFFF3F1EB)
      ];
    } else if (score >= 55) {
      return [
        const Color(0xFFF3F1EB),
        const Color(0xFFF5F3EE),
        const Color(0xFFF3F1EB)
      ];
    } else if (score >= 30) {
      return [
        const Color(0xFFF2F0EE),
        const Color(0xFFF5F3EE),
        const Color(0xFFF0EEEC)
      ];
    } else {
      return [
        const Color(0xFFF5EFE8),
        const Color(0xFFF5F3EE),
        const Color(0xFFF2EEEA)
      ];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY — DM Sans (premium, geometric, clean)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get _baseFont => GoogleFonts.dmSans();

  static TextStyle get displayLarge => _baseFont.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.15);
  static TextStyle get displayMedium => _baseFont.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2);
  static TextStyle get displaySmall => _baseFont.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.25);
  static TextStyle get headlineLarge => _baseFont.copyWith(
      fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get headlineMed => _baseFont.copyWith(
      fontSize: 17, fontWeight: FontWeight.w600, height: 1.35);
  static TextStyle get bodyLarge => _baseFont.copyWith(
      fontSize: 17, fontWeight: FontWeight.w400, height: 1.45);
  static TextStyle get bodyMedium => _baseFont.copyWith(
      fontSize: 15, fontWeight: FontWeight.w400, height: 1.45);
  static TextStyle get bodySmall => _baseFont.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: textSecondary);
  static TextStyle get labelLarge => _baseFont.copyWith(
      fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static TextStyle get labelSmall => _baseFont.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: textTertiary);
  static TextStyle get caption => _baseFont.copyWith(
      fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORATION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard glass card decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: surfaceBorder, width: glassBorderWidth),
      );

  /// Subtle shadow for elevated elements
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0x0A000000),
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0x05000000),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Primary accent shadow (for CTA buttons)
  static List<BoxShadow> accentShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        surface: surfaceCard,
        primary: primary,
        primaryContainer: primarySoft,
        secondary: accent,
        secondaryContainer: accentSoft,
        onSurface: textPrimary,
        onPrimary: textOnPrimary,
        onSecondary: textPrimary,
        outline: surfaceBorder,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: headlineLarge.copyWith(color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadiusSm),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: bodyMedium.copyWith(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          textStyle: labelLarge,
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard,
        contentTextStyle: bodyMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 0.5,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // TODO: real dark mode
}
