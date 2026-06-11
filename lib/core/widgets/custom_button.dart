import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum CustomButtonVariant { filled, outlined }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.variant = CustomButtonVariant.filled,
    this.height = 58,
    this.backgroundColor,
    this.foregroundColor,
    this.borderSide,
    this.borderRadius = 18,
    this.elevation,
    this.shadowColor,
    this.textStyle,
    this.padding,
  });

  final String text;
  final FutureOr<void> Function()? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final CustomButtonVariant variant;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? borderSide;
  final double borderRadius;
  final double? elevation;
  final Color? shadowColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final resolvedBackgroundColor = backgroundColor ?? primaryColor;
    final resolvedForegroundColor = foregroundColor ?? Colors.white;
    final disabledBackgroundColor = resolvedBackgroundColor.withValues(
      alpha: 0.45,
    );
    final disabledForegroundColor = resolvedForegroundColor.withValues(
      alpha: 0.8,
    );
    final resolvedTextStyle = textStyle ??
        TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius.r),
    );
    final onPressedCallback =
        isLoading || onPressed == null ? null : () => onPressed!.call();
    final buttonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
      shape: WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledForegroundColor;
        }
        return resolvedForegroundColor;
      }),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height.h,
      child: AbsorbPointer(
        absorbing: isLoading,
        child: variant == CustomButtonVariant.outlined
            ? OutlinedButton(
                onPressed: onPressedCallback,
                style: buttonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return backgroundColor == null
                          ? Colors.transparent
                          : disabledBackgroundColor;
                    }
                    return backgroundColor;
                  }),
                  side: WidgetStatePropertyAll<BorderSide?>(borderSide),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2.r,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            resolvedForegroundColor,
                          ),
                        ),
                      )
                    : Text(text, style: resolvedTextStyle),
              )
            : ElevatedButton(
                onPressed: onPressedCallback,
                style: buttonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return disabledBackgroundColor;
                    }
                    return resolvedBackgroundColor;
                  }),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return 0;
                    }
                    return elevation ?? 8.r;
                  }),
                  shadowColor: WidgetStatePropertyAll<Color?>(
                    shadowColor ??
                        resolvedBackgroundColor.withValues(alpha: 0.35),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5.r,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            resolvedForegroundColor,
                          ),
                        ),
                      )
                    : Text(text, style: resolvedTextStyle),
              ),
      ),
    );
  }
}
