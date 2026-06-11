import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';

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
  assigned,
  inProgress,
  attemptedDelivery,
  completed,
  cancelled,
  unknown,
}

class OrderMock {
  final String id;
  final String? orderNumber;
  final OrderTypeMock type;
  final OrderStatusMock status;
  final String area;
  final String district;
  final DateTime scheduledAt;
  final String customerName;
  final String customerPhone;
  final int? buildingNumber;
  final int? roomNumber;
  final DateTime? createdOn;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final String? laundryName;
  final String? laundryPhone;

  /// Laundry service type in English (e.g. "Carpet Washing", "Laundry", "Iron").
  final String? laundryTypeName;

  /// Laundry service type in Arabic (e.g. "غسيل سجاد", "غسيل", "كوي").
  final String? laundryTypeNameAr;

  /// Line-items for the order (quantity + size/description).
  final List<OrderItemMock>? orderItems;
  final String? itemDescription;

  /// Image URLs attached to the order (customer-provided photos).
  final List<String>? orderImages;
  final double? distanceKm;
  final int? etaMin;
  final double? lat;
  final double? lng;
  final double? sourceLat;
  final double? sourceLng;
  final double? targetLat;
  final double? targetLng;
  final double totalPrice;
  final bool? isCash;
  final String? notes;
  final String? sourceAddress;
  final String? targetAddress;
  final bool? customerHasHanger;
  final MobileRiderStatus? riderStatus;
  final MobilePickupRiderStatus? pickupRiderStatus;

  OrderMock({
    required this.id,
    this.orderNumber,
    required this.type,
    required this.status,
    required this.area,
    required this.district,
    required this.scheduledAt,
    required this.customerName,
    required this.customerPhone,
    this.buildingNumber,
    this.roomNumber,
    this.createdOn,
    this.pickupTime,
    this.deliveryTime,
    this.laundryName,
    this.laundryPhone,
    this.laundryTypeName,
    this.laundryTypeNameAr,
    this.orderItems,
    this.itemDescription,
    this.orderImages,
    this.distanceKm,
    this.etaMin,
    this.lat,
    this.lng,
    this.sourceLat,
    this.sourceLng,
    this.targetLat,
    this.targetLng,
    this.totalPrice = 0,
    this.isCash,
    this.notes,
    this.sourceAddress,
    this.targetAddress,
    this.customerHasHanger,
    this.riderStatus,
    this.pickupRiderStatus,
  });

  OrderMock copyWith({
    OrderStatusMock? status,
  }) {
    return OrderMock(
      id: id,
      orderNumber: orderNumber,
      type: type,
      status: status ?? this.status,
      area: area,
      district: district,
      scheduledAt: scheduledAt,
      customerName: customerName,
      customerPhone: customerPhone,
      buildingNumber: buildingNumber,
      roomNumber: roomNumber,
      createdOn: createdOn,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      laundryName: laundryName,
      laundryPhone: laundryPhone,
      laundryTypeName: laundryTypeName,
      laundryTypeNameAr: laundryTypeNameAr,
      orderItems: orderItems,
      itemDescription: itemDescription,
      orderImages: orderImages,
      distanceKm: distanceKm,
      etaMin: etaMin,
      lat: lat,
      lng: lng,
      sourceLat: sourceLat,
      sourceLng: sourceLng,
      targetLat: targetLat,
      targetLng: targetLng,
      totalPrice: totalPrice,
      isCash: isCash,
      notes: notes,
      sourceAddress: sourceAddress,
      targetAddress: targetAddress,
      customerHasHanger: customerHasHanger,
      riderStatus: riderStatus,
      pickupRiderStatus: pickupRiderStatus,
    );
  }
}
