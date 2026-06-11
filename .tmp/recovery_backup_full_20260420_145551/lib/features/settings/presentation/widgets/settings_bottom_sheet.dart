import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../app.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeController = App.localeController;

    if (localeController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'settings'.tr ?? 'Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Language section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'language'.tr ?? 'Language',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Arabic option
                  ListenableBuilder(
                    listenable: localeController,
                    builder: (context, _) {
                      final currentLocale = localeController.locale;
                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text('arabic'.tr ?? 'Arabic'),
                        trailing: Radio<String>(
                          value: 'ar',
                          groupValue: currentLocale?.languageCode,
                          onChanged: (String? value) async {
                            if (value != null) {
                              await localeController
                                  .setLocale(const Locale('ar'));
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                        onTap: () async {
                          await localeController.setLocale(const Locale('ar'));
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                  // English option
                  ListenableBuilder(
                    listenable: localeController,
                    builder: (context, _) {
                      final currentLocale = localeController.locale;
                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text('english'.tr ?? 'English'),
                        trailing: Radio<String>(
                          value: 'en',
                          groupValue: currentLocale?.languageCode,
                          onChanged: (String? value) async {
                            if (value != null) {
                              await localeController
                                  .setLocale(const Locale('en'));
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                        onTap: () async {
                          await localeController.setLocale(const Locale('en'));
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Logout button
            ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'menuLogout'.tr ?? 'Logout',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('menuLogout'.tr ?? 'Logout'),
                    content: Text(
                      'logoutConfirmation'.tr ??
                          'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('cancel'.tr ?? 'Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: Text('menuLogout'.tr ?? 'Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  // Close bottom sheet first
                  Navigator.pop(context);

                  // Perform logout
                  await AuthService.logout();

                  // Navigate to login and clear all routes
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
