import '../../domain/models/order_mock.dart';

enum FilterStatus {
  all,
  newOrder,
  assigned,
  active,
  attemptedDelivery,
  done,
  cancelled
}

enum SortOption { nearest, fastestEta, newest }

enum DateFilter { today, tomorrow, custom }

class OrdersFilterState {
  FilterStatus status;
  Set<OrderTypeMock> types;
  double maxDistance;
  DateFilter dateFilter;
  String? selectedArea;

  OrdersFilterState({
    this.status = FilterStatus.all,
    Set<OrderTypeMock>? types,
    this.maxDistance = 20.0,
    this.dateFilter = DateFilter.custom,
    this.selectedArea,
  }) : types = types ?? <OrderTypeMock>{};

  OrdersFilterState copy() {
    return OrdersFilterState(
      status: status,
      types: Set<OrderTypeMock>.from(types),
      maxDistance: maxDistance,
      dateFilter: dateFilter,
      selectedArea: selectedArea,
    );
  }

  void restoreFrom(OrdersFilterState other) {
    status = other.status;
    types = Set<OrderTypeMock>.from(other.types);
    maxDistance = other.maxDistance;
    dateFilter = other.dateFilter;
    selectedArea = other.selectedArea;
  }
}
