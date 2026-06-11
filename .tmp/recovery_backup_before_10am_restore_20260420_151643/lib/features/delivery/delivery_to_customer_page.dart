import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
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
  final bool isPickup;
  final VoidCallback? onComplete;

  const DeliveryToCustomerPage({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    this.buildingNo,
    this.floorNo,
    this.apartmentNo,
    this.customerNotes,
    this.isPickup = false,
    this.onComplete,
  });

  @override
  State<DeliveryToCustomerPage> createState() => _DeliveryToCustomerPageState();
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

  void _onDeliveredTap() {
    if (!_canDeliver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.mustTakeBuildingPhotoWarning,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      context.go('/map-status');
    }
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
        title: Text(
          widget.isPickup ? l10n.pickup : l10n.deliverToCustomerTitle,
        ),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _hasClothesRelationship
                          ? Icons.check_circle
                          : Icons.cancel,
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.cantReachCustomer,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showCantReachDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.orange.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Help',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _callCustomer,
                  icon: const Icon(Icons.call, size: 20),
                  label: Text(l10n.call),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openMessages,
                  icon: const Icon(Icons.message_rounded, size: 20),
                  label: Text(l10n.messages),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary.withValues(alpha: 0.1),
                    foregroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepHeader(number: 2, title: l10n.step2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.step2Instruction,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _capturePhoto(isBuilding: true),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: _kPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.takePhoto,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_buildingPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPhotoSlider(_buildingPhotos, isBuilding: true),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepHeader(number: 3, title: l10n.step3Optional),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.step3Instruction,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _capturePhoto(isBuilding: false),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: _kPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.takePhoto,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_orderPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPhotoSlider(_orderPhotos, isBuilding: false),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo thumbnail grid
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSlider(List<XFile> photos, {required bool isBuilding}) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = photos[index];
          return Container(
            margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => _showImageViewer(entry.path),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(entry.path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () =>
                          _removePhoto(isBuilding: isBuilding, index: index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
              widget.isPickup ? l10n.confirmPickup : l10n.deliveredBtn,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
