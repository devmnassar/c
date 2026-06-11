import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../l10n/app_localizations.dart';

AppLocalizations _resolveL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (l10n != null) return l10n;

  final locale = Localizations.maybeLocaleOf(context);
  if (locale != null) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (supported) return lookupAppLocalizations(locale);
  }

  return lookupAppLocalizations(const Locale('en'));
}

/// Floating map control buttons: Expand (fullscreen) and Reset (recenter).
/// Aligned bottom-right in LTR / bottom-left in RTL.
class IncomingMapControls extends StatelessWidget {
  final bool showReset;
  final VoidCallback onExpand;
  final VoidCallback? onReset;
  final bool isRtl;

  const IncomingMapControls({
    super.key,
    required this.showReset,
    required this.onExpand,
    this.onReset,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
    return PositionedDirectional(
      bottom: 12.h,
      end: isRtl ? null : 12.w,
      start: isRtl ? 12.w : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReset && onReset != null) ...[
            _MapControlButton(
              icon: Icons.my_location,
              tooltip: l10n.resetMap,
              onPressed: onReset!,
            ),
            SizedBox(width: 8.w),
          ],
          _MapControlButton(
            icon: Icons.fullscreen,
            tooltip: l10n.expandMap,
            onPressed: onExpand,
          ),
        ],
      ),
    );
  }
}

/// Fullscreen map controls: Close (X) and Reset. Bottom-right/bottom-left.
class IncomingFullMapControls extends StatelessWidget {
  final bool showReset;
  final VoidCallback onClose;
  final VoidCallback? onReset;
  final bool isRtl;

  const IncomingFullMapControls({
    super.key,
    required this.showReset,
    required this.onClose,
    this.onReset,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
    return PositionedDirectional(
      bottom: 24.h,
      end: isRtl ? null : 24.w,
      start: isRtl ? 24.w : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReset && onReset != null) ...[
            _MapControlButton(
              icon: Icons.my_location,
              tooltip: l10n.resetMap,
              onPressed: onReset!,
            ),
            SizedBox(width: 8.w),
          ],
          _MapControlButton(
            icon: Icons.close,
            tooltip: l10n.closeMap,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12.r),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
        ),
      ),
    );
  }
}
