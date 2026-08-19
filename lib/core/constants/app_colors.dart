import 'package:flutter/material.dart';

/// All the colors used across the app live here.
///
/// Keeping colors in one file means if we ever want to change our theme,
/// we only need to change the values here instead of hunting through
/// every screen in the app.
class AppColors {
  // Private constructor so nobody can accidentally create an AppColors object.
  // We only ever use the static values below, like AppColors.primaryNavy.
  AppColors._();

  // ---- Main brand colors ----

  /// The dark navy blue used for the app bar, the drawer background,
  /// and anything that should look like our main "brand" color.
  static const Color primaryNavy = Color(0xFF0B1730);

  /// The light grey-white used as the background of most screens.
  static const Color background = Color(0xFFF5F6F8);

  /// Plain white, used for cards and the app bar text.
  static const Color white = Color(0xFFFFFFFF);

  /// A slightly lighter navy, used together with [primaryNavy] to make
  /// a subtle gradient on the dashboard's "Welcome back" card. It's
  /// close in hue to the drawer's navy on purpose, so the banner reads
  /// as "the same brand color, with a little depth" rather than a
  /// completely different, brighter color.
  static const Color secondaryNavy = Color(0xFF1B2C52);

  /// The thin border color used around white cards.
  static const Color cardBorder = Color(0xFFE5E7EB);

  /// Default color for body text.
  static const Color textPrimary = Color(0xFF1F2937);

  /// Lighter color for secondary text, like subtitles.
  static const Color textSecondary = Color(0xFF6B7280);

  // ---- Accent / status colors ----
  //
  // These are used in small amounts to tell things apart at a glance:
  // a colored chip, a colored outline on a card, a colored dot, etc.
  // We never use these as big background fills.

  /// Red: used for things that are live right now or urgent.
  static const Color statusRed = Color(0xFFA32D2D);
  static const Color statusRedBg = Color(0xFFFCEBEB);

  /// Amber/yellow: used for things that are upcoming or need attention soon.
  static const Color statusAmber = Color(0xFF854F0B);
  static const Color statusAmberBg = Color(0xFFFAEEDA);

  /// Green: used for things that are done or positive.
  static const Color statusGreen = Color(0xFF3B6D11);
  static const Color statusGreenBg = Color(0xFFEAF3DE);

  /// Orange: used as a 4th differentiating color, e.g. "in review".
  static const Color statusOrange = Color(0xFFC2410C);
  static const Color statusOrangeBg = Color(0xFFFFEDD5);

  /// Purple: used as a 5th differentiating color, e.g. a stat card accent.
  static const Color statusPurple = Color(0xFF6B21A8);
  static const Color statusPurpleBg = Color(0xFFF3E8FF);

  // ---- Stat card colors ----
  //
  // The 4 dashboard stat cards, and the 3 list sections below them, use
  // these as a solid fill behind an icon, and as a label/pill color.
  // They're deliberately a shade deeper and less neon than a typical
  // "bright" palette - closer to what a serious business dashboard
  // would use - so the app reads as professional rather than playful.
  static const Color statCardOrange = Color(0xFFD97706);
  static const Color statCardRed = Color(0xFFDC2626);
  static const Color statCardGreen = Color(0xFF15803D);
  static const Color statCardBlue = Color(0xFF2563EB);

  // ---- Section background tints ----
  //
  // Extremely light, flat background colors for the three dashboard
  // list sections (Today's Schedule, Pending Grading, Recent
  // Submissions). They're fixed, hand-picked pale colors rather than a
  // computed tint of the (fairly deep) stat card colors above, so they
  // stay reliably soft no matter what - just a hint of color, not a
  // wash.
  static const Color sectionRedBg = Color(0xFFFDF3F2);
  static const Color sectionGreenBg = Color(0xFFF0F8F1);
  static const Color sectionBlueBg = Color(0xFFEFF4FC);
}
