import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return PositionedDirectional(
      bottom: 12,
      end: isRtl ? null : 12,
      start: isRtl ? 12 : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReset && onReset != null) ...[
            _MapControlButton(
              icon: Icons.my_location,
              tooltip: l10n.resetMap,
              onPressed: onReset!,
            ),
            const SizedBox(width: 8),
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
    final l10n = AppLocalizations.of(context)!;
    return PositionedDirectional(
      bottom: 24,
      end: isRtl ? null : 24,
      start: isRtl ? 24 : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showReset && onReset != null) ...[
            _MapControlButton(
              icon: Icons.my_location,
              tooltip: l10n.resetMap,
              onPressed: onReset!,
            ),
            const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
