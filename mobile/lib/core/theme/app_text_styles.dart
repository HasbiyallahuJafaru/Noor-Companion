/// Typography definitions for the Noor Companion design system.
/// Latin text uses Inter via google_fonts.
/// Arabic text uses Amiri via google_fonts — used exclusively for
/// Quranic text, duas, and dhikr phrases.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text style constants for the app.
/// Use these instead of inline TextStyle definitions in widgets.
abstract final class AppTextStyles {
  // ── Latin (Inter) ──────────────────────────────────────────────────────────

  /// Large display heading — used on splash and milestone screens.
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.1,
      );

  /// Section headings and screen titles.
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// Card titles and prominent labels.
  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Sub-section labels.
  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Standard body text.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textBody,
        height: 1.6,
      );

  /// Secondary body — supporting copy and descriptions.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Button label text.
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
      );

  /// Small labels, badges, and metadata.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.2,
      );

  // ── Arabic (Amiri) ─────────────────────────────────────────────────────────

  /// Primary Arabic display — used for the Arabic phrase in the text block.
  /// Minimum 24sp per accessibility requirements.
  static TextStyle get arabicLarge => GoogleFonts.amiri(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.8,
      );

  /// Arabic text at medium size — used in dhikr counter labels.
  static TextStyle get arabicMedium => GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.7,
      );

  /// Transliteration text — sits below the Arabic phrase.
  static TextStyle get transliteration => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
        height: 1.5,
      );
}
