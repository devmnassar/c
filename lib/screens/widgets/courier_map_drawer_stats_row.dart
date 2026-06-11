import 'package:flutter/material.dart';

/// Static Income / Orders stats row in the map-status navigation drawer.
class CourierMapDrawerStatsRow extends StatelessWidget {
  const CourierMapDrawerStatsRow({
    super.key,
    required this.theme,
    required this.incomeLabel,
    required this.ordersLabel,
    this.incomeAmount = 'SAR 0.00',
    this.ordersCount = '0',
  });

  final ThemeData theme;
  final String incomeLabel;
  final String ordersLabel;
  final String incomeAmount;
  final String ordersCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                incomeAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(incomeLabel, style: theme.textTheme.bodySmall),
            ],
          ),
          Column(
            children: [
              Text(
                ordersCount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(ordersLabel, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
