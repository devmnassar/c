import 'package:flutter/material.dart';

/// Centralized color constants aligned with [AppTheme].
///
/// Phase 1: additive only — not imported by production code yet.
/// Do not replace inline [Color] usages until a dedicated theming phase.
class AppColors {
  const AppColors._();

  /// Matches [AppTheme.primaryColor].
  static const primary = Color(0xFF23C1B2);

  /// Matches [AppTheme.backgroundColor].
  static const background = Color(0xFFF6FBFB);

  /// Matches light theme [ColorScheme.surface].
  static const surface = Colors.white;

  /// Matches light theme [ColorScheme.onSurface].
  static const onSurface = Color(0xFF111827);

  /// Matches light theme [ColorScheme.onSurfaceVariant].
  static const onSurfaceVariant = Color(0xFF6B7280);

  static const white = Colors.white;
  static const black = Colors.black;

  /// Material [Colors.red] — used for offline/error indicators in drawer.
  static const error = Colors.red;

  /// Material [Colors.green] — used for online indicators in drawer.
  static const success = Colors.green;

  // TODO: Define a single project-wide warning color when design confirms one.
  // static const warning = ...
}
