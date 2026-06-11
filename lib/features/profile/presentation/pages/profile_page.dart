import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  static const String id = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ProfileService.getProfile();
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, theme, l10n, primaryColor),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(theme, l10n),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          theme,
                          l10n?.personalInfo ?? 'Personal Information',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(theme, [
                          _buildInfoRow(
                            theme,
                            Icons.person_outline,
                            l10n?.fullName ?? 'Full Name',
                            _profileData?['fullName'] ?? 'Courier User',
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.phone_outlined,
                            l10n?.phoneNumberLabel ?? 'Phone Number',
                            _profileData?['mobileNumber'] ?? '+966 50 000 0000',
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.badge_outlined,
                            l10n?.nationalId ?? 'National ID',
                            _profileData?['nationalId'] ?? '1234567890',
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          theme,
                          l10n?.vehicleDetails ?? 'Vehicle Details',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(theme, [
                          _buildInfoRow(
                            theme,
                            Icons.directions_car_outlined,
                            l10n?.vehicleType ?? 'Brand',
                            _profileData?['vehicleBrand'] ?? 'Toyota',
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.pin_outlined,
                            l10n?.plateNumber ?? 'Plate Number',
                            _profileData?['vehiclePlateNumber'] ?? '1234 ABC',
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          theme,
                          l10n?.documents ?? 'Documents',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(theme, [
                          _buildDocRow(
                            theme,
                            Icons.assignment_ind_outlined,
                            l10n?.nationalIdCard ?? 'Iqama / National ID',
                            true,
                          ),
                          _buildDocRow(
                            theme,
                            Icons.drive_eta_outlined,
                            l10n?.drivingLicense ?? 'Driving License',
                            true,
                          ),
                          _buildDocRow(
                            theme,
                            Icons.description_outlined,
                            'Vehicle Registration',
                            true,
                          ),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    Color primaryColor,
  ) {
    final photoPath = _profileData?['photoPath'];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile_photo',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage:
                          photoPath != null ? FileImage(File(photoPath)) : null,
                      child: photoPath == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _profileData?['fullName'] ?? 'Courier User',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Verified Courier',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatsRow(ThemeData theme, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, '128', 'Deliveries'),
          _buildDivider(),
          _buildStatItem(
            theme,
            '4.9',
            'Rating',
            icon: Icons.star,
            iconColor: Colors.amber,
          ),
          _buildDivider(),
          _buildStatItem(theme, '2.5y', 'Experience'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFE5E7EB));
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < children.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocRow(
    ThemeData theme,
    IconData icon,
    String title,
    bool verified,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          if (verified)
            const Icon(Icons.check_circle, size: 20, color: Color(0xFF10B981))
          else
            const Icon(Icons.info_outline, size: 20, color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}
