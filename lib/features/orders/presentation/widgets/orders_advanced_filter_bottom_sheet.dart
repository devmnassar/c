import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order_mock.dart';
import '../models/orders_filters.dart';

const double _s8 = 8;
const double _s12 = 12;
const double _s16 = 16;

Future<void> showOrdersAdvancedFilterBottomSheet({
  required BuildContext context,
  required AppLocalizations? l10n,
  required OrdersFilterState filterState,
  required List<String> areas,
  required VoidCallback onApply,
}) {
  final theme = Theme.of(context);
  const primaryColor = Color(0xFF23C1B2);

  final savedFilterState = filterState.copy();

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _s16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.filterByType ?? 'Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          filterState.status = FilterStatus.all;
                          filterState.types.clear();
                          filterState.maxDistance = 20.0;
                          filterState.dateFilter = DateFilter.custom;
                          filterState.selectedArea = null;
                        });
                      },
                      child: Text(l10n?.reset ?? 'Reset'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: _s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.status ?? 'Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: _s8),
                      Wrap(
                        spacing: _s8,
                        runSpacing: _s8,
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: l10n?.filterAll ?? 'All',
                            icon: Icons.list,
                            selected: filterState.status == FilterStatus.all,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.all,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.filterNew ?? 'New',
                            icon: Icons.fiber_new,
                            selected:
                                filterState.status == FilterStatus.newOrder,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.newOrder,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: 'Assigned',
                            icon: Icons.assignment_turned_in_outlined,
                            selected:
                                filterState.status == FilterStatus.assigned,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.assigned,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.filterActive ?? 'Active',
                            icon: Icons.sync,
                            selected: filterState.status == FilterStatus.active,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.active,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: 'Attempted Delivery',
                            icon: Icons.warning_amber_rounded,
                            selected: filterState.status ==
                                FilterStatus.attemptedDelivery,
                            onTap: () => setModalState(
                              () => filterState.status =
                                  FilterStatus.attemptedDelivery,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.filterDone ?? 'Done',
                            icon: Icons.check_circle,
                            selected: filterState.status == FilterStatus.done,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.done,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: 'Cancelled',
                            icon: Icons.cancel_outlined,
                            selected:
                                filterState.status == FilterStatus.cancelled,
                            onTap: () => setModalState(
                              () => filterState.status = FilterStatus.cancelled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _s12),
                      Text(
                        l10n?.filterByType ?? 'Type',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: _s8),
                      Wrap(
                        spacing: _s8,
                        runSpacing: _s8,
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: l10n?.pickup ?? 'Pickup',
                            icon: Icons.person,
                            selected: filterState.types.contains(
                              OrderTypeMock.pickup,
                            ),
                            onTap: () {
                              setModalState(() {
                                if (filterState.types.contains(
                                  OrderTypeMock.pickup,
                                )) {
                                  filterState.types.remove(
                                    OrderTypeMock.pickup,
                                  );
                                } else {
                                  filterState.types.add(OrderTypeMock.pickup);
                                }
                              });
                            },
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.delivery ?? 'Delivery',
                            icon: Icons.local_laundry_service,
                            selected: filterState.types.contains(
                              OrderTypeMock.delivery,
                            ),
                            onTap: () {
                              setModalState(() {
                                if (filterState.types.contains(
                                  OrderTypeMock.delivery,
                                )) {
                                  filterState.types.remove(
                                    OrderTypeMock.delivery,
                                  );
                                } else {
                                  filterState.types.add(OrderTypeMock.delivery);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: _s12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n?.filterByDistance ?? 'Distance'}: ${filterState.maxDistance.toStringAsFixed(1)} km',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _s8),
                      Slider(
                        value: filterState.maxDistance,
                        min: 0,
                        max: 20,
                        divisions: 40,
                        label:
                            '${filterState.maxDistance.toStringAsFixed(1)} km',
                        onChanged: (value) {
                          setModalState(() => filterState.maxDistance = value);
                        },
                      ),
                      const SizedBox(height: _s12),
                      Text(
                        l10n?.filterByDate ?? 'Date',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: _s8),
                      Wrap(
                        spacing: _s8,
                        runSpacing: _s8,
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: l10n?.today ?? 'Today',
                            icon: Icons.today,
                            selected:
                                filterState.dateFilter == DateFilter.today,
                            onTap: () => setModalState(
                              () => filterState.dateFilter = DateFilter.today,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.tomorrow ?? 'Tomorrow',
                            icon: Icons.today_outlined,
                            selected:
                                filterState.dateFilter == DateFilter.tomorrow,
                            onTap: () => setModalState(
                              () =>
                                  filterState.dateFilter = DateFilter.tomorrow,
                            ),
                          ),
                          _buildFilterChip(
                            context: context,
                            label: l10n?.custom ?? 'Custom',
                            icon: Icons.calendar_today,
                            selected:
                                filterState.dateFilter == DateFilter.custom,
                            onTap: () => setModalState(
                              () => filterState.dateFilter = DateFilter.custom,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _s12),
                      Text(
                        l10n?.filterByArea ?? 'Area',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: _s8),
                      DropdownButtonFormField<String>(
                        value: filterState.selectedArea,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n?.filterAll ?? 'All'),
                          ),
                          ...areas.map(
                            (area) => DropdownMenuItem<String>(
                              value: area,
                              child: Text(area),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() => filterState.selectedArea = value);
                        },
                      ),
                      const SizedBox(height: _s16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_s16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          filterState.restoreFrom(savedFilterState);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: _s12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          onApply();
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n?.apply ?? 'Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildFilterChip({
  required BuildContext context,
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  const primaryColor = Color(0xFF23C1B2);

  return FilterChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: primaryColor.withValues(alpha: 0.2),
    checkmarkColor: primaryColor,
    labelStyle: TextStyle(
      color: selected ? primaryColor : theme.colorScheme.onSurface,
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
    ),
  );
}
