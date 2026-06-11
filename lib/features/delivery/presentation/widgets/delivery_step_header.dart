import 'package:flutter/material.dart';

/// Step number + title row used on [DeliveryToCustomerPage].
class DeliveryStepHeader extends StatelessWidget {
  const DeliveryStepHeader({
    super.key,
    required this.number,
    required this.title,
  });

  final int number;
  final String title;

  static const Color _primary = Color(0xFF23C1B2);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
