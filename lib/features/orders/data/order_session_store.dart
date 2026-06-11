import '../domain/models/order_mock.dart';

class OrderSessionStore {
  static final Map<String, OrderMock> _ordersById = <String, OrderMock>{};
  static List<OrderMock> _orders = <OrderMock>[];
  static DateTime? _lastUpdatedAt;

  static void replaceAll(Iterable<OrderMock> orders) {
    final nextOrders = List<OrderMock>.unmodifiable(orders.toList());
    _orders = nextOrders;
    _ordersById
      ..clear()
      ..addEntries(nextOrders.map((order) => MapEntry(order.id, order)));
    _lastUpdatedAt = DateTime.now();
  }

  static void upsert(OrderMock order) {
    final nextOrders = List<OrderMock>.from(_orders);
    final index = nextOrders.indexWhere((item) => item.id == order.id);
    if (index >= 0) {
      nextOrders[index] = order;
    } else {
      nextOrders.add(order);
    }
    replaceAll(nextOrders);
  }

  static OrderMock? getById(String id) => _ordersById[id];

  static List<OrderMock> getAll() => List<OrderMock>.unmodifiable(_orders);

  static bool get hasOrders => _orders.isNotEmpty;

  static DateTime? get lastUpdatedAt => _lastUpdatedAt;

  static bool isFresh(Duration maxAge) {
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= maxAge;
  }
}
