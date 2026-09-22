/// All colour constants for the Noor Companion design system.
/// Visual world: "Soft Luxury" — lavender-grey canvas, white cards,
/// ink-navy primary actions, single teal accent, gold reserved for
/// streaks and premium moments. Never use raw hex values in widgets.
library;

import 'package:flutter/material.dart';

/// Brand colour palette for Noor Companion.
abstract final class AppColors {
  /// Accent teal — icons, active states, progress, links.
  /// Brightened to the reference turquoise; still passes 3:1 non-text
  /// contrast on white. For body-size teal TEXT use [brandTealDark].
  static const Color brandTeal = Color(0xFF0D9488);

  /// Deep teal — pressed states, teal text on light surfaces (AA safe).
  static const Color brandTealDark = Color(0xFF0B7268);

  /// Soft teal tint — chip fills, icon containers, selected surfaces.
  static const Color tealLight = Color(0xFFDDF5F2);

  /// Near-white teal tint — subtle section backgrounds.
  static const Color tealXLight = Color(0xFFF0FAF8);

  /// Ink navy — primary buttons, bottom nav, hero cards. The reference
  /// look is built on near-black pills, not coloured ones.
  static const Color ink = Color(0xFF171930);
  static const Color inkSoft = Color(0xFF232544);
  static const Color inkBorder = Color(0xFF2C2E52);

  /// Gold accent — streak flame and premium badges ONLY. Never a second
  /// accent colour anywhere else.
  static const Color brandGold = Color(0xFFE8A33D);
  static const Color brandGoldDark = Color(0xFFB97F23);
  static const Color goldLight = Color(0xFFFCF1DD);

  /// Page background — soft lavender grey, the signature of the look.
  static const Color background = Color(0xFFF2F1F8);

  /// Secondary background for section differentiation.
  static const Color backgroundSecondary = Color(0xFFEAE9F3);

  /// Card and surface background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text — headings and high-emphasis content.
  static const Color textPrimary = Color(0xFF171930);

  /// Body text.
  static const Color textBody = Color(0xFF3A3B52);

  /// Secondary text — labels and supporting copy.
  static const Color textSecondary = Color(0xFF55566E);

  /// Muted text — placeholders and tertiary content.
  static const Color textMuted = Color(0xFF8B8CA3);

  /// Default border colour.
  static const Color border = Color(0xFFE9E8F2);

  /// Darker border — emphasis dividers.
  static const Color borderDark = Color(0xFFDDDCEA);

  /// Success — task completion, available therapist dot.
  static const Color success = Color(0xFF16A34A);

  /// Error — destructive actions, unavailable states.
  static const Color error = Color(0xFFDC2626);
}
