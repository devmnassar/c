import 'package:flutter/material.dart';

import 'custom_list_tile.dart';

class SettingsPreferenceTile extends StatelessWidget {
  const SettingsPreferenceTile({
    super.key,
    required this.listenable,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Listenable listenable;
  final Widget leading;
  final Widget title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        return CustomListTile(
          leading: leading,
          title: title,
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }
}
