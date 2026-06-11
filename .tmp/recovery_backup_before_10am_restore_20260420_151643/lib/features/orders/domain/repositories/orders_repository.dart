import '../models/order.dart';

abstract class OrdersRepository {
  Future<List<Order>> getTodayOrders();
  Future<List<Order>> getUpcomingOrders();
  Future<List<Order>> getCompletedOrders();
  Future<Order?> getOrderById(String id);
  Future<List<Order>> searchOrders(String query);
}
