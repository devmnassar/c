import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order_mock.dart';

class MockOrderCard extends StatefulWidget {
  const MockOrderCard({
    super.key,
    required this.order,
    required this.l10n,
    required this.primaryColor,
    required this.onOpenActiveTrip,
    required this.onOpenHistory,
    required this.onMarkCompleted,
    this.isActive = false,
  });

  final OrderMock order;
  final AppLocalizations? l10n;
  final Color primaryColor;
  final bool isActive;
  final VoidCallback onOpenActiveTrip;
  final VoidCallback onOpenHistory;
  final VoidCallback onMarkCompleted;

  @override
  State<MockOrderCard> createState() => _MockOrderCardState();
}

class _MockOrderCardState extends State<MockOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPickup = order.type == OrderTypeMock.pickup;
    final isHistoryOrder = order.status == OrderStatusMock.completed ||
        order.status == OrderStatusMock.attemptedDelivery;

    final statusMeta = _statusMeta(order.status);
    final startTimeStr = DateFormat('HH:mm').format(order.scheduledAt);
    final endTimeStr = DateFormat(
      'HH:mm',
    ).format(order.scheduledAt.add(const Duration(minutes: 20)));
    final scheduledTime = '$startTimeStr - $endTimeStr';
    final pickupTimeText = order.pickupTime != null
        ? DateFormat('dd MMM, hh:mm a').format(order.pickupTime!)
        : null;
    final deliveryTimeText = order.deliveryTime != null
        ? DateFormat('dd MMM, hh:mm a').format(order.deliveryTime!)
        : null;

    final timePills = <Widget>[
      if (pickupTimeText != null)
        _DetailPill(
          icon: Icons.schedule_outlined,
          label: 'Pickup $pickupTimeText',
        ),
      if (pickupTimeText != null && deliveryTimeText != null)
        SizedBox(height: 8.h),
      if (deliveryTimeText != null)
        _DetailPill(
          icon: Icons.local_shipping_outlined,
          label: 'Delivery $deliveryTimeText',
        ),
    ];

    final itemCount =
        order.orderItems?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
    final isCash = order.isCash ?? true;
    final displayId = order.orderNumber ?? order.id;
    final pickupAddress = order.sourceAddress?.trim().isNotEmpty == true
        ? order.sourceAddress!
        : '${order.customerName} - ${order.district}, ${order.area}';
    final dropoffAddress = order.targetAddress?.trim().isNotEmpty == true
        ? order.targetAddress!
        : (order.laundryName ?? '');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: widget.isActive
            ? Border.all(
                color: widget.primaryColor.withValues(alpha: 0.3),
                width: 2.w,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.isActive
                ? widget.primaryColor.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => isHistoryOrder
              ? widget.onOpenHistory()
              : widget.onOpenActiveTrip(),
          borderRadius: BorderRadius.circular(24.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$displayId',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isPickup
                                ? Colors.amber.shade100
                                : widget.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            isPickup
                                ? (widget.l10n?.pickup ?? 'Pickup')
                                : (widget.l10n?.delivery ?? 'Delivery'),
                            style: TextStyle(
                              color: isPickup
                                  ? Colors.amber.shade900
                                  : widget.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onLongPress: () {
                            if (!isHistoryOrder) {
                              widget.onMarkCompleted();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusMeta.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              statusMeta.label,
                              style: TextStyle(
                                color: statusMeta.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (pickupTimeText != null || deliveryTimeText != null) ...[
                  Column(children: timePills),
                  SizedBox(height: 16.h),
                ],
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: isHistoryOrder
                            ? Colors.grey[50]
                            : widget.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        isPickup
                            ? Icons.local_shipping_outlined
                            : Icons.inventory_2_outlined,
                        color: isHistoryOrder
                            ? Colors.grey[400]
                            : widget.primaryColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6.h),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isExpanded = !_isExpanded);
                            },
                            child: Row(
                              children: [
                                Text(
                                  _isExpanded ? 'Hide Address' : 'Show Address',
                                  style: TextStyle(
                                    color: widget.primaryColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: widget.primaryColor,
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                          if (_isExpanded)
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup Address:',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    pickupAddress,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Dropoff Address:',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    dropoffAddress,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isHistoryOrder)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Time: $scheduledTime',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!isHistoryOrder) ...[
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      _CompactInfo(
                        icon: Icons.payments_outlined,
                        label: isCash ? 'CASH' : 'ONLINE',
                        color: isCash ? Colors.green[600]! : Colors.blue[600]!,
                      ),
                      SizedBox(width: 12.w),
                      _CompactInfo(
                        icon: Icons.shopping_bag_outlined,
                        label: '$itemCount ITEMS',
                        color: Colors.grey[600]!,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: widget.primaryColor,
                        size: 24.sp,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OrderStatusMeta _statusMeta(OrderStatusMock status) {
    switch (status) {
      case OrderStatusMock.newOrder:
        return const _OrderStatusMeta(
          color: Color(0xFFF59E0B),
          label: 'New Order',
        );
      case OrderStatusMock.assigned:
        return const _OrderStatusMeta(
          color: Color(0xFF8B5CF6),
          label: 'Assigned Order',
        );
      case OrderStatusMock.inProgress:
        return const _OrderStatusMeta(
          color: Color(0xFF3B82F6),
          label: 'Inprogress Order',
        );
      case OrderStatusMock.attemptedDelivery:
        return const _OrderStatusMeta(
          color: Color(0xFFF97316),
          label: 'Attempted Delivery Order',
        );
      case OrderStatusMock.completed:
        return const _OrderStatusMeta(
          color: Color(0xFF6B7280),
          label: 'Delivered Order',
        );
      case OrderStatusMock.cancelled:
        return const _OrderStatusMeta(
          color: Color(0xFFEF4444),
          label: 'Cancelled Order',
        );
      case OrderStatusMock.unknown:
        return const _OrderStatusMeta(
          color: Color(0xFF9CA3AF),
          label: 'Unknown',
        );
    }
  }
}

class _OrderStatusMeta {
  const _OrderStatusMeta({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.sp,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF6B7280)),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
