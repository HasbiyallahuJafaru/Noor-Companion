/// Typography definitions for the Noor Companion design system.
/// Latin text uses Plus Jakarta Sans via google_fonts — the geometric,
/// slightly-rounded sans that carries the Soft Luxury look.
/// Arabic text uses Amiri via google_fonts — used exclusively for
/// Quranic text, duas, and dhikr phrases.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text style constants for the app.
/// Use these instead of inline TextStyle definitions in widgets.
abstract final class AppTextStyles {
  // ── Latin (Plus Jakarta Sans) ─────────────────────────────────────────────

  /// Large display heading — used on splash and milestone screens.
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.2,
        height: 1.08,
      );

  /// Section headings and screen titles.
  static TextStyle get headingLarge => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.6,
        height: 1.18,
      );

  /// Card titles and prominent labels.
  static TextStyle get headingMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  /// Sub-section labels.
  static TextStyle get headingSmall => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Standard body text.
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
        height: 1.6,
      );

  /// Secondary body — supporting copy and descriptions.
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Button label text.
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.1,
      );

  /// Small labels, badges, and metadata.
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
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
  static TextStyle get transliteration => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );
}
