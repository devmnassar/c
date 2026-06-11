import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';
import '../models/orders_filters.dart';

class OrdersStatusSortBar extends StatelessWidget {
  const OrdersStatusSortBar({
    super.key,
    required this.l10n,
    required this.selectedFilter,
    required this.sortLabel,
    required this.onSortTap,
    required this.onFilterChanged,
  });

  final AppLocalizations? l10n;
  final FilterStatus selectedFilter;
  final String sortLabel;
  final VoidCallback onSortTap;
  final ValueChanged<FilterStatus> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF23C1B2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusFilterChip(
                    label: l10n?.filterAll ?? 'All',
                    icon: Icons.list,
                    selected: selectedFilter == FilterStatus.all,
                    onTap: () => onFilterChanged(FilterStatus.all),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: l10n?.filterNew ?? 'New',
                    icon: Icons.fiber_new,
                    selected: selectedFilter == FilterStatus.newOrder,
                    onTap: () => onFilterChanged(FilterStatus.newOrder),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: 'Assigned',
                    icon: Icons.assignment_turned_in_outlined,
                    selected: selectedFilter == FilterStatus.assigned,
                    onTap: () => onFilterChanged(FilterStatus.assigned),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: l10n?.filterActive ?? 'Active',
                    icon: Icons.sync,
                    selected: selectedFilter == FilterStatus.active,
                    onTap: () => onFilterChanged(FilterStatus.active),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: 'Attempted Delivery',
                    icon: Icons.warning_amber_rounded,
                    selected:
                        selectedFilter == FilterStatus.attemptedDelivery,
                    onTap: () =>
                        onFilterChanged(FilterStatus.attemptedDelivery),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: l10n?.filterDone ?? 'Done',
                    icon: Icons.check_circle,
                    selected: selectedFilter == FilterStatus.done,
                    onTap: () => onFilterChanged(FilterStatus.done),
                  ),
                  SizedBox(width: 8.w),
                  _StatusFilterChip(
                    label: 'Cancelled',
                    icon: Icons.cancel_outlined,
                    selected: selectedFilter == FilterStatus.cancelled,
                    onTap: () => onFilterChanged(FilterStatus.cancelled),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 14.w),
          IntrinsicWidth(
            child: OutlinedButton.icon(
              onPressed: onSortTap,
              icon: Icon(Icons.sort, size: 16.sp),
              label: Text(
                sortLabel,
                style: TextStyle(fontSize: 11.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                side: const BorderSide(color: primaryColor),
                minimumSize: Size(0, 36.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: primaryColor.withValues(alpha: 0.15),
      checkmarkColor: primaryColor,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? primaryColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13.sp,
      ),
      side: BorderSide(
        color: selected
            ? primaryColor
            : theme.colorScheme.outline.withValues(alpha: 0.3),
        width: selected ? 1.5.w : 1.w,
      ),
    );
  }
}
