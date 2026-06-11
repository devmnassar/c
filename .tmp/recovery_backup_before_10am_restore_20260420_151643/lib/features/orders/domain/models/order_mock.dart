enum OrderTypeMock {
  pickup,
  delivery,
}

/// Single line-item in an order (e.g. "3 Large carpets").
class OrderItemMock {
  final String nameEn;
  final String nameAr;
  final int quantity;

  const OrderItemMock({
    required this.nameEn,
    required this.nameAr,
    required this.quantity,
  });
}

enum OrderStatusMock {
  newOrder,
  inProgress,
  arrivedAtLaundry,
  arrivedAtCustomer,
  completed,
}

class OrderMock {
  final String id;
  final OrderTypeMock type;
  final OrderStatusMock status;
  final String area;
  final String district;
  final DateTime scheduledAt;
  final String customerName;
  final String customerPhone;
  final String? laundryName;
  final String? laundryPhone;

  /// Laundry service type in English (e.g. "Carpet Washing", "Laundry", "Iron").
  final String? laundryTypeName;

  /// Laundry service type in Arabic (e.g. "غسيل سجاد", "غسيل", "كوي").
  final String? laundryTypeNameAr;

  /// Line-items for the order (quantity + size/description).
  final List<OrderItemMock>? orderItems;

  /// Image URLs attached to the order (customer-provided photos).
  final List<String>? orderImages;
  final double distanceKm;
  final int etaMin;
  final double? lat;
  final double? lng;
  final bool? isCash;
  final String? notes;

  OrderMock({
    required this.id,
    required this.type,
    required this.status,
    required this.area,
    required this.district,
    required this.scheduledAt,
    required this.customerName,
    required this.customerPhone,
    this.laundryName,
    this.laundryPhone,
    this.laundryTypeName,
    this.laundryTypeNameAr,
    this.orderItems,
    this.orderImages,
    required this.distanceKm,
    required this.etaMin,
    this.lat,
    this.lng,
    this.isCash,
    this.notes,
  });

  OrderMock copyWith({
    OrderStatusMock? status,
  }) {
    return OrderMock(
      id: id,
      type: type,
      status: status ?? this.status,
      area: area,
      district: district,
      scheduledAt: scheduledAt,
      customerName: customerName,
      customerPhone: customerPhone,
      laundryName: laundryName,
      laundryPhone: laundryPhone,
      laundryTypeName: laundryTypeName,
      laundryTypeNameAr: laundryTypeNameAr,
      orderItems: orderItems,
      orderImages: orderImages,
      distanceKm: distanceKm,
      etaMin: etaMin,
      lat: lat,
      lng: lng,
      isCash: isCash,
      notes: notes,
    );
  }
}
