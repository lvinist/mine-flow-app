// mine-flow app theme — Forest & Stone design system.
//
// Implements the colour palette, typography, shape, and density tokens defined
// in Doc 07 — UI / Design System. All feature widgets reference this theme via
// Theme.of(context) — no feature file should hardcode raw colour values.
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colour tokens — Doc 07 §2 Design Tokens — Color Palette: Forest & Stone
// ---------------------------------------------------------------------------

/// Primary brand colour: Deep Forest Green.
const Color kColorPrimary = Color(0xFF166534);

/// On-primary (text/icon on a Primary-coloured surface).
const Color kColorOnPrimary = Colors.white;

/// Primary container (lighter tint for chips, highlights).
const Color kColorPrimaryContainer = Color(0xFFDCFCE7);

/// Success / passed-check semantic colour.
const Color kColorSuccess = Color(0xFF15803D);

/// Darkest text — near-black Stone.
const Color kColorTextPrimary = Color(0xFF292524);

/// Secondary text — warm Stone.
const Color kColorTextSecondary = Color(0xFF44403C);

/// Muted labels and borders.
const Color kColorMuted = Color(0xFF78716C);

/// Subtle border / divider line.
const Color kColorBorder = Color(0xFFE7E5E4);

/// Page / scaffold background — off-white Stone.
const Color kColorBackground = Color(0xFFFAFAF9);

/// Card surface.
const Color kColorSurface = Colors.white;

// Dark-mode equivalents (approximate inversions of the above).
const Color kColorPrimaryDark = Color(0xFF4ADE80);
const Color kColorBackgroundDark = Color(0xFF1C1917);
const Color kColorSurfaceDark = Color(0xFF292524);
const Color kColorTextPrimaryDark = Color(0xFFFAFAF9);
const Color kColorBorderDark = Color(0xFF44403C);

// ---------------------------------------------------------------------------
// Shape token — Doc 07 §2 Shape & Elevation — 4 px corner radius
// ---------------------------------------------------------------------------

/// Universal 4 px corner radius for cards, buttons, and inputs.
const double kRadiusBase = 4.0;
const BorderRadius kBorderRadius = BorderRadius.all(Radius.circular(kRadiusBase));

// ---------------------------------------------------------------------------
// AppTheme — static factory for light and dark ThemeData
// ---------------------------------------------------------------------------

/// Provides the mine-flow [ThemeData] instances.
class AppTheme {
  AppTheme._();

  /// Light theme — default per Doc 07 §5 Theme Support.
  static ThemeData get light => _build(brightness: Brightness.light);

  /// Dark theme — toggled by user or OS preference per Doc 07 §5.
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary
      primary: isDark ? kColorPrimaryDark : kColorPrimary,
      onPrimary: isDark ? kColorBackgroundDark : kColorOnPrimary,
      primaryContainer: kColorPrimaryContainer,
      onPrimaryContainer: kColorPrimary,
      // Secondary (Stone)
      secondary: kColorMuted,
      onSecondary: Colors.white,
      secondaryContainer: kColorBorder,
      onSecondaryContainer: kColorTextPrimary,
      // Surface
      surface: isDark ? kColorSurfaceDark : kColorSurface,
      onSurface: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
      // Background
      surfaceContainerHighest: isDark ? kColorBackgroundDark : kColorBackground,
      onSurfaceVariant: isDark ? kColorTextPrimaryDark : kColorTextSecondary,
      // Semantic
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      outline: isDark ? kColorBorderDark : kColorBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // --- Typography: Geist (Doc 07 §2 Typography) ---
      // Geist is bundled as local assets for guaranteed offline availability.
      fontFamily: 'Geist',

      // --- Compact density (Doc 07 §2 Spacing & Layout) ---
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),

      // --- Shape: 4 px radius (Doc 07 §2 Shape & Elevation) ---
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: kBorderRadius),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: kBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: kBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // --- Motion: snappy (Doc 07 §5 Motion — 150-200 ms fades) ---
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // --- Scaffold background ---
      scaffoldBackgroundColor:
          isDark ? kColorBackgroundDark : kColorBackground,

      // --- Divider ---
      dividerTheme: DividerThemeData(
        color: isDark ? kColorBorderDark : kColorBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
