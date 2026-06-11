import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/profile/document_draft_service.dart';
import '../../../../../../core/profile/profile_service.dart';

class SelfieDetailsPage extends StatefulWidget {
  static const String id = '/signup/documents/selfie';
  const SelfieDetailsPage({super.key});

  @override
  State<SelfieDetailsPage> createState() => _SelfieDetailsPageState();
}

class _SelfieDetailsPageState extends State<SelfieDetailsPage> {
  File? _photo;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final path = await DocumentDraftService.getSelfieDraft();
    if (path.isEmpty || !mounted) return;
    final file = File(path);
    if (await file.exists() && mounted) {
      setState(() => _photo = file);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _photo = File(pickedFile.path));
      await DocumentDraftService.saveSelfieDraft(_photo?.path);
    }
  }

  Future<void> _save() async {
    if (_photo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please take a selfie')));
      return;
    }

    await ProfileService.saveSelfie(_photo!.path);
    await DocumentDraftService.clearSelfieDraft();
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Selfie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Please take a clear selfie of yourself.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                    ),
                    child: _photo != null
                        ? ClipOval(
                            child: Image.file(_photo!, fit: BoxFit.cover),
                          )
                        : Icon(
                            Icons.face_outlined,
                            size: 80,
                            color: primaryColor,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
