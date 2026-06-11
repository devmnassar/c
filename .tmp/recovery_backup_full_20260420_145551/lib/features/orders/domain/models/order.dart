enum OrderType {
  pickup,
  dropoff,
}

enum OrderStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class Order {
  final String id;
  final OrderType orderType;
  final OrderStatus status;
  final DateTime scheduledDateTime;
  final String area;
  final String district;
  final String customerName;
  final String customerPhone;
  final double? lat;
  final double? lng;
  final String? notes;
  final List<String> homePhotos;
  final List<String> clothesPhotos;

  Order({
    required this.id,
    required this.orderType,
    required this.status,
    required this.scheduledDateTime,
    required this.area,
    required this.district,
    required this.customerName,
    required this.customerPhone,
    this.lat,
    this.lng,
    this.notes,
    this.homePhotos = const [],
    this.clothesPhotos = const [],
  });

  bool get hasLocation => lat != null && lng != null;
}
