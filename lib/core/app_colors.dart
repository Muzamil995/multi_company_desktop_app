import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =====================================================
  // 🎨 PRIMARY BRAND COLORS
  // =====================================================

  /// Main brand teal (buttons, active states, icons)
  static const Color primary = Color(0xFF4FD1C5);

  /// Dark navy for headings & strong emphasis (used in sidebar/charts)
  static const Color navy = Color(0xFF2D3748);

  /// Slightly lighter teal for accents and gradients
  static const Color accentTeal = Color(0xFF38B2AC);

  /// Dark slate background for specific cards (like the Active Users card)
  static const Color darkCard = Color(0xFF1F2733);

  // =====================================================
  // 🏠 BACKGROUND SYSTEM
  // =====================================================

  /// Main app background (very light off-white/gray)
  static const Color scaffoldBg = Color(0xFFF8F9FA);

  /// Sidebar background
  static const Color sidebarBg = Color(0xFFFFFFFF);

  /// Card background
  static const Color cardBg = Color(0xFFFFFFFF);

  /// Top navigation background
  static const Color topBarBg = Color(0xFFFFFFFF);

  // =====================================================
  // 🧱 BORDERS & DIVIDERS
  // =====================================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF0F2F5);

  /// Subtle hover overlay
  static const Color hoverOverlay = Color(0x0A000000);

  // =====================================================
  // 📝 TEXT COLORS
  // =====================================================

  /// Primary headings & strong labels
  static const Color textPrimary = Color(0xFF2D3748);

  /// Secondary text / Breadcrumbs / Muted labels
  static const Color textSecondary = Color(0xFFA0AEC0);

  /// Very muted placeholder text
  static const Color textMuted = Color(0xFFCBD5E0);

  /// Text on primary teal button
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // =====================================================
  // 🚦 STATUS COLORS
  // =====================================================

  /// Green for positive growth (+55%)
  static const Color success = Color(0xFF48BB78);

  /// Red for negative trends (-14%)
  static const Color error = Color(0xFFE53E3E);

  /// Warm yellow for warnings
  static const Color warning = Color(0xFFECC94B);

  // =====================================================
  // 📊 CHART COLORS
  // =====================================================

  static const Color chartTeal = Color(0xFF4FD1C5);
  static const Color chartNavy = Color(0xFF2D3748);
  static const Color chartGray = Color(0xFFE2E8F0);
  static const Color chartLine = Color(0xFF319795);
}
