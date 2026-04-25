/// All colour constants for the Noor Companion design system.
/// Sourced from the brand palette defined in .design/recovery-companion/DESIGN_BRIEF.md.
/// Never use raw hex values in widgets — always reference these constants.
library;

import 'package:flutter/material.dart';

/// Brand colour palette for Noor Companion.
abstract final class AppColors {
  /// Primary brand teal — used for primary actions, headers, and active states.
  static const Color brandTeal = Color(0xFF0D7C6E);

  /// Darker teal — hover and pressed states on teal surfaces.
  static const Color brandTealDark = Color(0xFF0A6459);

  /// Lighter teal — card fills and soft container backgrounds.
  static const Color tealLight = Color(0xFFE8F5F3);

  /// Very light teal — page section backgrounds.
  static const Color tealXLight = Color(0xFFF2FAF9);

  /// Gold accent — milestone rewards, premium badges, streak highlights.
  static const Color brandGold = Color(0xFFC9933A);

  /// Darker gold — pressed state on gold elements.
  static const Color brandGoldDark = Color(0xFFA87730);

  /// Light gold — premium callout backgrounds.
  static const Color goldLight = Color(0xFFFDF3E3);

  /// Page background — warm off-white, never pure white.
  static const Color background = Color(0xFFF6FAF9);

  /// Secondary background for section differentiation.
  static const Color backgroundSecondary = Color(0xFFEEF6F4);

  /// Card and surface background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text — headings and high-emphasis content.
  static const Color textPrimary = Color(0xFF0F1C1A);

  /// Body text.
  static const Color textBody = Color(0xFF1A2E2B);

  /// Secondary text — labels and supporting copy.
  static const Color textSecondary = Color(0xFF3D5550);

  /// Muted text — placeholders and tertiary content.
  static const Color textMuted = Color(0xFF6B8A85);

  /// Default border colour.
  static const Color border = Color(0xFFDDE8E6);

  /// Darker border — emphasis dividers.
  static const Color borderDark = Color(0xFFC4D8D5);

  /// Success — task completion, available therapist dot.
  static const Color success = Color(0xFF2E7D52);

  /// Error — destructive actions, unavailable states.
  static const Color error = Color(0xFFB94040);
}
