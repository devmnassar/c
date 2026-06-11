import '../../domain/models/mobile_order.dart';

class MobileOrderModel {
  const MobileOrderModel({
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
  final int orderType;
  final int status;
  final int? riderStatus;
  final int? pickupRiderStatus;
  final int paymentMethod;
  final int deliveryType;
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
  final List<MobileOrderItemModel> subServices;
  final String? customerNote;
  final String? itemDescription;
  final bool? customerHasHanger;

  factory MobileOrderModel.fromJson(Map<String, dynamic> json) {
    return MobileOrderModel(
      id: _readInt(json['orderId'] ?? json['id']),
      orderNumber: _readInt(json['orderNumber']),
      orderTrackingId: (json['orderTrackingId'] as String?)?.trim() ?? '',
      customerId: _readInt(json['customerId']),
      customerFullName: (json['customerFullName'] as String?)?.trim() ?? '',
      customerPhoneNumber:
          (json['customerPhoneNumber'] as String?)?.trim() ?? '',
      buildingNumber: _readInt(json['buildingNumber']),
      roomNumber: _readInt(json['roomNumber']),
      assignmentId: _readNullableInt(json['assignmentId']),
      assignedAt: _readDateTime(json['assignedAt']),
      orderType: _readInt(json['orderType']),
      status: _readInt(json['status']),
      riderStatus: _readNullableInt(json['riderStatus']),
      pickupRiderStatus: _readNullableInt(json['pickupRiderStatus']),
      paymentMethod: _readInt(json['paymentMethod']),
      deliveryType: _readInt(json['deliveryType']),
      countryCode: (json['countryCode'] as String?)?.trim() ?? '',
      countryName: (json['countryName'] as String?)?.trim() ?? '',
      sourceCode: (json['sourceCode'] as String?)?.trim() ?? '',
      sourceAddress: (json['sourceAddress'] as String?)?.trim() ?? '',
      sourceLatitude: _readDouble(json['sourceLatitude']),
      sourceLongitude: _readDouble(json['sourceLongitude']),
      targetAddress: (json['targetAddress'] as String?)?.trim() ?? '',
      targetLatitude: _readDouble(json['targetLatitude']),
      targetLongitude: _readDouble(json['targetLongitude']),
      distanceKm: _readNullableDouble(json['distanceKm']),
      etaMinutes: _readNullableInt(json['etaMinutes']),
      polyline: (json['polyline'] as String?)?.trim(),
      totalPrice: _readDouble(json['totalPrice']),
      laundryName: (json['laundryName'] as String?)?.trim(),
      laundryPhoneNumber: (json['laundryPhoneNumber'] as String?)?.trim(),
      createdOn: _readDateTime(json['createdOn']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      pickupTime: _readDateTime(json['pickupTime']),
      deliveryTime: _readDateTime(json['deliveryTime']),
      changedOn: _readDateTime(json['changedOn']),
      isActive: _readBool(json['isActive']),
      subServices: _readSubServices(json['subServices']),
      customerNote: (json['customerNote'] as String?)?.trim(),
      itemDescription: (json['itemDescription'] as String?)?.trim(),
      customerHasHanger: json['customerHasHanger'] == null
          ? null
          : _readBool(json['customerHasHanger']),
    );
  }

  MobileOrder toEntity() {
    return MobileOrder(
      id: id,
      orderNumber: orderNumber,
      orderTrackingId: orderTrackingId,
      customerId: customerId,
      customerFullName: customerFullName,
      customerPhoneNumber: customerPhoneNumber,
      buildingNumber: buildingNumber,
      roomNumber: roomNumber,
      assignmentId: assignmentId,
      assignedAt: assignedAt,
      orderType: _mapOrderType(orderType),
      status: _mapOrderStatus(status),
      riderStatus: _mapRiderStatus(riderStatus),
      pickupRiderStatus: _mapPickupRiderStatus(pickupRiderStatus),
      paymentMethod: _mapPaymentMethod(paymentMethod),
      deliveryType: _mapDeliveryType(deliveryType),
      countryCode: countryCode,
      countryName: countryName,
      sourceCode: sourceCode,
      sourceAddress: sourceAddress,
      sourceLatitude: sourceLatitude,
      sourceLongitude: sourceLongitude,
      targetAddress: targetAddress,
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      polyline: polyline,
      totalPrice: totalPrice,
      laundryName: laundryName,
      laundryPhoneNumber: laundryPhoneNumber,
      createdOn: createdOn,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      changedOn: changedOn,
      isActive: isActive,
      subServices: subServices.map((item) => item.toEntity()).toList(),
      customerNote: customerNote,
      itemDescription: itemDescription,
      customerHasHanger: customerHasHanger,
    );
  }

  static List<MobileOrderItemModel> _readSubServices(dynamic value) {
    if (value is! List) {
      return const <MobileOrderItemModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(MobileOrderItemModel.fromJson)
        .toList();
  }

  static MobileOrderType _mapOrderType(int value) {
    switch (value) {
      case 1:
        return MobileOrderType.pickup;
      case 2:
        return MobileOrderType.delivery;
      default:
        return MobileOrderType.unknown;
    }
  }

  static MobileOrderStatus _mapOrderStatus(int value) {
    switch (value) {
      case 1:
        return MobileOrderStatus.newOrder;
      case 5:
        return MobileOrderStatus.assigned;
      case 6:
        return MobileOrderStatus.inProgress;
      case 7:
        return MobileOrderStatus.deliveryAttempted;
      case 8:
        return MobileOrderStatus.delivered;
      case 9:
        return MobileOrderStatus.cancelled;
      case 2:
        return MobileOrderStatus.assigned;
      case 3:
        return MobileOrderStatus.inProgress;
      case 4:
        return MobileOrderStatus.delivered;
      default:
        return MobileOrderStatus.unknown;
    }
  }

  static MobileRiderStatus? _mapRiderStatus(int? value) {
    if (value == null) return null;
    switch (value) {
      case 1:
        return MobileRiderStatus.enRouteToLaundry;
      case 2:
        return MobileRiderStatus.arrivedAtLaundry;
      case 3:
        return MobileRiderStatus.pickedUp;
      case 4:
        return MobileRiderStatus.enRouteToCustomer;
      case 5:
        return MobileRiderStatus.arrivedAtCustomer;
      case 6:
        return MobileRiderStatus.delivered;
      case 7:
        return MobileRiderStatus.attemptedDelivery;
      default:
        return MobileRiderStatus.unknown;
    }
  }

  static MobilePickupRiderStatus? _mapPickupRiderStatus(int? value) {
    if (value == null) return null;
    switch (value) {
      case 1:
        return MobilePickupRiderStatus.enRouteToCustomer;
      case 2:
        return MobilePickupRiderStatus.arrivedAtCustomer;
      case 3:
        return MobilePickupRiderStatus.pickedUp;
      case 4:
        return MobilePickupRiderStatus.enRouteToLaundry;
      case 5:
        return MobilePickupRiderStatus.arrivedAtLaundry;
      case 6:
        return MobilePickupRiderStatus.droppedOffAtLaundry;
      default:
        return MobilePickupRiderStatus.unknown;
    }
  }

  static MobilePaymentMethod _mapPaymentMethod(int value) {
    switch (value) {
      case 1:
        return MobilePaymentMethod.online;
      case 2:
        return MobilePaymentMethod.cash;
      default:
        return MobilePaymentMethod.unknown;
    }
  }

  static MobileDeliveryType _mapDeliveryType(int value) {
    switch (value) {
      case 1:
        return MobileDeliveryType.sixHour;
      case 2:
        return MobileDeliveryType.twelveHour;
      default:
        return MobileDeliveryType.unknown;
    }
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    return _readDouble(value);
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}

class MobileOrderItemModel {
  const MobileOrderItemModel({
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

  factory MobileOrderItemModel.fromJson(Map<String, dynamic> json) {
    return MobileOrderItemModel(
      id: MobileOrderModel._readInt(json['id']),
      orderServiceId: MobileOrderModel._readInt(json['orderServiceId']),
      serviceNameEn: (json['serviceNameEn'] as String?)?.trim() ?? '',
      serviceNameAr: (json['serviceNameAr'] as String?)?.trim() ?? '',
      nameEn: (json['nameEn'] as String?)?.trim() ?? '',
      nameAr: (json['nameAr'] as String?)?.trim() ?? '',
      quantity: MobileOrderModel._readInt(json['quantity']),
    );
  }

  MobileOrderItem toEntity() {
    return MobileOrderItem(
      id: id,
      orderServiceId: orderServiceId,
      serviceNameEn: serviceNameEn,
      serviceNameAr: serviceNameAr,
      nameEn: nameEn,
      nameAr: nameAr,
      quantity: quantity,
    );
  }
}
