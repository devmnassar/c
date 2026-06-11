import '../../domain/models/order_mock.dart';
import '../models/orders_filters.dart';

class OrdersFilteringHelper {
  static List<OrderMock> applyFiltersAndSort({
    required List<OrderMock> allOrders,
    required FilterStatus selectedFilter,
    required OrdersFilterState filterState,
    required SortOption selectedSort,
  }) {
    List<OrderMock> filtered = List<OrderMock>.from(allOrders);

    switch (selectedFilter) {
      case FilterStatus.all:
        break;
      case FilterStatus.newOrder:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.newOrder)
            .toList();
        break;
      case FilterStatus.assigned:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.assigned)
            .toList();
        break;
      case FilterStatus.active:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.inProgress)
            .toList();
        break;
      case FilterStatus.attemptedDelivery:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.attemptedDelivery)
            .toList();
        break;
      case FilterStatus.done:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.completed)
            .toList();
        break;
      case FilterStatus.cancelled:
        filtered = filtered
            .where((o) => o.status == OrderStatusMock.cancelled)
            .toList();
        break;
    }

    if (filterState.types.isNotEmpty) {
      filtered =
          filtered.where((o) => filterState.types.contains(o.type)).toList();
    }

    filtered = filtered
        .where((o) => o.distanceKm == null || o.distanceKm! <= filterState.maxDistance)
        .toList();

    if (filterState.selectedArea != null) {
      filtered =
          filtered.where((o) => o.area == filterState.selectedArea).toList();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (filterState.dateFilter) {
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
        break;
    }

    switch (selectedSort) {
      case SortOption.nearest:
        filtered.sort((a, b) {
          final aDistance = a.distanceKm ?? double.infinity;
          final bDistance = b.distanceKm ?? double.infinity;
          return aDistance.compareTo(bDistance);
        });
        break;
      case SortOption.fastestEta:
        filtered.sort((a, b) {
          final aEta = a.etaMin ?? 1 << 30;
          final bEta = b.etaMin ?? 1 << 30;
          return aEta.compareTo(bEta);
        });
        break;
      case SortOption.newest:
        filtered.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        break;
    }

    return filtered;
  }

  static int getTodayOrdersCount(List<OrderMock> allOrders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return allOrders.where((o) {
      final createdAt = _todayReferenceDate(o);
      return !createdAt.isBefore(todayStart) && createdAt.isBefore(todayEnd);
    }).length;
  }

  static int getCountByStatus(
      List<OrderMock> allOrders, OrderStatusMock status) {
    return allOrders.where((o) => o.status == status).length;
  }

  static DateTime _todayReferenceDate(OrderMock order) {
    return order.createdOn ?? order.scheduledAt;
  }
}
