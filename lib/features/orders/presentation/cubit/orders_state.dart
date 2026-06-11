part of 'orders_cubit.dart';

enum OrdersStatus { initial, loading, success, failure }

class OrdersState {
  OrdersState({
    required this.status,
    required this.allOrders,
    required this.filteredOrders,
    required this.selectedFilter,
    required this.selectedSort,
    required this.filterState,
    required this.isLoading,
    required this.feedbackCounter,
    this.errorMessage,
  });

  factory OrdersState.initial({
    List<OrderMock> initialOrders = const <OrderMock>[],
  }) {
    final filterState = OrdersFilterState();
    final selectedFilter = FilterStatus.all;
    final selectedSort = SortOption.nearest;
    return OrdersState(
      status: OrdersStatus.initial,
      allOrders: initialOrders,
      filteredOrders: OrdersFilteringHelper.applyFiltersAndSort(
        allOrders: initialOrders,
        selectedFilter: selectedFilter,
        filterState: filterState,
        selectedSort: selectedSort,
      ),
      selectedFilter: selectedFilter,
      selectedSort: selectedSort,
      filterState: filterState,
      isLoading: false,
      feedbackCounter: 0,
    );
  }

  final OrdersStatus status;
  final List<OrderMock> allOrders;
  final List<OrderMock> filteredOrders;
  final FilterStatus selectedFilter;
  final SortOption selectedSort;
  final OrdersFilterState filterState;
  final bool isLoading;
  final String? errorMessage;
  final int feedbackCounter;

  int get todayCount => OrdersFilteringHelper.getTodayOrdersCount(allOrders);

  int get activeCount => OrdersFilteringHelper.getCountByStatus(
      allOrders, OrderStatusMock.inProgress);

  int get doneCount => OrdersFilteringHelper.getCountByStatus(
      allOrders, OrderStatusMock.completed);

  List<String> get areas =>
      allOrders.map((order) => order.area).toSet().toList()..sort();

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderMock>? allOrders,
    List<OrderMock>? filteredOrders,
    FilterStatus? selectedFilter,
    SortOption? selectedSort,
    OrdersFilterState? filterState,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? feedbackCounter,
  }) {
    return OrdersState(
      status: status ?? this.status,
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSort: selectedSort ?? this.selectedSort,
      filterState: filterState ?? this.filterState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
    );
  }
}
