import 'package:flutter/material.dart';

/// Single navigation drawer menu row on the map-status screen.
class CourierMapDrawerTile extends StatelessWidget {
  const CourierMapDrawerTile({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      onTap: onTap,
    );
  }
}
