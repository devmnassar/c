import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding/onboarding_state.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../l10n/app_localizations.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  File? _profilePhoto;
  bool _phoneVerified = false;
  bool _loading = false;
  bool _sendingCode = false;
  bool _isPhoneValid = false;

  PhoneNumber? _initialPhoneNumber;
  String _e164Number = '';
  String _nationalNumber = '';

  // OTP input controllers
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.getProfile();
    if (profile != null) {
      _nameController.text = profile['fullName'] ?? '';
      final savedE164 = profile['e164Number'] ?? profile['mobileNumber'] ?? '';
      final savedNational = profile['nationalNumber'] ?? '';
      _nationalIdController.text = profile['nationalId'] ?? '';
      _phoneVerified = profile['phoneVerified'] ?? false;
      final photoPath = profile['photoPath'];
      if (photoPath != null) {
        final photoFile = File(photoPath);
        // Only set photo if file actually exists (not placeholder)
        if (await photoFile.exists()) {
          _profilePhoto = photoFile;
        }
      }

      // Try to parse saved phone number
      if (savedE164.isNotEmpty) {
        _e164Number = savedE164;
        _nationalNumber = savedNational;
        _isPhoneValid = true;
        // Parse the saved E.164 number to PhoneNumber object
        try {
          final regionInfo = await PhoneNumber.getRegionInfoFromPhoneNumber(
            savedE164,
          );
          if (mounted) {
            // Use saved national number or extract from E.164 by removing country code
            String nationalNum = savedNational;
            if (nationalNum.isEmpty && savedE164.isNotEmpty) {
              // Try to extract national number by removing country code
              // This is a fallback - ideally we should store it separately
              final dialCode = regionInfo.dialCode ?? '+966';
              if (savedE164.startsWith(dialCode)) {
                nationalNum = savedE164.substring(dialCode.length);
              } else {
                nationalNum = savedE164.replaceAll(RegExp(r'[^\d]'), '');
              }
            }
            setState(() {
              _initialPhoneNumber = PhoneNumber(
                phoneNumber: savedE164,
                isoCode: regionInfo.isoCode ?? _getDefaultCountryCode(),
                dialCode: regionInfo.dialCode ?? '+966',
              );
              _phoneController.text = nationalNum;
              _nationalNumber = nationalNum;
            });
          }
        } catch (e) {
          // If parsing fails, use default country
          if (mounted) {
            setState(() {
              _initialPhoneNumber = PhoneNumber(
                isoCode: _getDefaultCountryCode(),
              );
              _phoneController.text = savedNational.isNotEmpty
                  ? savedNational
                  : '';
            });
          }
        }
      } else {
        // Initialize with default country
        if (mounted) {
          setState(() {
            _initialPhoneNumber = PhoneNumber(
              isoCode: _getDefaultCountryCode(),
            );
          });
        }
      }
    } else {
      // Initialize with default country if no profile exists
      if (mounted) {
        setState(() {
          _initialPhoneNumber = PhoneNumber(isoCode: _getDefaultCountryCode());
        });
      }
    }

    // Also check phone verified status separately
    final phoneVerified = await ProfileService.isPhoneVerified();
    if (mounted) {
      setState(() {
        _phoneVerified = phoneVerified;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Only set photo if user actually picked/captured a photo (not placeholder)
      final photoFile = File(pickedFile.path);
      if (await photoFile.exists()) {
        setState(() {
          _profilePhoto = photoFile;
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n?.takePhoto ?? 'Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n?.chooseFromGallery ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPhoneValid || _e164Number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.invalidPhone ??
                'Invalid phone number',
          ),
        ),
      );
      return;
    }

    setState(() {
      _sendingCode = true;
    });

    try {
      // TODO: Call backend API to send verification code
      // Use _e164Number for the API call
      debugPrint('Sending OTP to E.164 number: $_e164Number');
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to OTP verification page instead of showing modal
      if (mounted) {
        final verified = await context.pushNamed<bool>(
          'signupOtp',
          extra: _e164Number,
        );

        if (verified == true && mounted) {
          setState(() {
            _phoneVerified = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingCode = false;
        });
      }
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.profilePhotoRequired ??
                'Profile photo is required',
          ),
        ),
      );
      return;
    }

    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number first')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Save profile data with both E.164 and national number
      await ProfileService.saveProfile(
        fullName: _nameController.text.trim(),
        e164Number: _e164Number,
        nationalNumber: _nationalNumber,
        photoPath: _profilePhoto!.path,
        nationalId: _nationalIdController.text.trim().isEmpty
            ? null
            : _nationalIdController.text.trim(),
        phoneVerified: _phoneVerified,
      );

      // Mark profile as completed
      await OnboardingState.instance.setProfileCompleted(true);

      if (mounted) {
        context.go('/signup/documents');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Default country for phone input: Saudi Arabia (+966)
  String _getDefaultCountryCode() {
    return 'SA';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Complete Profile button enabled only when:
    // 1. Name is not empty
    // 2. Phone is valid
    // 3. Phone is verified
    // 4. Photo is selected (not placeholder)
    final canComplete =
        _nameController.text.trim().isNotEmpty &&
        _isPhoneValid &&
        _phoneVerified &&
        _profilePhoto != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.signup ?? 'Sign Up')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: _profilePhoto != null
                          ? ClipOval(
                              child: Image.file(
                                _profilePhoto!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          color: theme.colorScheme.onPrimary,
                          onPressed: _showImageSourceDialog,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_profilePhoto == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n?.profilePhotoRequired ?? 'Profile photo is required',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n?.fullName ?? 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n?.fullNameRequired ?? 'Full name is required';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // International Phone Number Field
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  // Guard: Only update if phone number actually changed
                  final newE164 = number.phoneNumber ?? '';
                  if (newE164 == _e164Number &&
                      number.isoCode == _initialPhoneNumber?.isoCode) {
                    return; // No change, skip update
                  }

                  // Extract national number from E.164 by removing country code
                  String nationalNum = '';
                  if (newE164.isNotEmpty && number.dialCode != null) {
                    final dialCode = number.dialCode!.replaceAll(
                      RegExp(r'[^\d]'),
                      '',
                    );
                    final fullNumber = newE164.replaceAll(RegExp(r'[^\d]'), '');
                    if (fullNumber.startsWith(dialCode)) {
                      nationalNum = fullNumber.substring(dialCode.length);
                    } else {
                      nationalNum = fullNumber;
                    }
                  }

                  // Guard: Only update state if values actually changed
                  final hasChanged =
                      newE164 != _e164Number || nationalNum != _nationalNumber;
                  if (!hasChanged) {
                    return;
                  }

                  setState(() {
                    _e164Number = newE164;
                    _nationalNumber = nationalNum;
                    _isPhoneValid = newE164.isNotEmpty;
                    _phoneVerified = false; // Reset verification
                  });

                  // Only print when value actually changes
                  debugPrint(
                    'Phone updated - E.164: $newE164, National: $nationalNum',
                  );
                },
                onInputValidated: (bool value) async {
                  // Guard: Only update if validation state actually changed
                  if (value == _isPhoneValid) return;

                  // TODO: TEMP FOR TESTING ONLY - Remove this auto-verification once backend OTP is connected
                  // Auto-verify phone when valid for testing purposes
                  if (value && !_phoneVerified) {
                    await ProfileService.setPhoneVerified(true);
                    if (mounted) {
                      setState(() {
                        _isPhoneValid = value;
                        _phoneVerified = true; // TEMP: Auto-verify for testing
                      });
                    }
                  } else {
                    if (mounted) {
                      setState(() {
                        _isPhoneValid = value;
                      });
                    }
                  }
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DROPDOWN,
                  showFlags: true,
                  useEmoji: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                selectorTextStyle: theme.textTheme.bodyLarge,
                initialValue:
                    _initialPhoneNumber ??
                    PhoneNumber(isoCode: _getDefaultCountryCode()),
                textFieldController: _phoneController,
                formatInput: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                inputBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                inputDecoration: InputDecoration(
                  labelText: l10n?.phoneNumberLabel ?? 'Phone Number',
                  hintText: 'Enter phone number',
                  errorText: _isPhoneValid || _phoneController.text.isEmpty
                      ? null
                      : (l10n?.invalidPhone ?? 'Invalid phone number'),
                  suffixIcon: _phoneVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                countries: const [], // Empty list means all countries
                locale: Localizations.localeOf(context).languageCode,
                spaceBetweenSelectorAndTextField: 0,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _phoneVerified
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle),
                        label: Text(l10n?.verified ?? 'Verified'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed:
                            (_isPhoneValid && !_sendingCode && !_phoneVerified)
                            ? _sendCode
                            : null,
                        icon: _sendingCode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _sendingCode
                              ? (l10n?.sendingCode ?? 'Sending Code...')
                              : (l10n?.sendCode ?? 'Send Code'),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // National ID Field (Optional)
              TextFormField(
                controller: _nationalIdController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n?.nationalId ?? 'National ID'} (${l10n?.language == 'ar' ? 'اختياري' : 'Optional'})',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canComplete && !_loading ? _completeProfile : null,
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
                          l10n?.completeProfile ?? 'Complete Profile',
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
