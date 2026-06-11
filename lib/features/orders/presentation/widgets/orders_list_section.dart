import 'package:flutter/material.dart';

import '../../domain/models/order_mock.dart';

class OrdersListSection extends StatelessWidget {
  const OrdersListSection({
    super.key,
    required this.orders,
    required this.hasInProgressOrders,
    required this.showActiveTaskSection,
    required this.remainingSectionTitle,
    required this.onRefresh,
    required this.cardBuilder,
    required this.emptyState,
  });

  final List<OrderMock> orders;
  final bool hasInProgressOrders;
  final bool showActiveTaskSection;
  final String remainingSectionTitle;
  final Future<void> Function() onRefresh;
  final Widget Function(OrderMock order, bool isActive) cardBuilder;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return emptyState;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          if (showActiveTaskSection && hasInProgressOrders) ...[
            const Text(
              'ACTIVE TASK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            ...orders
                .where((o) => o.status == OrderStatusMock.inProgress)
                .map((order) => cardBuilder(order, true)),
            const SizedBox(height: 24),
          ],
          if (!showActiveTaskSection) ...[
            Text(
              remainingSectionTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            ...orders.map(
              (order) => cardBuilder(
                order,
                order.status == OrderStatusMock.inProgress,
              ),
            ),
          ] else if (orders
              .any((o) => o.status != OrderStatusMock.inProgress)) ...[
            Text(
              remainingSectionTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            ...orders
                .where((o) => o.status != OrderStatusMock.inProgress)
                .map((order) => cardBuilder(order, false)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
