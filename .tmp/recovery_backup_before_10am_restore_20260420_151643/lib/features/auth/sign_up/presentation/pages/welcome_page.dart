import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/documents/document_upload/presentation/pages/document_upload_page.dart';
import 'package:gaseel_courier/features/settings/presentation/widgets/settings_bottom_sheet.dart';

class WelcomePage extends StatelessWidget {
  static const String id = '/signup/welcome';

  const WelcomePage({super.key});

  Future<void> _openMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const SettingsBottomSheet(
          showLanguageSection: false,
          title: 'Menu',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 56,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: primaryColor),
                  ),
                  Positioned(
                    top: 4,
                    left: 8,
                    child: IconButton(
                      onPressed: () => _openMenu(context),
                      icon: const Icon(
                        Icons.menu,
                        size: 30,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: 'logo',
                      child: Container(
                        width: 136,
                        height: 136,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -74,
                    left: -30,
                    right: -30,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.elliptical(600, 180),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -96,
                    left: -26,
                    right: -26,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                     //   color: accentColor.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.elliptical(600, 180),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 44,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF3F4F6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 60),
                          const Text(
                            'Ready to join Gaseel Express?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: Color(0xFF111827),
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Start your courier registration by tapping the button below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              height: 1.35,
                            ),
                          ),
                          const Spacer(),
                          CustomButton(
                            text: 'Continue',
                            fullWidth: true,
                            onPressed: () async {
                              context.go(DocumentUploadPage.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
