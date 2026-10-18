import 'package:flutter/material.dart';

class AppColors {
  // Primary Accent (Enterprise Muted Blue / Slate accent)
  static const Color primary = Color(0xFF2563EB); 
  static const Color primaryHover = Color(0xFF1D4ED8); 
  static const Color primaryLight = Color(0xFFF1F5F9); 

  // Muted Semantic Status Colors with 1px border tints
  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF1D4ED8);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFDBEAFE);

  // Light Mode Neutral Palette (Crisp Enterprise Slate)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSidebar = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Mode Neutral Palette (Crisp Enterprise Dark Slate)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSidebar = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color darkCardBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Backward compatibility
  static const Color secondary = Color(0xFF475569);
  static const Color accent = Color(0xFF2563EB);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF15803D), Color(0xFF166534)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
