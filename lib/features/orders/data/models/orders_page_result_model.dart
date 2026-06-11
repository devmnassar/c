import '../../domain/models/orders_page_result.dart';
import 'mobile_order_model.dart';

class OrdersPageResultModel {
  const OrdersPageResultModel({
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
  final List<MobileOrderModel> orders;

  factory OrdersPageResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['data'] ?? <dynamic>[];
    final list = rawItems is List ? rawItems : <dynamic>[];

    return OrdersPageResultModel(
      page: _readInt(json['page']),
      pageSize: _readInt(json['pageSize']),
      totalCount: _readInt(json['totalCount']),
      totalPages: _readInt(json['totalPages']),
      orders: list
          .whereType<Map<String, dynamic>>()
          .map(MobileOrderModel.fromJson)
          .toList(),
    );
  }

  OrdersPageResult toEntity() {
    return OrdersPageResult(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
      orders: orders.map((order) => order.toEntity()).toList(),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
