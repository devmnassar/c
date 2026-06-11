import 'mobile_order.dart';

class OrdersPageResult {
  const OrdersPageResult({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.orders,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<MobileOrder> orders;
}
