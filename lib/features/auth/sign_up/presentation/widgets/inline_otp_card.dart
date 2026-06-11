import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';

class _InlineOtpCard extends StatelessWidget {
  const _InlineOtpCard({
    required this.phoneNumber,
    required this.secondsRemaining,
    required this.isExpired,
    required this.loading,
    this.errorMessage,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onActionTap,
  });

  final String phoneNumber;
  final int secondsRemaining;
  final bool isExpired;
  final bool loading;
  final String? errorMessage;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final Future<void> Function() onActionTap;

  String get _timeText {
    final safe = secondsRemaining < 0 ? 0 : secondsRemaining;
    return safe.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A2C),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify your number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E1F5A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit OTP sent to $phoneNumber',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsetsDirectional.only(end: index == 5 ? 0 : 6),
                  height: 54,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    enabled: !loading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF7ED3C8),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => onChanged(index, value),
                  ),
                ),
              );
            }),
          ),
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Time remaining: 00:$_timeText',
            style: const TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: isExpired ? 'Resend' : 'Verify',
            isLoading: loading,
            fullWidth: true,
            onPressed: onActionTap,
          ),
        ],
      ),
    );
  }
}
