import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../core/widgets/scaffold_auth.dart';

class SignUpPage extends StatefulWidget {
  static const String id = '/signup';
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

  PhoneNumber? _initialPhoneNumber;
  String _e164Number = '';
  String _nationalNumber = '';

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
        if (await photoFile.exists()) {
          _profilePhoto = photoFile;
        }
      }

      if (savedE164.isNotEmpty) {
        _e164Number = savedE164;
        _nationalNumber = savedNational;
        try {
          final regionInfo = await PhoneNumber.getRegionInfoFromPhoneNumber(
            savedE164,
          );
          if (mounted) {
            String nationalNum = savedNational;
            if (nationalNum.isEmpty && savedE164.isNotEmpty) {
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
                isoCode: regionInfo.isoCode ?? 'SA',
                dialCode: regionInfo.dialCode ?? '+966',
              );
              _phoneController.text = nationalNum;
              _nationalNumber = nationalNum;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _initialPhoneNumber = PhoneNumber(isoCode: 'SA');
              _phoneController.text = savedNational;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _initialPhoneNumber = PhoneNumber(isoCode: 'SA');
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _initialPhoneNumber = PhoneNumber(isoCode: 'SA');
        });
      }
    }

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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final photoFile = File(pickedFile.path);
      if (await photoFile.exists()) {
        setState(() {
          _profilePhoto = photoFile;
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo is required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ProfileService.saveProfile(
        fullName: _nameController.text.trim(),
        e164Number: _e164Number,
        nationalNumber: _nationalNumber,
        photoPath: _profilePhoto!.path,
        nationalId: _nationalIdController.text.trim(),
        phoneVerified: _phoneVerified,
      );

      if (mounted) {
        context.push('/signup/otp', extra: _e164Number);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ScaffoldItem(
      title: 'Create Account',
      currentStep: 1,
      totalSteps: 4,
      onNext: _onNext,
      loading: _loading,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 6),
                        ),
                        child: _profilePhoto != null
                            ? ClipOval(
                                child: Image.file(
                                  _profilePhoto!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor.withValues(alpha: 0.05),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 70,
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Add profile photo',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[800],
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                _buildFieldTitle('Full Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'John Doe',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: primaryColor,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Full name is required'
                      : null,
                ),
                const SizedBox(height: 24),

                // Phone Number
                _buildFieldTitle('Phone Number'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      _e164Number = number.phoneNumber ?? '';
                      _nationalNumber = _phoneController.text;
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DROPDOWN,
                      showFlags: true,
                      setSelectorButtonAsPrefixIcon: true,
                      leadingPadding: 16,
                    ),
                    initialValue: _initialPhoneNumber,
                    textFieldController: _phoneController,
                    inputDecoration: InputDecoration(
                      hintText: '5xxxxxxxx',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    formatInput: true,
                  ),
                ),
                const SizedBox(height: 24),

                // National ID
                _buildFieldTitle('National ID (Optional)'),
                TextFormField(
                  controller: _nationalIdController,
                  decoration: InputDecoration(
                    hintText: 'Enter your ID',
                    prefixIcon: Icon(Icons.badge_outlined, color: primaryColor),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
