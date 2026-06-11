import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../chat/customer_chat_screen.dart';

const Color _kPrimary = Color(0xFF23C1B2);

class DeliveryToCustomerPage extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String? buildingNo;
  final String? floorNo;
  final String? apartmentNo;
  final String? customerNotes;

  const DeliveryToCustomerPage({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    this.buildingNo,
    this.floorNo,
    this.apartmentNo,
    this.customerNotes,
  });

  @override
  State<DeliveryToCustomerPage> createState() =>
      _DeliveryToCustomerPageState();
}

class _DeliveryToCustomerPageState extends State<DeliveryToCustomerPage> {
  final bool _hasClothesRelationship = false; // TODO: wire from backend
  final List<XFile> _buildingPhotos = [];
  final List<XFile> _orderPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool get _canDeliver => _buildingPhotos.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _capturePhoto({required bool isBuilding}) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (xFile == null) return;
    setState(() {
      if (isBuilding) {
        _buildingPhotos.add(xFile);
      } else {
        _orderPhotos.add(xFile);
      }
    });
  }

  void _removePhoto({required bool isBuilding, required int index}) {
    setState(() {
      if (isBuilding) {
        _buildingPhotos.removeAt(index);
      } else {
        _orderPhotos.removeAt(index);
      }
    });
  }

  void _callCustomer() {
    final phone = widget.customerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('tel:$phone'));
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerChatScreen(
          orderId: widget.orderId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
        ),
      ),
    );
  }

  void _showCantReachDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cantReachCustomer),
        content: Text(l10n.comingSoon),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showSamplePhotos() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.samplePhotosTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
              4,
              // TODO: replace placeholders with real sample images from backend
              (i) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment, size: 40, color: Colors.grey.shade500),
                    const SizedBox(height: 4),
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _onDeliveredTap() {
    if (!_canDeliver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mustTakeBuildingPhotoWarning),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // TODO: send delivery confirmation + photos to API
    context.go('/map-status');
  }

  void _showImageViewer(String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliverToCustomerTitle),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClothesCard(l10n, theme),
            const SizedBox(height: 16),
            _buildBuildingCard(l10n, theme),
            const SizedBox(height: 20),
            Text(
              l10n.followSteps,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStep1(l10n, theme),
            const SizedBox(height: 12),
            _buildStep2(l10n, theme),
            const SizedBox(height: 12),
            _buildStep3(l10n, theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(l10n),
    );
  }

  // ---------------------------------------------------------------------------
  // Clothes relationship card
  // ---------------------------------------------------------------------------

  Widget _buildClothesCard(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withAlpha(15),
        border: Border.all(color: _kPrimary.withAlpha(51)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.checkroom, color: _kPrimary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.clothesRelationshipQ,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _hasClothesRelationship ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _hasClothesRelationship
                          ? _kPrimary
                          : Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasClothesRelationship ? '✓' : '✗',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _hasClothesRelationship
                            ? _kPrimary
                            : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
                if (!_hasClothesRelationship) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.faceToFaceDelivery,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Building info card
  // ---------------------------------------------------------------------------

  Widget _buildBuildingCard(AppLocalizations l10n, ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: _kPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.buildingPanelTitle,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          _InfoRow(label: l10n.buildingNo, value: widget.buildingNo),
          _InfoRow(label: l10n.floorNo, value: widget.floorNo),
          _InfoRow(label: l10n.apartmentNo, value: widget.apartmentNo),
          if (widget.customerNotes != null &&
              widget.customerNotes!.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              l10n.customerNotes,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.customerNotes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 – contact the customer
  // ---------------------------------------------------------------------------

  Widget _buildStep1(AppLocalizations l10n, ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(number: 1, title: l10n.step1),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: _showCantReachDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      l10n.cantReachCustomer,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callCustomer,
                  icon: const Icon(Icons.call, size: 18),
                  label: Text(l10n.call),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMessages,
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: Text(l10n.messages),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 – building proof photos (mandatory)
  // ---------------------------------------------------------------------------

  Widget _buildStep2(AppLocalizations l10n, ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(number: 2, title: l10n.step2),
          const SizedBox(height: 8),
          Text(
            l10n.step2Instruction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: _showSamplePhotos,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 18, color: _kPrimary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.previousPhotoExamples,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _capturePhoto(isBuilding: true),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(l10n.takePhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_buildingPhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPhotoGrid(_buildingPhotos, isBuilding: true),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 – order photos (optional)
  // ---------------------------------------------------------------------------

  Widget _buildStep3(AppLocalizations l10n, ThemeData theme) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(number: 3, title: l10n.step3Optional),
          const SizedBox(height: 8),
          Text(
            l10n.step3Instruction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _capturePhoto(isBuilding: false),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(l10n.takePhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_orderPhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPhotoGrid(_orderPhotos, isBuilding: false),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo thumbnail grid
  // ---------------------------------------------------------------------------

  Widget _buildPhotoGrid(List<XFile> photos, {required bool isBuilding}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photos.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () => _showImageViewer(entry.value.path),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(entry.value.path),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _removePhoto(
                    isBuilding: isBuilding,
                    index: entry.key,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar – delivered button
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _onDeliveredTap,
            style: FilledButton.styleFrom(
              backgroundColor: _canDeliver ? _kPrimary : Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.deliveredBtn,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int number;
  final String title;
  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
