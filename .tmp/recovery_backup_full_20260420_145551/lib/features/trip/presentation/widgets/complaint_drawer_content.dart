import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Complaint form for Help drawer: text input, photos, submit.
class ComplaintDrawerContent extends StatefulWidget {
  const ComplaintDrawerContent({super.key});

  @override
  State<ComplaintDrawerContent> createState() => _ComplaintDrawerContentState();
}

class _ComplaintDrawerContentState extends State<ComplaintDrawerContent> {
  final _controller = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _images = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final pick = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pick != null && mounted && _images.length < 5) {
        setState(() => _images.add(pick));
      }
    } catch (e) {
      developer.log('ComplaintDrawerContent pickImage camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picks = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: 5 - _images.length,
      );
      if (!mounted) return;
      setState(() {
        for (final x in picks) {
          if (_images.length < 5) {
            _images.add(x);
          }
        }
      });
    } catch (e) {
      developer.log('ComplaintDrawerContent pickMultiImage: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _images.removeAt(index));
  }

  void _submit() {
    final text = _controller.text.trim();
    developer.log(
      'Complaint submitted: text=${text.length} chars, images=${_images.length}',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.complaintSubmitted),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.complaintTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.complaintHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.addPhotos,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _images.length < 5 ? _takePhoto : null,
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: Text(l10n.takePhoto),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _images.length < 5 ? _pickFromGallery : null,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: Text(l10n.chooseFromGallery),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.asMap().entries.map((e) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _ThumbnailImage(xfile: e.value),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(e.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays image thumbnail using XFile.readAsBytes (works on all platforms).
class _ThumbnailImage extends StatelessWidget {
  final XFile xfile;

  const _ThumbnailImage({required this.xfile});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: xfile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          );
        }
        return Container(
          width: 72,
          height: 72,
          color: Colors.grey.shade300,
          child: Icon(Icons.image, color: Colors.grey.shade600),
        );
      },
    );
  }
}
