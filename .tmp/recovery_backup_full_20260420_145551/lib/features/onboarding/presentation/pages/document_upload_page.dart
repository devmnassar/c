import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding/onboarding_state.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../l10n/app_localizations.dart';

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();

  File? _licensePhoto;
  File? _nationalIdPhoto;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source, bool isLicense) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (isLicense) {
          _licensePhoto = File(pickedFile.path);
        } else {
          _nationalIdPhoto = File(pickedFile.path);
        }
      });
    }
  }

  void _showImageSourcePicker(bool isLicense) {
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
                _pickImage(ImageSource.camera, isLicense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n?.chooseFromGallery ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isLicense);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDocuments() async {
    if (!_formKey.currentState!.validate()) return;

    if (_licensePhoto == null || _nationalIdPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both license and national ID photos'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ProfileService.saveDocuments(
        licensePath: _licensePhoto!.path,
        nationalIdPath: _nationalIdPhoto!.path,
        vehicleType: _vehicleTypeController.text.trim(),
        plateNumber: _plateNumberController.text.trim(),
        insuranceNumber: _insuranceNumberController.text.trim(),
      );

      await OnboardingState.instance.setDocumentsSubmitted(true);

      if (mounted) {
        context.go('/signup/awaiting-review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _plateNumberController.dispose();
    _insuranceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.uploadDocuments ?? 'Upload Documents')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.uploadDocuments ?? 'Upload Documents',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide clear photos of your documents and vehicle details.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Driving License
              _buildPhotoCard(
                title: l10n?.drivingLicense ?? 'Driving License',
                photo: _licensePhoto,
                onTap: () => _showImageSourcePicker(true),
              ),
              const SizedBox(height: 16),

              // National ID Card
              _buildPhotoCard(
                title: l10n?.nationalIdCard ?? 'National ID Card',
                photo: _nationalIdPhoto,
                onTap: () => _showImageSourcePicker(false),
              ),
              const SizedBox(height: 32),

              // Mock Fields
              TextFormField(
                controller: _vehicleTypeController,
                decoration: InputDecoration(
                  labelText: l10n?.vehicleType ?? 'Vehicle Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.directions_car),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateNumberController,
                decoration: InputDecoration(
                  labelText: l10n?.plateNumber ?? 'Plate Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceNumberController,
                decoration: InputDecoration(
                  labelText: l10n?.insuranceNumber ?? 'Insurance Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.verified_user),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submitDocuments,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n?.submit ?? 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    File? photo,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(photo, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
