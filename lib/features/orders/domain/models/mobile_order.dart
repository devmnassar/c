enum MobileOrderType {
  pickup,
  delivery,
  unknown,
}

enum MobileOrderStatus {
  newOrder,
  assigned,
  inProgress,
  deliveryAttempted,
  delivered,
  cancelled,
  unknown,
}

enum MobileRiderStatus {
  enRouteToLaundry,
  arrivedAtLaundry,
  pickedUp,
  enRouteToCustomer,
  arrivedAtCustomer,
  delivered,
  attemptedDelivery,
  unknown,
}

enum MobilePickupRiderStatus {
  enRouteToCustomer,
  arrivedAtCustomer,
  pickedUp,
  enRouteToLaundry,
  arrivedAtLaundry,
  droppedOffAtLaundry,
  unknown,
}

enum MobilePaymentMethod {
  online,
  cash,
  unknown,
}

enum MobileDeliveryType {
  sixHour,
  twelveHour,
  unknown,
}

class MobileOrderItem {
  const MobileOrderItem({
    required this.id,
    required this.orderServiceId,
    required this.serviceNameEn,
    required this.serviceNameAr,
    required this.nameEn,
    required this.nameAr,
    required this.quantity,
  });

  final int id;
  final int orderServiceId;
  final String serviceNameEn;
  final String serviceNameAr;
  final String nameEn;
  final String nameAr;
  final int quantity;
}

class MobileOrder {
  const MobileOrder({
    required this.id,
    required this.orderNumber,
    required this.orderTrackingId,
    required this.customerId,
    required this.customerFullName,
    required this.customerPhoneNumber,
    required this.buildingNumber,
    required this.roomNumber,
    required this.orderType,
    required this.status,
    required this.paymentMethod,
    required this.deliveryType,
    required this.countryCode,
    required this.countryName,
    required this.sourceCode,
    required this.sourceAddress,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.targetAddress,
    required this.targetLatitude,
    required this.targetLongitude,
    this.distanceKm,
    this.etaMinutes,
    this.polyline,
    required this.totalPrice,
    required this.createdOn,
    required this.isActive,
    required this.subServices,
    this.assignmentId,
    this.assignedAt,
    this.riderStatus,
    this.pickupRiderStatus,
    this.laundryName,
    this.laundryPhoneNumber,
    this.pickupTime,
    this.deliveryTime,
    this.changedOn,
    this.customerNote,
    this.itemDescription,
    this.customerHasHanger,
  });

  final int id;
  final int orderNumber;
  final String orderTrackingId;
  final int customerId;
  final String customerFullName;
  final String customerPhoneNumber;
  final int buildingNumber;
  final int roomNumber;
  final int? assignmentId;
  final DateTime? assignedAt;
  final MobileOrderType orderType;
  final MobileOrderStatus status;
  final MobileRiderStatus? riderStatus;
  final MobilePickupRiderStatus? pickupRiderStatus;
  final MobilePaymentMethod paymentMethod;
  final MobileDeliveryType deliveryType;
  final String countryCode;
  final String countryName;
  final String sourceCode;
  final String sourceAddress;
  final double sourceLatitude;
  final double sourceLongitude;
  final String targetAddress;
  final double targetLatitude;
  final double targetLongitude;
  final double? distanceKm;
  final int? etaMinutes;
  final String? polyline;
  final double totalPrice;
  final String? laundryName;
  final String? laundryPhoneNumber;
  final DateTime createdOn;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DateTime? changedOn;
  final bool isActive;
  final List<MobileOrderItem> subServices;
  final String? customerNote;
  final String? itemDescription;
  final bool? customerHasHanger;
}
