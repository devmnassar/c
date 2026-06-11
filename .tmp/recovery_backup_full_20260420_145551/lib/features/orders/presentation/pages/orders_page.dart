import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/profile/profile_service.dart';
import '../../domain/models/order_mock.dart';
import '../../data/mock_orders_data.dart';
import '../../../settings/presentation/widgets/settings_bottom_sheet.dart';

// Spacing constants (compact professional density)
const double s8 = 8;
const double s12 = 12;
const double s16 = 16;

enum FilterStatus {
  all,
  newOrder,
  active,
  done,
}

enum SortOption {
  nearest,
  fastestEta,
  newest,
}

enum DateFilter {
  today,
  tomorrow,
  custom,
}

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
          () => _courierOnline = prefs.getBool(_kCourierOnlineKey) ?? false);
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
      filtered =
          filtered.where((o) => _filterState.types.contains(o.type)).toList();
    }

    filtered = filtered
        .where((o) => o.distanceKm <= _filterState.maxDistance)
        .toList();

    if (_filterState.selectedArea != null) {
      filtered =
          filtered.where((o) => o.area == _filterState.selectedArea).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (_filterState.dateFilter) {
      case DateFilter.today:
        final todayEnd = todayStart.add(const Duration(days: 1));
        filtered = filtered.where((o) {
          return o.scheduledAt.isAfter(todayStart) &&
              o.scheduledAt.isBefore(todayEnd);
        }).toList();
        break;
      case DateFilter.tomorrow:
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
        filtered = filtered.where((o) {
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
        filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.fastestEta:
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'sort'.tr ?? 'Sort',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.near_me,
                  color:
                      _selectedSort == SortOption.nearest ? primaryColor : null,
                ),
                title: Text('nearest'.tr ?? 'Nearest'),
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
                title: Text('fastestEta'.tr ?? 'Fastest ETA'),
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
                  color:
                      _selectedSort == SortOption.newest ? primaryColor : null,
                ),
                title: Text('newest'.tr ?? 'Newest'),
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
        return 'nearest'.tr ?? 'Nearest';
      case SortOption.fastestEta:
        return 'fastestEta'.tr ?? 'Fastest ETA';
      case SortOption.newest:
        return 'newest'.tr ?? 'Newest';
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: s16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'filterByType'.tr ?? 'Filters',
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
                        child: Text('reset'.tr ?? 'Reset'),
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
                          'status'.tr ?? 'Status',
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
                              label: 'filterAll'.tr ?? 'All',
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
                              label: 'filterNew'.tr ?? 'New',
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
                              label: 'filterActive'.tr ?? 'Active',
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
                              label: 'filterDone'.tr ?? 'Done',
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
                          'filterByType'.tr ?? 'Type',
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
                              label: 'pickup'.tr ?? 'Pickup',
                              icon: Icons.person,
                              selected: _filterState.types
                                  .contains(OrderTypeMock.pickup),
                              onTap: () {
                                setModalState(() {
                                  if (_filterState.types
                                      .contains(OrderTypeMock.pickup)) {
                                    _filterState.types
                                        .remove(OrderTypeMock.pickup);
                                  } else {
                                    _filterState.types
                                        .add(OrderTypeMock.pickup);
                                  }
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: 'delivery'.tr ?? 'Delivery',
                              icon: Icons.local_laundry_service,
                              selected: _filterState.types
                                  .contains(OrderTypeMock.delivery),
                              onTap: () {
                                setModalState(() {
                                  if (_filterState.types
                                      .contains(OrderTypeMock.delivery)) {
                                    _filterState.types
                                        .remove(OrderTypeMock.delivery);
                                  } else {
                                    _filterState.types
                                        .add(OrderTypeMock.delivery);
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
                                '${'filterByDistance'.tr ?? 'Distance'}: ${_filterState.maxDistance.toStringAsFixed(1)} km',
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
                          'filterByDate'.tr ?? 'Date',
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
                              label: 'today'.tr ?? 'Today',
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
                              label: 'tomorrow'.tr ?? 'Tomorrow',
                              icon: Icons.today_outlined,
                              selected: _filterState.dateFilter ==
                                  DateFilter.tomorrow,
                              onTap: () {
                                setModalState(() {
                                  _filterState.dateFilter = DateFilter.tomorrow;
                                });
                              },
                            ),
                            _buildFilterChip(
                              context: context,
                              label: 'custom'.tr ?? 'Custom',
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
                          'filterByArea'.tr ?? 'Area',
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
                                horizontal: 16, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('filterAll'.tr ?? 'All'),
                            ),
                            ..._mockAreas
                                .map((area) => DropdownMenuItem<String>(
                                      value: area,
                                      child: Text(area),
                                    )),
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
                            _filterState.types =
                                Set.from(savedFilterState.types);
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
                          child: Text('cancel'.tr ?? 'Cancel'),
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
                          child: Text('apply'.tr ?? 'Apply'),
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
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      BuildContext context, ThemeData theme, AppLocalizations? l10n) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(s16, s16, s16, s12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _profilePhoto != null
                        ? FileImage(_profilePhoto!)
                        : null,
                    child: _profilePhoto == null
                        ? Icon(Icons.person,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))
                        : null,
                  ),
                  const SizedBox(height: s12),
                  Text(
                    'Courier',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _courierOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: s8),
                      Text(
                        _courierOnline
                            ? ('drawerStatusOnline'.tr ?? 'Online')
                            : ('drawerStatusOffline'.tr ?? 'Offline'),
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
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: s8),
                children: [
                  _drawerTile(theme, 'drawerOrders'.tr ?? 'Orders',
                      Icons.receipt_long_outlined, () {
                    Navigator.of(context).pop();
                    final loc = GoRouterState.of(context).matchedLocation;
                    if (loc != '/orders' && !loc.startsWith('/orders')) {
                      context.go('/orders');
                    }
                  }),
                  _drawerTile(
                      theme,
                      'promotion'.tr ?? 'Promotion',
                      Icons.campaign_outlined,
                      () => _drawerComingSoon(context, l10n)),
                  _drawerTile(
                      theme,
                      'inbox'.tr ?? 'Inbox',
                      Icons.inbox_outlined,
                      () => _drawerComingSoon(context, l10n)),
                  _drawerTile(
                      theme,
                      'appealCentre'.tr ?? 'Appeal Centre',
                      Icons.gavel_outlined,
                      () => _drawerComingSoon(context, l10n)),
                  _drawerTile(
                      theme,
                      'tutorialCentre'.tr ?? 'Tutorial Centre',
                      Icons.school_outlined,
                      () => _drawerComingSoon(context, l10n)),
                  _drawerTile(
                      theme,
                      'contactCs'.tr ?? 'Contact CS',
                      Icons.support_agent_outlined,
                      () => _drawerComingSoon(context, l10n)),
                  _drawerTile(theme, 'menuSettings'.tr ?? 'Settings',
                      Icons.settings_outlined, () {
                    Navigator.of(context).pop();
                    context.push('/home/settings');
                  }),
                  const Divider(height: 24),
                  _drawerTile(theme, 'menuLogout'.tr ?? 'Logout', Icons.logout,
                      () => _drawerLogout(context, l10n)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerTile(
      ThemeData theme, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _drawerComingSoon(BuildContext context, AppLocalizations? l10n) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('comingSoon'.tr ?? 'Coming soon')),
    );
  }

  Future<void> _drawerLogout(
      BuildContext context, AppLocalizations? l10n) async {
    Navigator.of(context).pop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('drawerLogoutTitle'.tr ?? 'Logout'),
        content: Text('drawerLogoutMessage'.tr ?? 'Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('drawerLogoutCancel'.tr ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('drawerLogoutYes'.tr ?? 'Yes'),
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
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.8),
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
          'ordersTitle'.tr ?? 'orders'.tr ?? 'Orders',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _showAdvancedFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Compact Mini-Dashboard Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: s16, vertical: s12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDashboardTile(
                          context,
                          icon: Icons.today,
                          value: _getTodayOrdersCount().toString(),
                          label: 'todayOrders'.tr ?? 'Today',
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: s8),
                      Expanded(
                        child: _buildDashboardTile(
                          context,
                          icon: Icons.sync,
                          value: _getInProgressCount().toString(),
                          label: 'inProgress'.tr ?? 'In Progress',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: s8),
                      Expanded(
                        child: _buildDashboardTile(
                          context,
                          icon: Icons.check_circle,
                          value: _getCompletedCount().toString(),
                          label: 'completed'.tr ?? 'Completed',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Filter Chips + Sort Button Row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: s16, vertical: s8),
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
                                label: 'filterAll'.tr ?? 'All',
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
                                label: 'filterNew'.tr ?? 'New',
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
                                label: 'filterActive'.tr ?? 'Active',
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
                                label: 'filterDone'.tr ?? 'Done',
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
                                horizontal: 10, vertical: 8),
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: s12),
                              Text(
                                'noOrdersFound'.tr ?? 'No orders found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: s16, vertical: s8),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              if (kDebugMode) {
                                debugPrint(
                                    'ORDER CARD: id=${order.id} type=${order.type}');
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: s12),
                                child: _buildOrderCard(
                                    context, order, l10n, primaryColor),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.all(s12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    Color primaryColor,
  ) {
    final theme = Theme.of(context);
    final isPickup = order.type == OrderTypeMock.pickup;

    // Status color and text
    Color statusColor;
    String statusText;
    switch (order.status) {
      case OrderStatusMock.newOrder:
        statusColor = Colors.orange;
        statusText = 'filterNew'.tr ?? 'New';
        break;
      case OrderStatusMock.inProgress:
        statusColor = Colors.blue;
        statusText = 'inProgress'.tr ?? 'In Progress';
        break;
      case OrderStatusMock.arrivedAtLaundry:
        statusColor = Colors.teal;
        statusText = 'statusArrivedAtLaundry'.tr ?? 'Arrived at laundry';
        break;
      case OrderStatusMock.arrivedAtCustomer:
        statusColor = Colors.teal;
        statusText = 'statusArrivedAtCustomer'.tr ?? 'Arrived at customer';
        break;
      case OrderStatusMock.completed:
        statusColor = Colors.green;
        statusText = 'completed'.tr ?? 'Completed';
        break;
    }

    // Format scheduled time
    final timeFormat = DateFormat('HH:mm');
    final isToday = order.scheduledAt.year == DateTime.now().year &&
        order.scheduledAt.month == DateTime.now().month &&
        order.scheduledAt.day == DateTime.now().day;
    final scheduledText = isToday
        ? '${'today'.tr ?? 'Today'} • ${timeFormat.format(order.scheduledAt)}'
        : DateFormat('MMM dd • HH:mm').format(order.scheduledAt);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (kDebugMode) {
              debugPrint(
                  'NAV TO ACTIVE TRIP: id=${order.id} type=${order.type}');
            }
            context.go('/active-trip/${order.id}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Content (Expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Order ID + Type Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.id,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: s8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isPickup
                                    ? ('pickup'.tr ?? 'Pickup')
                                    : ('delivery'.tr ?? 'Delivery'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: s12),

                      // Address line: area • district (2 lines max)
                      Text(
                        '${order.area} • ${order.district}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: s8),

                      // Time line: Today • 18:16
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              scheduledText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: s12),

                      // Meta chips row: Status + Distance + ETA
                      Wrap(
                        spacing: s8,
                        runSpacing: s8,
                        children: [
                          // Status badge (larger)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                statusText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          // Distance chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 14,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${order.distanceKm.toStringAsFixed(1)} km',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ETA chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${order.etaMin} min',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: Map Icon + Start Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Opening maps for ${order.id}')),
                        );
                      },
                      style: IconButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(height: s8),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Starting order ${order.id}')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text(
                        'start'.tr ?? 'Start',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
