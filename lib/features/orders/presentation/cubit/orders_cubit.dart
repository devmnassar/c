import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/features/incoming/data/mappers/mobile_order_to_order_mock_mapper.dart';

import '../../../../core/networking/api_exception.dart';
import '../../domain/models/order_mock.dart';
import '../../domain/models/orders_query_params.dart';
import '../../domain/usecases/get_orders_use_case.dart';
import '../helpers/orders_filtering_helper.dart';
import '../models/orders_filters.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({
    required GetOrdersUseCase getOrdersUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        super(OrdersState.initial());

  final GetOrdersUseCase _getOrdersUseCase;
  bool _loadingInProgress = false;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('================ ORDERS CUBIT ================');
    debugPrint('[ORDERS CUBIT] $message');
  }

  Future<void> loadOrders({bool forceRefresh = false}) async {
    if (_loadingInProgress) {
      _log('loadOrders ignored because another request is already running');
      return;
    }

    final hasVisibleOrders = state.allOrders.isNotEmpty;
    final currentSignature = _buildOrdersSignature(state.allOrders);

    _loadingInProgress = true;
    _log(
      'loadOrders started. forceRefresh=$forceRefresh, '
      'hasVisibleOrders=$hasVisibleOrders',
    );
    if (!hasVisibleOrders) {
      emit(
        state.copyWith(
          status: OrdersStatus.loading,
          isLoading: true,
          clearErrorMessage: true,
        ),
      );
    }

    ApiException? failure;
    final List<OrderMock> allOrders = <OrderMock>[];
    int currentPage = 1;
    int totalPages = 1;

    do {
      _log('Requesting orders page=$currentPage pageSize=100');
      final result = await _getOrdersUseCase(
        query: OrdersQueryParams(
          page: currentPage,
          pageSize: 100,
        ),
      );

      final pageResult = result.fold((error) {
        _log('Orders page=$currentPage failed: ${error.message}');
        failure = error;
        return null;
      }, (value) => value);

      if (pageResult == null) {
        break;
      }

      if (pageResult.orders.isEmpty && currentPage == 1) {
        _log('Orders API returned empty first page');
        break;
      }

      _log(
        'Orders page=$currentPage succeeded with count=${pageResult.orders.length} '
        'totalPages=${pageResult.totalPages}',
      );
      allOrders.addAll(pageResult.orders.map(fromMobileOrder));
      totalPages = pageResult.totalPages <= 0 ? 1 : pageResult.totalPages;
      currentPage++;
    } while (currentPage <= totalPages);

    _loadingInProgress = false;

    if (failure != null) {
      _log('loadOrders finished with failure: ${failure!.message}');
      emit(
        state.copyWith(
          status: OrdersStatus.failure,
          isLoading: false,
          errorMessage: failure!.message,
          feedbackCounter: state.feedbackCounter + 1,
        ),
      );
      return;
    }

    final nextSignature = _buildOrdersSignature(allOrders);
    if (forceRefresh ||
        !hasVisibleOrders ||
        nextSignature != currentSignature) {
      _log('Emitting refreshed orders list. totalOrders=${allOrders.length}');
      _emitOrdersLoaded(allOrders);
      return;
    }

    _log('Orders signature unchanged. Emitting success without replacing list');
    emit(
      state.copyWith(
        status: OrdersStatus.success,
        isLoading: false,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> refreshOrders() => loadOrders(forceRefresh: true);

  Future<OrderMock?> refreshAndFindOrderById(String orderId) async {
    _log('refreshAndFindOrderById started for orderId=$orderId');
    await loadOrders(forceRefresh: true);

    if (state.status == OrdersStatus.failure) {
      _log(
        'refreshAndFindOrderById stopped because orders refresh failed. '
        'error=${state.errorMessage}',
      );
      return null;
    }

    OrderMock? selectedOrder;
    for (final order in state.allOrders) {
      if (order.id == orderId) {
        selectedOrder = order;
        break;
      }
    }

    if (selectedOrder == null) {
      _log(
          'refreshAndFindOrderById could not find orderId=$orderId in refreshed list');
      return null;
    }

    _log(
      'refreshAndFindOrderById resolved orderId=${selectedOrder.id}, '
      'status=${selectedOrder.status.name}, type=${selectedOrder.type.name}, '
      'riderStatus=${selectedOrder.riderStatus?.name}, '
      'pickupRiderStatus=${selectedOrder.pickupRiderStatus?.name}',
    );
    return selectedOrder;
  }

  void changeFilter(FilterStatus nextFilter) {
    final nextFilterState = state.filterState.copy()..status = nextFilter;
    _emitWithFilters(
      selectedFilter: nextFilter,
      filterState: nextFilterState,
    );
  }

  void changeSort(SortOption nextSort) {
    _emitWithFilters(selectedSort: nextSort);
  }

  void applyAdvancedFilters(OrdersFilterState nextFilterState) {
    _emitWithFilters(
      selectedFilter: nextFilterState.status,
      filterState: nextFilterState.copy(),
    );
  }

  void _emitOrdersLoaded(List<OrderMock> orders) {
    final filteredOrders = OrdersFilteringHelper.applyFiltersAndSort(
      allOrders: orders,
      selectedFilter: state.selectedFilter,
      filterState: state.filterState,
      selectedSort: state.selectedSort,
    );

    emit(
      state.copyWith(
        status: OrdersStatus.success,
        isLoading: false,
        allOrders: orders,
        filteredOrders: filteredOrders,
        clearErrorMessage: true,
      ),
    );
  }

  void _emitWithFilters({
    FilterStatus? selectedFilter,
    SortOption? selectedSort,
    OrdersFilterState? filterState,
  }) {
    final nextSelectedFilter = selectedFilter ?? state.selectedFilter;
    final nextSelectedSort = selectedSort ?? state.selectedSort;
    final nextFilterState = filterState ?? state.filterState.copy();
    final filteredOrders = OrdersFilteringHelper.applyFiltersAndSort(
      allOrders: state.allOrders,
      selectedFilter: nextSelectedFilter,
      filterState: nextFilterState,
      selectedSort: nextSelectedSort,
    );

    emit(
      state.copyWith(
        status: OrdersStatus.success,
        selectedFilter: nextSelectedFilter,
        selectedSort: nextSelectedSort,
        filterState: nextFilterState,
        filteredOrders: filteredOrders,
        clearErrorMessage: true,
      ),
    );
  }

  String _buildOrdersSignature(List<OrderMock> orders) {
    return orders
        .map(
          (order) => [
            order.id,
            order.orderNumber ?? '',
            order.status.name,
            order.type.name,
            order.riderStatus?.name ?? '',
            order.pickupRiderStatus?.name ?? '',
            order.scheduledAt.toIso8601String(),
            order.customerName,
            order.isCash?.toString() ?? '',
          ].join('|'),
        )
        .join('||');
  }
}
