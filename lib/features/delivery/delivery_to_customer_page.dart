import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/dependency_injection.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import '../chat/customer_chat_screen.dart';
import '../orders/domain/models/order_checklist_question.dart';
import 'presentation/cubit/attempted_delivery_checklist_cubit.dart';
import 'presentation/cubit/delivery_completion_cubit.dart';
import 'presentation/widgets/delivery_checklist_error_banner.dart';
import 'presentation/widgets/delivery_checklist_question_card.dart';
import 'presentation/widgets/delivery_checklist_success_banner.dart';
import 'presentation/widgets/delivery_info_row.dart';
import 'presentation/widgets/delivery_section_card.dart';
import 'presentation/widgets/delivery_step_header.dart';

const Color _kPrimary = Color(0xFF23C1B2);

AppLocalizations _resolveL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (l10n != null) return l10n;

  final locale = Localizations.maybeLocaleOf(context);
  if (locale != null) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (supported) return lookupAppLocalizations(locale);
  }

  return lookupAppLocalizations(const Locale('en'));
}

class DeliveryToCustomerPage extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String? buildingNo;
  final String? floorNo;
  final String? apartmentNo;
  final String? customerNotes;
  final bool isPickup;
  final bool? customerHasHanger;
  final bool requireProofPhoto;
  final String? pickupConfirmButtonText;
  final Future<void> Function(String? proofPhotoPath)? onPickupConfirm;
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
    this.customerHasHanger,
    this.requireProofPhoto = true,
    this.pickupConfirmButtonText,
    this.onPickupConfirm,
    this.onComplete,
  });

  @override
  State<DeliveryToCustomerPage> createState() => _DeliveryToCustomerPageState();
}

class _DeliveryToCustomerPageState extends State<DeliveryToCustomerPage> {
  static const int _maxRequiredBuildingPhotos = 4;
  final ValueNotifier<List<XFile>> _buildingPhotosNotifier =
      ValueNotifier<List<XFile>>([]);
  final ValueNotifier<List<XFile>> _orderPhotosNotifier =
      ValueNotifier<List<XFile>>([]);
  final ImagePicker _picker = ImagePicker();
  late final DeliveryCompletionCubit _deliveryCompletionCubit;
  late final AttemptedDeliveryChecklistCubit _attemptedDeliveryChecklistCubit;
  final ValueNotifier<bool> _isPickupSubmittingNotifier = ValueNotifier<bool>(
    false,
  );

  List<XFile> get _buildingPhotos => _buildingPhotosNotifier.value;
  List<XFile> get _orderPhotos => _orderPhotosNotifier.value;
  bool get _isPickupSubmitting => _isPickupSubmittingNotifier.value;

  bool get _isProofPhotoRequired =>
      !widget.isPickup || widget.requireProofPhoto;

  bool get _canDeliver => !_isProofPhotoRequired || _buildingPhotos.isNotEmpty;
  bool get _isAnySubmitting =>
      _deliveryCompletionCubit.state.isSubmitting || _isPickupSubmitting;
  bool get _isAttemptingDelivery =>
      _deliveryCompletionCubit.state.isAttemptingDelivery;

  @override
  void initState() {
    super.initState();
    _deliveryCompletionCubit = getIt<DeliveryCompletionCubit>();
    _attemptedDeliveryChecklistCubit = getIt<AttemptedDeliveryChecklistCubit>();
  }

  @override
  void dispose() {
    _buildingPhotosNotifier.dispose();
    _orderPhotosNotifier.dispose();
    _isPickupSubmittingNotifier.dispose();
    _deliveryCompletionCubit.close();
    _attemptedDeliveryChecklistCubit.close();
    super.dispose();
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('================ DELIVERY SCREEN FLOW ================');
    debugPrint('[DELIVERY SCREEN FLOW] $message');
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _capturePhoto({required bool isBuilding}) async {
    if (isBuilding && _buildingPhotos.length >= _maxRequiredBuildingPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can add up to $_maxRequiredBuildingPhotos photos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (xFile == null) return;
    if (!mounted) return;
    if (isBuilding) {
      _buildingPhotosNotifier.value = [..._buildingPhotos, xFile];
    } else {
      _orderPhotosNotifier.value = [..._orderPhotos, xFile];
    }
  }

  void _removePhoto({required bool isBuilding, required int index}) {
    if (isBuilding) {
      final updated = [..._buildingPhotos]..removeAt(index);
      _buildingPhotosNotifier.value = updated;
    } else {
      final updated = [..._orderPhotos]..removeAt(index);
      _orderPhotosNotifier.value = updated;
    }
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

  Future<void> _handleHelpPressed() async {
    if (_isAnySubmitting || widget.isPickup) {
      return;
    }

    final loaded = await _attemptedDeliveryChecklistCubit.loadChecklist(
      orderId: widget.orderId,
    );
    if (!mounted) return;

    if (!loaded) {
      final message = _attemptedDeliveryChecklistCubit.state.errorMessage;
      if (message != null && message.trim().isNotEmpty) {
        AppSnackBar.showError(context, message);
      }
      return;
    }

    _showCantReachDialog();
  }

  void _showCantReachDialog() {
    final l10n = _resolveL10n(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: _attemptedDeliveryChecklistCubit,
        child:
            BlocBuilder<
              AttemptedDeliveryChecklistCubit,
              AttemptedDeliveryChecklistState
            >(
              builder: (context, checklistState) {
                final canAttemptDelivery =
                    !_isAnySubmitting &&
                    !widget.isPickup &&
                    checklistState.submitSuccess;
                final canSubmitChecklist =
                    checklistState.hasQuestions &&
                    checklistState.isComplete &&
                    !checklistState.isSubmitting;
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cantReachCustomer,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _checklistDescriptionText(context),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    height: 1.45,
                                  ),
                            ),
                            if (checklistState.errorMessage != null &&
                                checklistState.errorMessage!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              DeliveryChecklistErrorBanner(
                                message: checklistState.errorMessage!,
                              ),
                            ],
                            if (checklistState.submitSuccess) ...[
                              const SizedBox(height: 16),
                              const DeliveryChecklistSuccessBanner(),
                            ],
                            const SizedBox(height: 18),
                            if (!checklistState.hasQuestions)
                              Text(
                                _noChecklistQuestionsText(context),
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              ...checklistState.questions.map(
                                (question) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: DeliveryChecklistQuestionCard(
                                    questionNumber: question.displayOrder,
                                    questionText: _resolveChecklistQuestionText(
                                      context,
                                      question,
                                    ),
                                    answer: question.answer,
                                    yesLabel: l10n.yes,
                                    noLabel: l10n.no,
                                    onChanged: checklistState.isSubmitting
                                        ? null
                                        : (value) {
                                            _attemptedDeliveryChecklistCubit
                                                .answerQuestion(
                                                  questionId:
                                                      question.questionId,
                                                  answer: value,
                                                );
                                          },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: checklistState.isSubmitting
                                        ? null
                                        : () => Navigator.of(ctx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(l10n.close),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: canSubmitChecklist
                                        ? () => _submitChecklistAnswers(context)
                                        : checklistState.isSubmitting
                                        ? null
                                        : () =>
                                              _submitChecklistAnswers(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: checklistState.isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(l10n.submit),
                                  ),
                                ),
                              ],
                            ),
                            if (!widget.isPickup) ...[
                              const SizedBox(height: 12),
                              BlocBuilder<
                                DeliveryCompletionCubit,
                                DeliveryCompletionState
                              >(
                                bloc: _deliveryCompletionCubit,
                                builder: (context, deliveryState) {
                                  final isAttemptingDelivery =
                                      deliveryState.isAttemptingDelivery;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: canAttemptDelivery
                                          ? () =>
                                                _handleAttemptedDeliveryFromDialog(
                                                  ctx,
                                                )
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: canAttemptDelivery
                                            ? _kPrimary
                                            : Colors.grey.shade300,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: isAttemptingDelivery
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Attempted Delivery',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Future<void> _submitChecklistAnswers(BuildContext dialogContext) async {
    final success = await _attemptedDeliveryChecklistCubit.submitChecklist(
      orderId: widget.orderId,
    );
    if (!mounted || !success) {
      return;
    }

    AppSnackBar.showSuccess(
      dialogContext,
      _checklistSubmittedMessage(dialogContext),
    );
  }

  Future<void> _handleAttemptedDeliveryFromDialog(
    BuildContext dialogContext,
  ) async {
    if (!_attemptedDeliveryChecklistCubit.state.submitSuccess) {
      _attemptedDeliveryChecklistCubit.showLocalError(
        _submitChecklistFirstMessage(dialogContext),
      );
      return;
    }

    if (!_canDeliver) {
      _attemptedDeliveryChecklistCubit.showLocalError(
        _attemptedDeliveryPhotoRequiredMessage(dialogContext),
      );
      return;
    }

    await _onAttemptedDeliveryTap();
  }

  Future<void> _onDeliveredTap() async {
    if (_isAnySubmitting) return;
    _log(
      '_onDeliveredTap pressed. '
      'orderId=${widget.orderId}, isPickup=${widget.isPickup}, canDeliver=$_canDeliver',
    );
    if (!_canDeliver) {
      final l10n = _resolveL10n(context);
      _log('Delivered blocked because building photo is missing');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustTakeBuildingPhotoWarning),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await _showDeliveryConfirmationDialog();
    if (confirmed != true || !mounted) {
      _log('Delivered flow cancelled from confirmation dialog');
      return;
    }

    if (widget.isPickup) {
      final proofPhotoPath = _buildingPhotos.isNotEmpty
          ? _buildingPhotos.last.path
          : null;
      if (widget.onPickupConfirm != null) {
        _log(
          'Pickup completion path triggered with custom callback. '
          'proofPhotoPath=$proofPhotoPath',
        );
        _isPickupSubmittingNotifier.value = true;
        try {
          await widget.onPickupConfirm!(proofPhotoPath);
        } finally {
          if (mounted) {
            _isPickupSubmittingNotifier.value = false;
          }
        }
        return;
      }

      _log('Pickup completion path triggered without rider status update');
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        context.go('/map-status');
      }
      return;
    }

    final proofPhotoPath = _buildingPhotos.last.path;
    _log(
      'Submitting delivered flow through cubit. '
      'proofPhotoPath=$proofPhotoPath',
    );
    await _deliveryCompletionCubit.deliverOrder(
      orderId: widget.orderId,
      proofPhotoPath: proofPhotoPath,
    );
  }

  Future<void> _onAttemptedDeliveryTap() async {
    _log(
      '_onAttemptedDeliveryTap pressed. '
      'orderId=${widget.orderId}, isPickup=${widget.isPickup}, canDeliver=$_canDeliver',
    );
    if (!_canDeliver) {
      final l10n = _resolveL10n(context);
      _log('AttemptedDelivery blocked because building photo is missing');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustTakeBuildingPhotoWarning),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.isPickup) {
      _log('AttemptedDelivery ignored for pickup flow');
      return;
    }

    final proofPhotoPath = _buildingPhotos.last.path;
    _log(
      'Submitting attempted-delivery flow through cubit. '
      'proofPhotoPath=$proofPhotoPath',
    );
    await _deliveryCompletionCubit.attemptDelivery(
      orderId: widget.orderId,
      proofPhotoPath: proofPhotoPath,
    );
  }

  Future<bool?> _showDeliveryConfirmationDialog() {
    final l10n = _resolveL10n(context);
    final confirmationMessage = _deliveryConfirmationMessage(l10n);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: _kPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Confirm Action',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              if (confirmationMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  confirmationMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.confirm,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deliveryConfirmationMessage(AppLocalizations l10n) {
    if (widget.isPickup) {
      return '';
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'هل تريد تأكيد تسليم الطلب؟';
    }
    return 'Do you want to confirm delivering this order?';
  }

  void _handleDeliveryCubitState(
    BuildContext context,
    DeliveryCompletionState state,
  ) {
    if (state.status == DeliveryCompletionStatus.failure &&
        state.errorMessage != null &&
        state.errorMessage!.trim().isNotEmpty) {
      _log('Cubit emitted failure: ${state.errorMessage}');
      AppSnackBar.showError(context, state.errorMessage!);
      _deliveryCompletionCubit.reset();
      return;
    }

    if (state.status == DeliveryCompletionStatus.success) {
      _log('Cubit emitted success for orderId=${widget.orderId}');
      _deliveryCompletionCubit.reset();
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        context.go('/map-status');
      }
      return;
    }

    if (state.status == DeliveryCompletionStatus.submitting) {
      _log('Cubit emitted submitting');
      return;
    }

    if (state.status == DeliveryCompletionStatus.initial) {
      _log('Cubit emitted initial');
    }
  }

  Widget _buildPage(BuildContext context, DeliveryCompletionState state) {
    final l10n = _resolveL10n(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToMapStatus();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 16,
          title: Text(
            widget.isPickup ? l10n.pickup : l10n.deliverToCustomerTitle,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
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
      ),
    );
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

  void _showSelectedPhotos(List<XFile> photos, {required String title}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${photos.length}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _kPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: photos.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => _showImageViewer(photo.path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(photo.path), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackToMapStatus() async {
    if (!mounted) return false;
    _log('Back navigation intercepted -> routing to map-status');
    context.go('/map-status');
    return false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _deliveryCompletionCubit),
        BlocProvider.value(value: _attemptedDeliveryChecklistCubit),
      ],
      child: BlocConsumer<DeliveryCompletionCubit, DeliveryCompletionState>(
        listener: _handleDeliveryCubitState,
        builder: _buildPage,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Clothes relationship card
  // ---------------------------------------------------------------------------

  Widget _buildClothesCard(AppLocalizations l10n, ThemeData theme) {
    final hasClothesHanger = widget.customerHasHanger ?? false;

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
                      hasClothesHanger ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: hasClothesHanger ? _kPrimary : Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasClothesHanger ? '✓' : '✗',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasClothesHanger
                            ? _kPrimary
                            : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
                if (!hasClothesHanger) ...[
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
    return DeliverySectionCard(
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
          DeliveryInfoRow(label: 'Customer Name', value: widget.customerName),
          DeliveryInfoRow(label: l10n.buildingNo, value: widget.buildingNo),
          DeliveryInfoRow(label: l10n.floorNo, value: widget.floorNo),
          DeliveryInfoRow(label: l10n.apartmentNo, value: widget.apartmentNo),
          const Divider(height: 20),
          Text(
            l10n.customerNotes,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.customerNotes != null && widget.customerNotes!.isNotEmpty)
            Text(widget.customerNotes!, style: theme.textTheme.bodyMedium)
          else
            SizedBox(
              height: 20,
              child: Text('', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 – contact the customer
  // ---------------------------------------------------------------------------

  Widget _buildStep1(AppLocalizations l10n, ThemeData theme) {
    return DeliverySectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeliveryStepHeader(number: 1, title: l10n.step1),
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
                BlocBuilder<
                  AttemptedDeliveryChecklistCubit,
                  AttemptedDeliveryChecklistState
                >(
                  bloc: _attemptedDeliveryChecklistCubit,
                  builder: (context, checklistState) {
                    return TextButton(
                      onPressed: checklistState.isLoading
                          ? null
                          : _handleHelpPressed,
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
                      child: checklistState.isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange.shade800,
                                ),
                              ),
                            )
                          : Text(
                              l10n.help,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                    );
                  },
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

  String _resolveChecklistQuestionText(
    BuildContext context,
    OrderChecklistQuestion question,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar' && question.textAr.trim().isNotEmpty) {
      return question.textAr;
    }
    if (question.textEn.trim().isNotEmpty) {
      return question.textEn;
    }
    return question.textAr;
  }

  String _checklistDescriptionText(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'أجب على كل الأسئلة أولاً ثم اضغط إرسال قبل تنفيذ محاولة التسليم.';
    }
    return 'Answer all checklist questions, submit them first, then continue with attempted delivery.';
  }

  String _submitChecklistFirstMessage(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'يجب إرسال الإجابات أولاً قبل تنفيذ محاولة التسليم.';
    }
    return 'Please submit the checklist before attempting delivery.';
  }

  String _checklistSubmittedMessage(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'تم إرسال الإجابات بنجاح. يمكنك الآن تنفيذ محاولة التسليم.';
    }
    return 'Checklist submitted successfully. You can now attempt delivery.';
  }

  String _attemptedDeliveryPhotoRequiredMessage(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'لازم ترفع صور الإثبات أولاً قبل تنفيذ Attempted Delivery.';
    }
    return 'Please upload the proof photos first before attempting delivery.';
  }

  String _noChecklistQuestionsText(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'لا توجد أسئلة متاحة حاليًا لهذه الحالة.';
    }
    return 'No checklist questions are available for this order right now.';
  }

  // ---------------------------------------------------------------------------
  // Step 2 – building proof photos (mandatory)
  // ---------------------------------------------------------------------------

  Widget _buildStep2(AppLocalizations l10n, ThemeData theme) {
    return ValueListenableBuilder<List<XFile>>(
      valueListenable: _buildingPhotosNotifier,
      builder: (context, buildingPhotos, _) {
        final proofRequired = _isProofPhotoRequired;
        final canAddMorePhotos =
            buildingPhotos.length < _maxRequiredBuildingPhotos;
        return DeliverySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DeliveryStepHeader(number: 2, title: l10n.step2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: proofRequired
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: proofRequired
                            ? Colors.red.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      proofRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        color: proofRequired
                            ? Colors.red.shade700
                            : Colors.grey.shade600,
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
                onTap: canAddMorePhotos
                    ? () => _capturePhoto(isBuilding: true)
                    : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: canAddMorePhotos
                        ? _kPrimary.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canAddMorePhotos
                          ? _kPrimary.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        color: canAddMorePhotos
                            ? _kPrimary
                            : Colors.grey.shade500,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        canAddMorePhotos
                            ? l10n.takePhoto
                            : 'Maximum $_maxRequiredBuildingPhotos photos reached',
                        style: TextStyle(
                          color: canAddMorePhotos
                              ? _kPrimary
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (buildingPhotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showSelectedPhotos(
                      buildingPhotos,
                      title: 'Selected proof photos',
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      'View selected photos (${buildingPhotos.length})',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _kPrimary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPhotoSlider(buildingPhotos, isBuilding: true),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 – order photos (optional)
  // ---------------------------------------------------------------------------

  Widget _buildStep3(AppLocalizations l10n, ThemeData theme) {
    return ValueListenableBuilder<List<XFile>>(
      valueListenable: _orderPhotosNotifier,
      builder: (context, orderPhotos, _) {
        return DeliverySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DeliveryStepHeader(number: 3, title: l10n.step3Optional),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
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
              if (orderPhotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showSelectedPhotos(
                      orderPhotos,
                      title: 'Selected order photos',
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text('View selected photos (${orderPhotos.length})'),
                    style: TextButton.styleFrom(
                      foregroundColor: _kPrimary,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPhotoSlider(orderPhotos, isBuilding: false),
              ],
            ],
          ),
        );
      },
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
    return ValueListenableBuilder<List<XFile>>(
      valueListenable: _buildingPhotosNotifier,
      builder: (context, photos, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isPickupSubmittingNotifier,
          builder: (context, isPickupSubmitting, _) {
            final isSubmitting =
                _deliveryCompletionCubit.state.isDelivering ||
                isPickupSubmitting;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (!isSubmitting && _canDeliver)
                            ? _onDeliveredTap
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _canDeliver
                              ? _kPrimary
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.isPickup
                                    ? (widget.pickupConfirmButtonText ??
                                          l10n.confirmPickup)
                                    : l10n.deliveredBtn,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
