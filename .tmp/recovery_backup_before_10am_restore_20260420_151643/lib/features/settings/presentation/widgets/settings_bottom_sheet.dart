import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../app.dart';
import 'custom_list_tile.dart';

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
                      l10n?.settings ?? 'Settings',
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      l10n?.language ?? 'Language',
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
                      return CustomListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n?.arabic ?? 'Arabic'),
                        trailing: Radio<String>(
                          value: 'ar',
                          groupValue: currentLocale?.languageCode,
                          onChanged: (String? value) {
                            if (value != null) {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              localeController.setLocale(const Locale('ar'));
                            }
                          },
                        ),
                        onTap: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          localeController.setLocale(const Locale('ar'));
                        },
                      );
                    },
                  ),
                  // English option
                  ListenableBuilder(
                    listenable: localeController,
                    builder: (context, _) {
                      final currentLocale = localeController.locale;
                      return CustomListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n?.english ?? 'English'),
                        trailing: Radio<String>(
                          value: 'en',
                          groupValue: currentLocale?.languageCode,
                          onChanged: (String? value) {
                            if (value != null) {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              localeController.setLocale(const Locale('en'));
                            }
                          },
                        ),
                        onTap: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          localeController.setLocale(const Locale('en'));
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Logout button
            CustomListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                l10n?.menuLogout ?? 'Logout',
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
                    title: Text(l10n?.menuLogout ?? 'Logout'),
                    content: Text(
                      l10n?.logoutConfirmation ??
                          'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: Text(l10n?.menuLogout ?? 'Logout'),
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
