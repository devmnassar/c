import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/order.dart';
import '../../../../l10n/app_localizations.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String? distance;
  final String? eta;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.distance,
    this.eta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.area}, ${order.district}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy • HH:mm',
                          ).format(order.scheduledDateTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTypeBadge(context, l10n),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, l10n),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(order.customerName, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  if (distance != null || eta != null) ...[
                    if (distance != null) ...[
                      Icon(
                        Icons.straighten,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(distance!, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                    ],
                    if (eta != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(eta!, style: theme.textTheme.bodySmall),
                    ],
                  ] else ...[
                    Text(
                      '--',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, AppLocalizations? l10n) {
    final theme = Theme.of(context);
    final isPickup = order.orderType == OrderType.pickup;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPickup
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPickup ? (l10n?.pickup ?? 'Pickup') : (l10n?.dropoff ?? 'Dropoff'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPickup
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations? l10n) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (order.status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade700;
        statusText = l10n?.pending ?? 'Pending';
        break;
      case OrderStatus.inProgress:
        backgroundColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue.shade700;
        statusText = l10n?.inProgress ?? 'In Progress';
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green.shade700;
        statusText = l10n?.completed ?? 'Completed';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red.shade700;
        statusText = l10n?.cancelled ?? 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
