import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gaseel_courier/features/orders/presentation/widgets/drawer_tile.dart';

import '../../../../l10n/app_localizations.dart';

class OrdersDrawer extends StatelessWidget {
  const OrdersDrawer({
    super.key,
    required this.theme,
    required this.l10n,
    required this.profilePhoto,
    required this.courierOnline,
    required this.onCourierOnlineChanged,
    required this.availabilityBusy,
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.onOrdersTap,
    required this.onSettingsTap,
    required this.onComingSoonTap,
    required this.onLogoutTap,
  });

  final ThemeData theme;
  final AppLocalizations? l10n;
  final File? profilePhoto;
  final bool courierOnline;
  final ValueChanged<bool> onCourierOnlineChanged;
  final bool availabilityBusy;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onComingSoonTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onProfileTap,
                    child: Column(
                      children: [
                        Hero(
                          tag: 'profile_photo',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: profilePhoto != null
                                ? FileImage(profilePhoto!)
                                : null,
                            child: profilePhoto == null
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Courier',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    courierOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              courierOnline
                                  ? (l10n?.drawerStatusOnline ?? 'Online')
                                  : (l10n?.drawerStatusOffline ?? 'Offline'),
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: courierOnline,
                              onChanged: availabilityBusy
                                  ? null
                                  : onCourierOnlineChanged,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: GestureDetector(
                      onTap: onNotificationsTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              size: 24,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5252),
                                    Color(0xFFD32F2F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '+11',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  DrawerTile(
                    theme: theme,
                    title: l10n?.profile ?? 'Profile',
                    icon: Icons.person_outline,
                    onTap: onProfileTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.drawerOrders ?? 'Orders',
                    icon: Icons.receipt_long_outlined,
                    onTap: onOrdersTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.promotion ?? 'Promotion',
                    icon: Icons.campaign_outlined,
                    onTap: onComingSoonTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.inbox ?? 'Inbox',
                    icon: Icons.inbox_outlined,
                    onTap: onComingSoonTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.appealCentre ?? 'Appeal Centre',
                    icon: Icons.gavel_outlined,
                    onTap: onComingSoonTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.tutorialCentre ?? 'Tutorial Centre',
                    icon: Icons.school_outlined,
                    onTap: onComingSoonTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.contactCs ?? 'Contact CS',
                    icon: Icons.support_agent_outlined,
                    onTap: onComingSoonTap,
                  ),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.menuSettings ?? 'Settings',
                    icon: Icons.settings_outlined,
                    onTap: onSettingsTap,
                  ),
                  const Divider(height: 24),
                  DrawerTile(
                    theme: theme,
                    title: l10n?.menuLogout ?? 'Logout',
                    icon: Icons.logout,
                    onTap: onLogoutTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
