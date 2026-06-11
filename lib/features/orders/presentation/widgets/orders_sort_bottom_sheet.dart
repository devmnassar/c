import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../models/orders_filters.dart';

Future<void> showOrdersSortBottomSheet({
  required BuildContext context,
  required AppLocalizations? l10n,
  required SortOption selectedSort,
  required ValueChanged<SortOption> onSortSelected,
}) {
  final theme = Theme.of(context);
  const primaryColor = Color(0xFF23C1B2);

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Text(
                l10n?.sort ?? 'Sort',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _SortTile(
              icon: Icons.near_me,
              title: 'Nearest',
              selected: selectedSort == SortOption.nearest,
              onTap: () {
                onSortSelected(SortOption.nearest);
                Navigator.pop(context);
              },
              primaryColor: primaryColor,
            ),
            _SortTile(
              icon: Icons.schedule,
              title: 'Fastest',
              selected: selectedSort == SortOption.fastestEta,
              onTap: () {
                onSortSelected(SortOption.fastestEta);
                Navigator.pop(context);
              },
              primaryColor: primaryColor,
            ),
            _SortTile(
              icon: Icons.new_releases,
              title: l10n?.newest ?? 'Newest',
              selected: selectedSort == SortOption.newest,
              onTap: () {
                onSortSelected(SortOption.newest);
                Navigator.pop(context);
              },
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.primaryColor,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? primaryColor : null),
      title: Text(title),
      trailing: selected ? Icon(Icons.check, color: primaryColor) : null,
      onTap: onTap,
    );
  }
}
