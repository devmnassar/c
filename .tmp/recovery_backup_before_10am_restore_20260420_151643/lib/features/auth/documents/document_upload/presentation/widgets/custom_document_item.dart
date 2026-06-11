import 'package:flutter/material.dart';

class CustomDocumentItem extends StatelessWidget {
  const CustomDocumentItem({
    super.key,
    required this.title,
    required this.isDone,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final bool isDone;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final subtitleColor = isDone ? primaryColor : Colors.grey[400];
    final subtitleWeight = isDone ? FontWeight.w600 : FontWeight.normal;
    final leadingBackground =
        isDone ? primaryColor.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
    final trailingIcon =
        isDone ? Icons.check_circle_rounded : Icons.chevron_right_rounded;
    final trailingColor = isDone ? primaryColor : Colors.grey[300];
    final leadingIconColor = isDone ? primaryColor : Colors.grey[400];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: leadingIconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF374151),
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            isDone ? 'Completed' : 'Tap to upload',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: subtitleWeight,
            ),
          ),
        ),
        trailing: Icon(
          trailingIcon,
          color: trailingColor,
          size: 24,
        ),
      ),
    );
  }
}