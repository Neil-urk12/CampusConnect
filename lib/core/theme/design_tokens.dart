import 'package:flutter/material.dart';

/// Design System Tokens - "The Scholastic Horizon"
/// Based on DESIGN.md specifications
class DesignTokens {
  // Colors - Tonal Architecture
  static const primary = Color(0xFF001E40);
  static const primaryContainer = Color(0xFF003366);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFD4E3FF);

  static const secondary = Color(0xFF00796B);
  static const secondaryContainer = Color(0xFFB2DFDB);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF004D40);

  static const tertiary = Color(0xFF006A67);
  static const tertiaryContainer = Color(0xFF003A36);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF6FF7F2);

  static const secondaryFixed = Color(0xFFB2DFDB);
  static const onSecondaryFixed = Color(0xFF004D40);

  // Surface Hierarchy - "No-Line" Rule
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const surfaceVariant = Color(0xFFDFE2EB);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF43474E);

  static const surfaceTint = Color(0xFF3A5F94);
  static const outlineVariant = Color(0xFFC3C6D1);

  // Semantic Colors
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF410002);

  // Category Colors (for events)
  static const categoryAcademic = Color(0xFF0EA5E9);
  static const categorySocial = Color(0xFFA855F7);
  static const categorySports = Color(0xFF10B981);
  static const categoryCareer = Color(0xFFF59E0B);

  // Elevation & Depth - Ambient Shadows
  static BoxShadow ambientShadow({double opacity = 0.06}) {
    return BoxShadow(
      color: onSurface.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    );
  }

  static BoxShadow cardShadow() {
    return BoxShadow(
      color: onSurface.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    );
  }

  // Border Radius Tokens
  static const radiusSm = 4.0; // 0.25rem
  static const radiusMd = 8.0; // 0.5rem
  static const radiusLg = 16.0; // 1rem
  static const radiusXl = 24.0; // 1.5rem

  // Spacing Scale
  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;

  // Glass & Gradient
  static LinearGradient primaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primaryContainer],
    );
  }

  static LinearGradient categoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        );
      case 'social':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
        );
      case 'sports':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case 'career':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      default:
        return primaryGradient();
    }
  }

  // Ghost Border
  static Border ghostBorder() {
    return Border.all(color: outlineVariant.withValues(alpha: 0.15), width: 1);
  }
}
