import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/profile/profile_service.dart';
import '../../domain/models/order_mock.dart';
import '../../data/mock_orders_data.dart';

// Spacing constants (compact professional density)
const double s8 = 8;
const double s12 = 12;
const double s16 = 16;

enum FilterStatus { all, newOrder, active, done }

enum SortOption { nearest, fastestEta, newest }

enum DateFilter { today, tomorrow, custom }

class _FilterState {
  FilterStatus status = FilterStatus.all;
  Set<OrderTypeMock> types = {};
  double maxDistance = 20.0;
  DateFilter dateFilter = DateFilter.today;
  String? selectedArea;
}

class OrdersPage extends StatefulWidget {
  static const String id = '/orders';
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<OrderMock> _allOrders = [];
  List<OrderMock> _filteredOrders = [];
  FilterStatus _selectedFilter = FilterStatus.all;
  SortOption _selectedSort = SortOption.nearest;
  File? _profilePhoto;
  bool _isLoading = true;

  /// Courier online/offline status (persisted to SharedPreferences).
  bool _courierOnline = false;

  static const String _kCourierOnlineKey = 'courier_online';

  // Advanced filter state
  final _FilterState _filterState = _FilterState();
  final List<String> _mockAreas = [
    'Al Olaya',
    'Al Malaz',
    'Al Naseem',
    'Al Wurud',
    'Al Falah',
    'Al Murabba',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadProfilePhoto();
    _loadCourierOnline();
  }

  Future<void> _loadCourierOnline() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _courierOnline = prefs.getBool(_kCourierOnlineKey) ?? false,
      );
    }
  }

  Future<void> _setCourierOnline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCourierOnlineKey, value);
    if (mounted) setState(() => _courierOnline = value);
  }

  Future<void> _loadProfilePhoto() async {
    final profile = await ProfileService.getProfile();
    if (profile != null) {
      final photoPath = profile['photoPath'];
      if (photoPath != null) {
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          setState(() {
            _profilePhoto = photoFile;
          });
        }
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final orders = MockOrdersData.getMockOrders();
    setState(() {
      _allOrders = orders;
      _isLoading = false;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    List<OrderMock> filtered = List.from(_allOrders);

    // Apply status filter
    switch (_selectedFilter) {
      case FilterStatus.all:
        break;
      case FilterStatus.newOrder:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.newOrder)
            .toList();
        break;
      case FilterStatus.active:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.inProgress)
            .toList();
        break;
      case FilterStatus.done:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.completed)
            .toList();
        break;
    }

    // Apply advanced filters
    if (_filterState.types.isNotEmpty) {
      filtered = filtered
          .where((o) => _filterState.types.contains(o.type))
          .toList();
    }

    filtered = filtered
        .where((o) => o.distanceKm <= _filterState.maxDistance)
        .toList();

    if (_filterState.selectedArea != null) {
      filtered = filtered
          .where((o) => o.area == _filterState.selectedArea)
          .toList();
    }

    // Apply date filter (BUT exempt completed orders so they always show in history)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (_filterState.dateFilter) {
      case DateFilter.today:
        final todayEnd = todayStart.add(const Duration(days: 1));
        filtered = filtered.where((o) {
          if (o.status == OrderStatusMock.completed) return true;
          return o.scheduledAt.isAfter(todayStart) &&
              o.scheduledAt.isBefore(todayEnd);
        }).toList();
        break;
      case DateFilter.tomorrow:
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
        filtered = filtered.where((o) {
          if (o.status == OrderStatusMock.completed) return true;
          return o.scheduledAt.isAfter(tomorrowStart) &&
              o.scheduledAt.isBefore(tomorrowEnd);
        }).toList();
        break;
      case DateFilter.custom:
        // No filtering for custom (show all)
        break;
    }

    // Apply sort
    switch (_selectedSort) {
      case SortOption.nearest:
        // Keep nearest for now but user said don't show distance
        filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.fastestEta:
        // Keep fastest for now but user said don't show time
        filtered.sort((a, b) => a.etaMin.compareTo(b.etaMin));
        break;
      case SortOption.newest:
        filtered.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        break;
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  int _getTodayOrdersCount() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return _allOrders.where((o) {
      return o.scheduledAt.isAfter(todayStart) &&
          o.scheduledAt.isBefore(todayEnd);
    }).length;
  }

  int _getInProgressCount() {
    return _allOrders
        .where((o) => o.status == OrderStatusMock.inProgress)
        .length;
  }

  int _getCompletedCount() {
    return _allOrders
        .where((o) => o.status == OrderStatusMock.completed)
        .length;
  }

  void _showSortBottomSheet() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  l10n?.sort ?? 'Sort',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.near_me,
                  color: _selectedSort == SortOption.nearest
                      ? primaryColor
                      : null,
                ),
                title: const Text('Nearest'),
                trailing: _selectedSort == SortOption.nearest
                    ? Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSort = SortOption.nearest;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: _selectedSort == SortOption.fastestEta
                      ? primaryColor
                      : null,
                ),
                title: const Text('Fastest'), // Simplified label
                trailing: _selectedSort == SortOption.fastestEta
                    ? Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSort = SortOption.fastestEta;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.new_releases,
                  color: _selectedSort == SortOption.newest
                      ? primaryColor
                      : null,
                ),
                title: Text(l10n?.newest ?? 'Newest'),
                trailing: _selectedSort == SortOption.newest
                    ? Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSort = SortOption.newest;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortLabel(AppLocalizations? l10n) {
    switch (_selectedSort) {
      case SortOption.nearest:
        return 'Nearest';
      case SortOption.fastestEta:
        return 'Fastest';
      case SortOption.newest:
        return 'Newest';
    }
  }

  void _showAdvancedFilter() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    // Save current filter state
    final savedFilterState = _FilterState()
      ..status = _filterState.status
      ..types = Set.from(_filterState.types)
      ..maxDistance = _filterState.maxDistance
      ..dateFilter = _filterState.dateFilter
      ..selectedArea = _filterState.selectedArea;

    showModalBottomSheet(
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
                    horizontal: s16,
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
                            _filterState.status = FilterStatus.all;
                            _filterState.types.clear();
                            _filterState.maxDistance = 20.0;
                            _filterState.dateFilter = DateFilter.today;
                            _filterState.selectedArea = null;
                          });
                        },
                        child: Text(l10n?.reset ?? 'Reset'),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status filter
                        Text(
                          l10n?.status ?? 'Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: s8),
                        Wrap(
                          spacing: s8,
                          runSpacing: s8,
                          children: [
                            _buildFilterChip(
                              context: context,
                              label: l10n?.filterAll ?? 'All',
                              icon: Icons.list,
                              selected: _filterState.status == FilterStatus.all,
                              onTap: () {
                                setModalState(() {
                                  _filterState.status = FilterStatus.all;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.filterNew ?? 'New',
                              icon: Icons.fiber_new,
                              selected:
                                  _filterState.status == FilterStatus.newOrder,
                              onTap: () {
                                setModalState(() {
                                  _filterState.status = FilterStatus.newOrder;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.filterActive ?? 'Active',
                              icon: Icons.sync,
                              selected:
                                  _filterState.status == FilterStatus.active,
                              onTap: () {
                                setModalState(() {
                                  _filterState.status = FilterStatus.active;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.filterDone ?? 'Done',
                              icon: Icons.check_circle,
                              selected:
                                  _filterState.status == FilterStatus.done,
                              onTap: () {
                                setModalState(() {
                                  _filterState.status = FilterStatus.done;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: s12),

                        // Type filter
                        Text(
                          l10n?.filterByType ?? 'Type',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: s8),
                        Wrap(
                          spacing: s8,
                          runSpacing: s8,
                          children: [
                            _buildFilterChip(
                              context: context,
                              label: l10n?.pickup ?? 'Pickup',
                              icon: Icons.person,
                              selected: _filterState.types.contains(
                                OrderTypeMock.pickup,
                              ),
                              onTap: () {
                                setModalState(() {
                                  if (_filterState.types.contains(
                                    OrderTypeMock.pickup,
                                  )) {
                                    _filterState.types.remove(
                                      OrderTypeMock.pickup,
                                    );
                                  } else {
                                    _filterState.types.add(
                                      OrderTypeMock.pickup,
                                    );
                                  }
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.delivery ?? 'Delivery',
                              icon: Icons.local_laundry_service,
                              selected: _filterState.types.contains(
                                OrderTypeMock.delivery,
                              ),
                              onTap: () {
                                setModalState(() {
                                  if (_filterState.types.contains(
                                    OrderTypeMock.delivery,
                                  )) {
                                    _filterState.types.remove(
                                      OrderTypeMock.delivery,
                                    );
                                  } else {
                                    _filterState.types.add(
                                      OrderTypeMock.delivery,
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: s12),

                        // Distance slider
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n?.filterByDistance ?? 'Distance'}: ${_filterState.maxDistance.toStringAsFixed(1)} km',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: s8),
                        Slider(
                          value: _filterState.maxDistance,
                          min: 0,
                          max: 20,
                          divisions: 40,
                          label:
                              '${_filterState.maxDistance.toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setModalState(() {
                              _filterState.maxDistance = value;
                            });
                          },
                        ),
                        const SizedBox(height: s12),

                        // Date filter
                        Text(
                          l10n?.filterByDate ?? 'Date',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: s8),
                        Wrap(
                          spacing: s8,
                          runSpacing: s8,
                          children: [
                            _buildFilterChip(
                              context: context,
                              label: l10n?.today ?? 'Today',
                              icon: Icons.today,
                              selected:
                                  _filterState.dateFilter == DateFilter.today,
                              onTap: () {
                                setModalState(() {
                                  _filterState.dateFilter = DateFilter.today;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.tomorrow ?? 'Tomorrow',
                              icon: Icons.today_outlined,
                              selected:
                                  _filterState.dateFilter ==
                                  DateFilter.tomorrow,
                              onTap: () {
                                setModalState(() {
                                  _filterState.dateFilter = DateFilter.tomorrow;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: l10n?.custom ?? 'Custom',
                              icon: Icons.calendar_today,
                              selected:
                                  _filterState.dateFilter == DateFilter.custom,
                              onTap: () {
                                setModalState(() {
                                  _filterState.dateFilter = DateFilter.custom;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: s12),

                        // Area dropdown
                        Text(
                          l10n?.filterByArea ?? 'Area',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: s8),
                        DropdownButtonFormField<String>(
                          value: _filterState.selectedArea,
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
                            ..._mockAreas.map(
                              (area) => DropdownMenuItem<String>(
                                value: area,
                                child: Text(area),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              _filterState.selectedArea = value;
                            });
                          },
                        ),
                        const SizedBox(height: s16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(s16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Restore saved state
                            _filterState.status = savedFilterState.status;
                            _filterState.types = Set.from(
                              savedFilterState.types,
                            );
                            _filterState.maxDistance =
                                savedFilterState.maxDistance;
                            _filterState.dateFilter =
                                savedFilterState.dateFilter;
                            _filterState.selectedArea =
                                savedFilterState.selectedArea;
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(l10n?.cancel ?? 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: s12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = _filterState.status;
                              _applyFiltersAndSort();
                            });
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

  Widget _buildStatusFilterChip({
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
      selectedColor: primaryColor.withValues(alpha: 0.15),
      checkmarkColor: primaryColor,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? primaryColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected
            ? primaryColor
            : theme.colorScheme.outline.withValues(alpha: 0.3),
        width: selected ? 1.5 : 1,
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

  Widget _buildOrdersDrawer(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(s16, s16, s16, s12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      context.push('/profile');
                    },
                    child: Column(
                      children: [
                        Hero(
                          tag: 'profile_photo',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: _profilePhoto != null
                                ? FileImage(_profilePhoto!)
                                : null,
                            child: _profilePhoto == null
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: s12),
                        Text(
                          'Courier',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: s8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _courierOnline
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: s8),
                            Text(
                              _courierOnline
                                  ? (l10n?.drawerStatusOnline ?? 'Online')
                                  : (l10n?.drawerStatusOffline ?? 'Offline'),
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(width: s8),
                            Switch(
                              value: _courierOnline,
                              onChanged: (value) => _setCourierOnline(value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        context.push('/notifications');
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              size: 24,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5252),
                                    Color(0xFFD32F2F),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '+11',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: s8),
                children: [
                  _drawerTile(
                    theme,
                    l10n?.profile ?? 'Profile',
                    Icons.person_outline,
                    () {
                      Navigator.of(context).pop();
                      context.push('/profile');
                    },
                  ),
                  _drawerTile(
                    theme,
                    l10n?.drawerOrders ?? 'Orders',
                    Icons.receipt_long_outlined,
                    () {
                      Navigator.of(context).pop();
                      final loc = GoRouterState.of(context).matchedLocation;
                      if (loc != '/orders' && !loc.startsWith('/orders')) {
                        context.go('/orders');
                      }
                    },
                  ),
                  _drawerTile(
                    theme,
                    l10n?.promotion ?? 'Promotion',
                    Icons.campaign_outlined,
                    () => _drawerComingSoon(context, l10n),
                  ),
                  _drawerTile(
                    theme,
                    l10n?.inbox ?? 'Inbox',
                    Icons.inbox_outlined,
                    () => _drawerComingSoon(context, l10n),
                  ),
                  _drawerTile(
                    theme,
                    l10n?.appealCentre ?? 'Appeal Centre',
                    Icons.gavel_outlined,
                    () => _drawerComingSoon(context, l10n),
                  ),
                  _drawerTile(
                    theme,
                    l10n?.tutorialCentre ?? 'Tutorial Centre',
                    Icons.school_outlined,
                    () => _drawerComingSoon(context, l10n),
                  ),
                  _drawerTile(
                    theme,
                    l10n?.contactCs ?? 'Contact CS',
                    Icons.support_agent_outlined,
                    () => _drawerComingSoon(context, l10n),
                  ),
                  _drawerTile(
                    theme,
                    l10n?.menuSettings ?? 'Settings',
                    Icons.settings_outlined,
                    () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  const Divider(height: 24),
                  _drawerTile(
                    theme,
                    l10n?.menuLogout ?? 'Logout',
                    Icons.logout,
                    () => _drawerLogout(context, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerTile(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _drawerComingSoon(BuildContext context, AppLocalizations? l10n) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n?.comingSoon ?? 'Coming soon')));
  }

  Future<void> _drawerLogout(
    BuildContext context,
    AppLocalizations? l10n,
  ) async {
    Navigator.of(context).pop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.drawerLogoutTitle ?? 'Logout'),
        content: Text(l10n?.drawerLogoutMessage ?? 'Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.drawerLogoutCancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.drawerLogoutYes ?? 'Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AuthService.logout();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isRtl ? null : _buildOrdersDrawer(context, theme, l10n),
      endDrawer: isRtl ? _buildOrdersDrawer(context, theme, l10n) : null,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) {
            return Padding(
              padding: const EdgeInsets.all(s8),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.8,
                ),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (isRtl) {
                      Scaffold.of(ctx).openEndDrawer();
                    } else {
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                  child: const Center(
                    child: Icon(Icons.menu, color: Colors.black87, size: 24),
                  ),
                ),
              ),
            );
          },
        ),
        title: Text(
          l10n?.ordersTitle ?? l10n?.orders ?? 'Orders',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: theme.colorScheme.onSurface),
            onPressed: _showAdvancedFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Integrated Summary Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        'Today',
                        _getTodayOrdersCount().toString(),
                        primaryColor,
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[200]),
                      _buildSummaryItem(
                        'Active',
                        _getInProgressCount().toString(),
                        const Color(0xFF3B82F6),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[200]),
                      _buildSummaryItem(
                        'Done',
                        _getCompletedCount().toString(),
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),

                // Status Filter Chips + Sort Button Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: s16,
                    vertical: s8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Filter Chips
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip(
                                context: context,
                                label: l10n?.filterAll ?? 'All',
                                icon: Icons.list,
                                selected: _selectedFilter == FilterStatus.all,
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = FilterStatus.all;
                                    _applyFiltersAndSort();
                                  });
                                },
                              ),
                              const SizedBox(width: s8),
                              _buildStatusFilterChip(
                                context: context,
                                label: l10n?.filterNew ?? 'New',
                                icon: Icons.fiber_new,
                                selected:
                                    _selectedFilter == FilterStatus.newOrder,
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = FilterStatus.newOrder;
                                    _applyFiltersAndSort();
                                  });
                                },
                              ),
                              const SizedBox(width: s8),
                              _buildStatusFilterChip(
                                context: context,
                                label: l10n?.filterActive ?? 'Active',
                                icon: Icons.sync,
                                selected:
                                    _selectedFilter == FilterStatus.active,
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = FilterStatus.active;
                                    _applyFiltersAndSort();
                                  });
                                },
                              ),
                              const SizedBox(width: s8),
                              _buildStatusFilterChip(
                                context: context,
                                label: l10n?.filterDone ?? 'Done',
                                icon: Icons.check_circle,
                                selected: _selectedFilter == FilterStatus.done,
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = FilterStatus.done;
                                    _applyFiltersAndSort();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Sort Button (Fastest ETA)
                      IntrinsicWidth(
                        child: OutlinedButton.icon(
                          onPressed: _showSortBottomSheet,
                          icon: const Icon(Icons.sort, size: 16),
                          label: Text(
                            _getSortLabel(l10n),
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            side: BorderSide(color: primaryColor),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders List
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            children: [
                              // Active Orders Section (Always on top if exists)
                              if (_getInProgressCount() > 0) ...[
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
                                ..._filteredOrders
                                    .where(
                                      (o) =>
                                          o.status ==
                                          OrderStatusMock.inProgress,
                                    )
                                    .map(
                                      (order) => _buildOrderCard(
                                        context,
                                        order,
                                        l10n,
                                        primaryColor,
                                        isActive: true,
                                      ),
                                    ),
                                const SizedBox(height: 24),
                              ],

                              // Remaining Orders Section
                              if (_filteredOrders.any(
                                (o) => o.status != OrderStatusMock.inProgress,
                              )) ...[
                                Text(
                                  _selectedFilter == FilterStatus.done
                                      ? 'HISTORY'
                                      : 'RECENT ORDERS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._filteredOrders
                                    .where(
                                      (o) =>
                                          o.status !=
                                          OrderStatusMock.inProgress,
                                    )
                                    .map(
                                      (order) => _buildOrderCard(
                                        context,
                                        order,
                                        l10n,
                                        primaryColor,
                                      ),
                                    ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.noOrdersFound ?? 'No orders found',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderMock order,
    AppLocalizations? l10n,
    Color primaryColor, {
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final isPickup = order.type == OrderTypeMock.pickup;
    final isDone = order.status == OrderStatusMock.completed;

    // Status color and text
    Color statusColor;
    String statusText;
    switch (order.status) {
      case OrderStatusMock.newOrder:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'New Order';
        break;
      case OrderStatusMock.inProgress:
        statusColor = const Color(0xFF3B82F6);
        statusText = 'In Transit';
        break;
      case OrderStatusMock.arrivedAtLaundry:
        statusColor = const Color(0xFF10B981);
        statusText = 'At Laundry';
        break;
      case OrderStatusMock.arrivedAtCustomer:
        statusColor = const Color(0xFF10B981);
        statusText = 'At Customer';
        break;
      case OrderStatusMock.completed:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Completed';
        break;
    }

    final startTimeStr = DateFormat('HH:mm').format(order.scheduledAt);
    final endTimeStr = DateFormat(
      'HH:mm',
    ).format(order.scheduledAt.add(const Duration(minutes: 20)));
    final scheduledTime = '$startTimeStr - $endTimeStr';

    final itemCount = order.orderItems?.length ?? 0;
    final isCash = order.isCash ?? true;

    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isActive
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? primaryColor.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isDone) {
                  _showOrderDetails(context, order);
                } else {
                  context.go('/active-trip/${order.id}');
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPickup
                                    ? Colors.amber.shade100
                                    : primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPickup
                                    ? (l10n?.pickup ?? 'Pickup')
                                    : (l10n?.delivery ?? 'Delivery'),
                                style: TextStyle(
                                  color: isPickup
                                      ? Colors.amber.shade900
                                      : primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onLongPress: () {
                                // Developer testing shortcut: Long press status to complete order
                                if (!isDone) {
                                  MockOrdersData.updateOrderStatus(
                                    order.id,
                                    OrderStatusMock.completed,
                                  );
                                  _loadOrders();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Order ${order.id} marked as COMPLETED (Test Mode)',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.grey[50]
                                : primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPickup
                                ? Icons.local_shipping_outlined
                                : Icons.inventory_2_outlined,
                            color: isDone ? Colors.grey[400] : primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  setCardState(() {
                                    isExpanded = !isExpanded;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      isExpanded
                                          ? 'Hide Address'
                                          : 'Show Address',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pickup Address:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPickup
                                            ? '${order.customerName} - ${order.district}, ${order.area}'
                                            : order.laundryName ??
                                                  'Fresh Laundry',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Dropoff Address:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPickup
                                            ? order.laundryName ?? 'Laundry'
                                            : '${order.customerName} - ${order.district}, ${order.area}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isDone)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Time: $scheduledTime',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (!isDone) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildCompactInfo(
                            icon: Icons.payments_outlined,
                            label: isCash ? 'CASH' : 'PREPAID',
                            color: isCash
                                ? Colors.green[600]!
                                : Colors.blue[600]!,
                          ),
                          const SizedBox(width: 12),
                          _buildCompactInfo(
                            icon: Icons.shopping_bag_outlined,
                            label: '$itemCount ITEMS',
                            color: Colors.grey[600]!,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: primaryColor,
                            size: 24,
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
      },
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderMock order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[600],
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow('Order ID', '#${order.id}'),
            _buildDetailRow('Customer', order.customerName),
            _buildDetailRow(
              'Completed At',
              DateFormat('MMM dd, hh:mm a').format(order.scheduledAt),
            ),
            _buildDetailRow(
              'Payment',
              order.isCash == true ? 'Cash' : 'Paid Online',
            ),
            _buildDetailRow('Location', '${order.district}, ${order.area}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF1F2937),
                  elevation: 0,
                ),
                child: const Text(
                  'Close Archive',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
