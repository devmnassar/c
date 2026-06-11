import 'package:flutter/material.dart';

import 'custom_list_tile.dart';

class SettingsSelectionOption<T> {
  const SettingsSelectionOption({
    required this.value,
    required this.title,
    required this.icon,
  });

  final T value;
  final String title;
  final IconData icon;
}

class SettingsSelectionDialog<T> extends StatelessWidget {
  const SettingsSelectionDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<SettingsSelectionOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => CustomListTile(
                leading: Icon(option.icon),
                title: Text(option.title),
                trailing: selectedValue == option.value
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(option.value);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
