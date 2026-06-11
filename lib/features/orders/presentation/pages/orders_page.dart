import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/app_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../driver_availability/presentation/cubit/heartbeat_cubit.dart';
import '../../../driver_availability/presentation/cubit/go_offline_cubit.dart';
import '../../../courier_profile/data/datasources/courier_profile_local_data_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order_mock.dart';
import '../cubit/orders_cubit.dart';
import '../models/orders_filters.dart';
import '../widgets/orders_page_widgets.dart';

class OrdersPage extends StatelessWidget {
  static const String id = '/orders';
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<OrdersCubit>()..loadOrders(),
        ),
        BlocProvider(
          create: (_) => getIt<GoOfflineCubit>(),
        ),
      ],
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  static const String _kCourierOnlineKey = 'courier_online';
  static const int _fullTimeCourierTypeId = 3;

  File? _profilePhoto;
  bool _courierOnline = false;
  int? _cachedCourierTypeId;
  final CourierProfileLocalDataSource _courierProfileLocalDataSource =
      getIt<CourierProfileLocalDataSource>();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadCourierOnline();
    _loadCachedCourierTypeId();
  }

  void _log(String message) {
    debugPrint('================ ORDERS PAGE FLOW ================');
    debugPrint('[ORDERS PAGE FLOW] $message');
  }

  bool get _isFullTimeCourier => _cachedCourierTypeId == _fullTimeCourierTypeId;

  Future<void> _loadCachedCourierTypeId() async {
    final courierTypeId =
        await _courierProfileLocalDataSource.getCachedCourierTypeId();
    _log('Loaded cached courierTypeId=$courierTypeId in orders page');
    if (!mounted) return;
    setState(() => _cachedCourierTypeId = courierTypeId);
  }

  Future<void> _loadCourierOnline() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _courierOnline = prefs.getBool(_kCourierOnlineKey) ?? false);
  }

  Future<void> _setCourierOnline(bool value) async {
    if (value == _courierOnline) {
      return;
    }

    if (value) {
      Navigator.of(context).pop();
      context.go('/map-status', extra: {'autoSearch': true});
      return;
    }

    context.read<GoOfflineCubit>().goOffline();
  }

  Future<void> _persistCourierOnline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCourierOnlineKey, value);
    if (!mounted) return;
    setState(() => _courierOnline = value);
  }

  Future<void> _loadProfilePhoto() async {
    final profile = await ProfileService.getProfile();
    if (profile == null) return;

    final photoPath = profile['photoPath'];
    if (photoPath == null) return;

    final photoFile = File(photoPath);
    if (await photoFile.exists() && mounted) {
      setState(() => _profilePhoto = photoFile);
    }
  }

  Future<void> _handleOpenOrder(OrderMock tappedOrder) async {
    _log(
      'Order tapped. orderId=${tappedOrder.id}, '
      'status=${tappedOrder.status.name}, type=${tappedOrder.type.name}, '
      'riderStatus=${tappedOrder.riderStatus?.name}, '
      'pickupRiderStatus=${tappedOrder.pickupRiderStatus?.name}, '
      'courierTypeId=$_cachedCourierTypeId',
    );

    if (!_isFullTimeCourier) {
      _log('Courier is not fulltime. Opening order with existing flow');
      if (!mounted) return;
      context.push(
        '/active-trip/${tappedOrder.id}',
        extra: {
          'order': tappedOrder,
          'entrySource': 'orders',
        },
      );
      return;
    }

    final cubit = context.read<OrdersCubit>();
    _log('Fulltime courier detected. Refreshing orders API before navigation');
    final latestOrder = await cubit.refreshAndFindOrderById(tappedOrder.id);
    if (!mounted) return;

    if (latestOrder == null) {
      final errorMessage = cubit.state.errorMessage ??
          'Unable to load the latest order state from orders list.';
      _log('Failed to resolve latest order before navigation: $errorMessage');
      AppSnackBar.showError(context, errorMessage);
      return;
    }

    _log(
      'Latest fulltime order resolved. '
      'orderId=${latestOrder.id}, status=${latestOrder.status.name}, '
      'type=${latestOrder.type.name}, riderStatus=${latestOrder.riderStatus?.name}, '
      'pickupRiderStatus=${latestOrder.pickupRiderStatus?.name}',
    );

    if (_shouldOpenOrderHistory(latestOrder)) {
      _log(
        'Latest order is terminal history state (${latestOrder.status.name}). '
        'Opening order history bottom sheet',
      );
      showOrderHistoryBottomSheet(context, latestOrder);
      return;
    }

    _log('Opening active trip with refreshed order item from orders list');
    context.push(
      '/active-trip/${latestOrder.id}',
      extra: {
        'order': latestOrder,
        'entrySource': 'orders',
      },
    );
  }

  void _showSortBottomSheet() {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OrdersCubit>();
    showOrdersSortBottomSheet(
      context: context,
      l10n: l10n,
      selectedSort: cubit.state.selectedSort,
      onSortSelected: cubit.changeSort,
    );
  }

  String _getSortLabel(AppLocalizations? l10n, SortOption selectedSort) {
    switch (selectedSort) {
      case SortOption.nearest:
        return l10n?.nearest ?? 'Nearest';
      case SortOption.fastestEta:
        return 'Fastest';
      case SortOption.newest:
        return 'Newest';
    }
  }

  void _showAdvancedFilter() {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OrdersCubit>();
    final workingFilterState = cubit.state.filterState.copy();
    showOrdersAdvancedFilterBottomSheet(
      context: context,
      l10n: l10n,
      filterState: workingFilterState,
      areas: cubit.state.areas,
      onApply: () => cubit.applyAdvancedFilters(workingFilterState),
    );
  }

  void _drawerComingSoon(BuildContext context, AppLocalizations? l10n) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n?.comingSoon ?? 'Coming soon')),
    );
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

  bool _shouldOpenOrderHistory(OrderMock order) {
    return order.status == OrderStatusMock.completed ||
        order.status == OrderStatusMock.attemptedDelivery;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = kOrdersPrimaryColor;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return MultiBlocListener(
      listeners: [
        BlocListener<OrdersCubit, OrdersState>(
          listenWhen: (previous, current) =>
              previous.feedbackCounter != current.feedbackCounter &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
        ),
        BlocListener<GoOfflineCubit, GoOfflineState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status != GoOfflineStatus.initial,
          listener: (context, state) async {
            if (state.status == GoOfflineStatus.failure &&
                state.errorMessage != null) {
              AppSnackBar.showError(context, state.errorMessage!);
              context.read<GoOfflineCubit>().resetStatus();
              return;
            }

            if (state.status == GoOfflineStatus.success &&
                state.result != null) {
              await context.read<HeartbeatCubit>().stopHeartbeat(
                    reason: 'Go offline succeeded.',
                  );
              await _persistCourierOnline(state.result!.isOnline);
              if (!context.mounted) return;
              AppSnackBar.showSuccess(
                context,
                state.result!.message ?? 'Driver is offline now.',
              );
              context.read<GoOfflineCubit>().resetStatus();
            }
          },
        ),
        BlocListener<HeartbeatCubit, HeartbeatState>(
          listenWhen: (previous, current) =>
              previous.feedbackCounter != current.feedbackCounter &&
              current.status == HeartbeatStatus.serverForcedOffline,
          listener: (context, state) async {
            await _persistCourierOnline(false);
            if (!context.mounted) return;
            AppSnackBar.showError(
              context,
              state.message ?? 'Please go online first.',
            );
            context.read<HeartbeatCubit>().clearTransientMessage();
          },
        ),
      ],
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final availabilityBusy =
              context.watch<GoOfflineCubit>().state.isLoading;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              context.go('/map-status');
            },
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              drawer: isRtl
                  ? null
                  : OrdersDrawer(
                      theme: theme,
                      l10n: l10n,
                      profilePhoto: _profilePhoto,
                      courierOnline: _courierOnline,
                      onCourierOnlineChanged: _setCourierOnline,
                      availabilityBusy: availabilityBusy,
                      onProfileTap: () {
                        Navigator.of(context).pop();
                        context.push('/home/profile');
                      },
                      onNotificationsTap: () {
                        Navigator.of(context).pop();
                        context.push('/notifications');
                      },
                      onOrdersTap: () {
                        Navigator.of(context).pop();
                        final loc = GoRouterState.of(context).matchedLocation;
                        if (loc != '/orders' && !loc.startsWith('/orders')) {
                          context.go('/orders');
                        }
                      },
                      onSettingsTap: () {
                        Navigator.of(context).pop();
                        context.push('/home/settings');
                      },
                      onComingSoonTap: () => _drawerComingSoon(context, l10n),
                      onLogoutTap: () => _drawerLogout(context, l10n),
                    ),
              endDrawer: isRtl
                  ? OrdersDrawer(
                      theme: theme,
                      l10n: l10n,
                      profilePhoto: _profilePhoto,
                      courierOnline: _courierOnline,
                      onCourierOnlineChanged: _setCourierOnline,
                      availabilityBusy: availabilityBusy,
                      onProfileTap: () {
                        Navigator.of(context).pop();
                        context.push('/home/profile');
                      },
                      onNotificationsTap: () {
                        Navigator.of(context).pop();
                        context.push('/notifications');
                      },
                      onOrdersTap: () {
                        Navigator.of(context).pop();
                        final loc = GoRouterState.of(context).matchedLocation;
                        if (loc != '/orders' && !loc.startsWith('/orders')) {
                          context.go('/orders');
                        }
                      },
                      onSettingsTap: () {
                        Navigator.of(context).pop();
                        context.push('/home/settings');
                      },
                      onComingSoonTap: () => _drawerComingSoon(context, l10n),
                      onLogoutTap: () => _drawerLogout(context, l10n),
                    )
                  : null,
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => context.go('/map-status'),
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
                    icon: Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: _showAdvancedFilter,
                  ),
                ],
              ),
              body: state.isLoading && state.allOrders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        OrdersSummaryBar(
                          todayCount: state.todayCount,
                          activeCount: state.activeCount,
                          doneCount: state.doneCount,
                        ),
                        OrdersStatusSortBar(
                          l10n: l10n,
                          selectedFilter: state.selectedFilter,
                          sortLabel: _getSortLabel(l10n, state.selectedSort),
                          onSortTap: _showSortBottomSheet,
                          onFilterChanged:
                              context.read<OrdersCubit>().changeFilter,
                        ),
                        Expanded(
                          child: OrdersListSection(
                            orders: state.filteredOrders,
                            hasInProgressOrders: state.activeCount > 0,
                            showActiveTaskSection:
                                state.selectedFilter != FilterStatus.all,
                            remainingSectionTitle:
                                state.selectedFilter == FilterStatus.done
                                    ? 'HISTORY'
                                    : 'RECENT ORDERS',
                            onRefresh:
                                context.read<OrdersCubit>().refreshOrders,
                            emptyState: OrdersEmptyState(l10n: l10n),
                            cardBuilder: (order, isActive) => MockOrderCard(
                              order: order,
                              l10n: l10n,
                              primaryColor: primaryColor,
                              isActive: isActive,
                              onOpenActiveTrip: () => _handleOpenOrder(order),
                              onOpenHistory: () =>
                                  showOrderHistoryBottomSheet(context, order),
                              onMarkCompleted: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
