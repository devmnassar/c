import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Primary brand color matching the rest of the app.
const Color _kPrimary = Color(0xFF23C1B2);

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class ChatMsg {
  final String id;
  final bool isFromCustomer;
  final String? text;
  final String? imagePath;
  final DateTime time;

  const ChatMsg({
    required this.id,
    required this.isFromCustomer,
    this.text,
    this.imagePath,
    required this.time,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen customer chat.
///
/// Receives order & customer identifiers so the future API integration can
/// scope messages to the correct conversation.
class CustomerChatScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;

  const CustomerChatScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final List<ChatMsg> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _showQuickReplies = true;

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onInputChanged);
    _seedMockMessages();
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() {});

  // ------------------------------------------------------------------
  // Mock data – TODO: replace with API polling / websocket
  // ------------------------------------------------------------------

  void _seedMockMessages() {
    final now = DateTime.now();
    _messages.addAll([
      ChatMsg(
        id: '1',
        isFromCustomer: true,
        text: null, // filled at build-time via l10n
        time: now.subtract(const Duration(minutes: 30)),
      ),
      ChatMsg(
        id: '2',
        isFromCustomer: false,
        text: null, // filled at build-time via l10n
        time: now.subtract(const Duration(minutes: 25)),
      ),
    ]);
  }

  /// Localized text for mock messages (resolved at build-time).
  String _mockText(AppLocalizations l10n, String id) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    switch (id) {
      case '1':
        return isRtl
            ? 'اترك الملابس بدون تواصل'
            : 'Leave the clothes without contacting';
      case '2':
        return isRtl ? 'تم، حاضر' : 'Sure';
      default:
        return '';
    }
  }

  // ------------------------------------------------------------------
  // Canned / quick-reply messages
  // ------------------------------------------------------------------

  List<String> _cannedMessages(AppLocalizations l10n) => [
        l10n.cannedSure,
        l10n.cannedOnMyWay,
        l10n.cannedArrivingSoon,
        l10n.cannedShareLocation,
        l10n.cannedOrderPickedUp,
        l10n.cannedSendPhoto,
        l10n.cannedLeaveAtDoor,
      ];

  List<String> _filteredCanned(AppLocalizations l10n) {
    final q = _inputCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _cannedMessages(l10n);
    return _cannedMessages(l10n)
        .where((m) => m.toLowerCase().contains(q))
        .toList();
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  void _sendText(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMsg(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isFromCustomer: false,
        text: text.trim(),
        time: DateTime.now(),
      ));
    });
    _inputCtrl.clear();
    _showQuickReplies = true;
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null || !mounted) return;
      setState(() {
        _messages.add(ChatMsg(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isFromCustomer: false,
          imagePath: file.path,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } catch (_) {
      // Camera/gallery error – silently ignore for now
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callCustomer() async {
    final clean = widget.customerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showImageViewer(String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final filtered = _filteredCanned(l10n);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.customerChatSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.call),
              tooltip: l10n.call,
              onPressed: _callCustomer,
            ),
          ],
        ),
        body: Column(
          children: [
            // Message list
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) =>
                      _buildBubble(_messages[i], l10n, theme, isRtl),
                ),
              ),
            ),

            // Quick-reply chips
            if (_showQuickReplies && filtered.isNotEmpty)
              _buildQuickReplies(filtered, theme),

            // Composer
            _buildComposer(l10n, theme),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Message bubble
  // ------------------------------------------------------------------

  Widget _buildBubble(
    ChatMsg msg,
    AppLocalizations l10n,
    ThemeData theme,
    bool isRtl,
  ) {
    final isCourier = !msg.isFromCustomer;
    final displayText = msg.text ?? _mockText(l10n, msg.id);
    final hasImage = msg.imagePath != null && msg.imagePath!.isNotEmpty;

    final bubbleColor = isCourier
        ? _kPrimary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = theme.colorScheme.onSurface;

    final timeStr = _formatTime(msg.time);

    return Align(
      alignment: isCourier
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(16),
              topEnd: const Radius.circular(16),
              bottomStart: Radius.circular(isCourier ? 16 : 4),
              bottomEnd: Radius.circular(isCourier ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isCourier
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (hasImage)
                GestureDetector(
                  onTap: () => _showImageViewer(msg.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(msg.imagePath!),
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        height: 150,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.broken_image,
                            color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              if (hasImage && displayText.isNotEmpty)
                const SizedBox(height: 6),
              if (displayText.isNotEmpty)
                Text(
                  displayText,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ------------------------------------------------------------------
  // Quick-reply chips
  // ------------------------------------------------------------------

  Widget _buildQuickReplies(List<String> items, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: items.map((text) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ActionChip(
                label: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _kPrimary,
                  ),
                ),
                backgroundColor: _kPrimary.withValues(alpha: 0.08),
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  _inputCtrl.text = text;
                  _inputCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: text.length),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Composer (input bar)
  // ------------------------------------------------------------------

  Widget _buildComposer(AppLocalizations l10n, ThemeData theme) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Camera
            _ComposerAction(
              icon: Icons.camera_alt_outlined,
              tooltip: l10n.attachCamera,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            // Gallery
            _ComposerAction(
              icon: Icons.photo_outlined,
              tooltip: l10n.attachGallery,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 4),
            // Text field
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendText,
                onTap: () => setState(() => _showQuickReplies = true),
                decoration: InputDecoration(
                  hintText: l10n.typeMessage,
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            // Send
            Material(
              color: _kPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _sendText(_inputCtrl.text),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small composer action icon (camera / gallery)
// ---------------------------------------------------------------------------

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ComposerAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: _kPrimary, size: 24),
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
