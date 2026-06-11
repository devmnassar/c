class OrdersQueryParams {
  const OrdersQueryParams({
    this.page,
    this.pageSize,
    this.orderNumber,
    this.customerName,
    this.status,
    this.orderType,
    this.fromDate,
    this.toDate,
  });

  final int? page;
  final int? pageSize;
  final String? orderNumber;
  final String? customerName;
  final int? status;
  final int? orderType;
  final DateTime? fromDate;
  final DateTime? toDate;
}
