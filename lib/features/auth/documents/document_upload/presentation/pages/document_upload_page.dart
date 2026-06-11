import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/profile/profile_service.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/documents/document_upload/presentation/widgets/custom_document_item.dart';
import 'package:gaseel_courier/features/auth/documents/driver_card_details/presentation/pages/driver_card_details_page.dart';
import 'package:gaseel_courier/features/auth/documents/iqama_details/presentation/pages/iqama_details_page.dart';
import 'package:gaseel_courier/features/auth/documents/license_details/presentation/pages/license_details_page.dart';
import 'package:gaseel_courier/features/auth/documents/selfie_details/presentation/pages/selfie_details_page.dart';
import 'package:gaseel_courier/features/auth/documents/vehicle_registration_details/presentaion/pages/vehicle_registration_details_page.dart';

class DocumentUploadPage extends StatefulWidget {
  static const String id = '/signup/documents';

  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  void _goBackToWelcome() {
    context.go('/signup/welcome');
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (mounted) setState(() => _loading = true);
    final profile = await ProfileService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  bool _isDocumentCompleted(String type) {
    if (_profile == null) return false;

    switch (type) {
      case 'iqama':
        return _profile!['iqamaPath'] != null;
      case 'selfie':
        return _profile!['selfiePath'] != null;
      case 'license':
        return _profile!['licenseFrontPath'] != null;
      case 'registration':
        return _profile!['vehicleRegistrationPath'] != null;
      case 'driver_card':
        return _profile!['driverCardPath'] != null;
      default:
        return false;
    }
  }

  Future<void> _openDocumentDetails(String route) async {
    final result = await context.push(route);
    if (result == true) {
      await _loadStatus();
    }
  }

  void _onNext() {
    final allDone = _isDocumentCompleted('iqama') &&
        _isDocumentCompleted('selfie') &&
        _isDocumentCompleted('license') &&
        _isDocumentCompleted('registration') &&
        _isDocumentCompleted('driver_card');

    if (allDone) {
      context.pushNamed('signupReview');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please upload all required documents')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToWelcome();
      },
      child: Scaffold(
        backgroundColor: primaryColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _goBackToWelcome,
                    ),
                    const Spacer(),
                    const Text(
                      'Gaseel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(),
                  const SizedBox(width: 8),
                  _dot(),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _dot(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Upload documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 45 / 2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(34)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            children: [
                              CustomDocumentItem(
                                title: 'Iqama',
                                isDone: _isDocumentCompleted('iqama'),
                                icon: Icons.badge_outlined,
                                onTap: () =>
                                    _openDocumentDetails(IqamaDetailsPage.id),
                              ),
                              CustomDocumentItem(
                                title: 'Selfie',
                                isDone: _isDocumentCompleted('selfie'),
                                icon: Icons.face_outlined,
                                onTap: () =>
                                    _openDocumentDetails(SelfieDetailsPage.id),
                              ),
                              CustomDocumentItem(
                                title: "Driver's licence",
                                isDone: _isDocumentCompleted('license'),
                                icon: Icons.credit_card_outlined,
                                onTap: () =>
                                    _openDocumentDetails(LicenseDetailsPage.id),
                              ),
                              CustomDocumentItem(
                                title: 'Vehicle registration',
                                isDone: _isDocumentCompleted('registration'),
                                icon: Icons.article_outlined,
                                onTap: () => _openDocumentDetails(
                                  VehicleRegistrationDetailsPage.id,
                                ),
                              ),
                              CustomDocumentItem(
                                title: 'Driver card',
                                isDone: _isDocumentCompleted('driver_card'),
                                icon: Icons.style_outlined,
                                onTap: () => _openDocumentDetails(
                                    DriverCardDetailsPage.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: CustomButton(
                          text: 'Next',
                          fullWidth: true,
                          onPressed: _onNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}
