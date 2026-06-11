import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../l10n/app_localizations.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with CodeAutoFill {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initAutoFill();
  }

  Future<void> _initAutoFill() async {
    try {
      // Start listening for SMS codes
      listenForCode();
    } catch (e) {
      // Auto-fill not available (e.g., on web), continue with manual input
    }
  }

  @override
  void codeUpdated() {
    // Access the code through the 'code' field provided by CodeAutoFill mixin
    final smsCode = code;
    if (smsCode != null && smsCode.length >= 6) {
      // Extract 6-digit code
      final match = RegExp(r'\d{6}').firstMatch(smsCode);
      if (match != null) {
        final extractedCode = match.group(0)!;
        if (extractedCode.length == 6) {
          for (int i = 0; i < 6; i++) {
            _controllers[i].text = extractedCode[i];
          }
          _verifyCode(extractedCode);
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    // Cancel SMS listening
    cancel();
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (index == 5 && value.isNotEmpty) {
      final code = _controllers.map((c) => c.text).join();
      if (code.length == 6) {
        _verifyCode(code);
      }
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      // TODO: Call backend API to verify code
      await Future.delayed(const Duration(seconds: 1));

      // Mock verification - accept any 6-digit code for now
      if (code.length == 6) {
        // Mark phone as verified
        await ProfileService.setPhoneVerified(true);

        if (mounted) {
          // Return to profile page
          context.pop(true);
        }
      } else {
        throw Exception('Invalid code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.invalidCode ??
                  'Invalid verification code',
            ),
          ),
        );
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    // TODO: Call backend API to resend code
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code resent')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.enterVerificationCode ?? 'Enter Verification Code'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(Icons.sms, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                l10n?.enterVerificationCode ?? 'Enter Verification Code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.verificationCodeSent(widget.phoneNumber) ??
                    'Verification code sent to ${widget.phoneNumber}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 64,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onCodeChanged(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              if (_loading)
                const CircularProgressIndicator()
              else
                TextButton(
                  onPressed: _resendCode,
                  child: Text(l10n?.resendCode ?? 'Resend Code'),
                ),

              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          final code = _controllers.map((c) => c.text).join();
                          if (code.length == 6) {
                            _verifyCode(code);
                          }
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n?.verify ?? 'Verify',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
