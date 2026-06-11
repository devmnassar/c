import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';

class MobileOrderOfferModel {
  const MobileOrderOfferModel({
    required this.offerId,
    required this.orderId,
    required this.orderNumber,
    this.orderTrackingId,
    this.offeredAt,
    required this.expiresAt,
    required this.serverTimeUtc,
    required this.remainingSeconds,
    required this.attemptNumber,
    required this.bonusAmount,
    this.effectiveTotalPrice,
    this.customerId,
    required this.customerFullName,
    required this.customerPhoneNumber,
    this.buildingNumber,
    this.roomNumber,
    this.customerHasHanger,
    this.customerNote,
    required this.orderType,
    required this.orderStatus,
    this.paymentMethod,
    this.deliveryType,
    this.countryCode,
    this.countryName,
    this.sourceCode,
    this.laundryName,
    this.laundryPhoneNumber,
    required this.sourceAddress,
    required this.targetAddress,
    this.distanceKm,
    this.etaMinutes,
    required this.totalPrice,
    this.itemDescription,
    this.createdOn,
    this.pickupTime,
    this.deliveryTime,
    this.subServices = const <MobileOrderOfferSubServiceModel>[],
    this.sourceLatitude,
    this.sourceLongitude,
    this.targetLatitude,
    this.targetLongitude,
  });

  final int offerId;
  final int orderId;
  final int orderNumber;
  final String? orderTrackingId;
  final DateTime? offeredAt;
  final DateTime? expiresAt;
  final DateTime? serverTimeUtc;
  final int remainingSeconds;
  final int attemptNumber;
  final double bonusAmount;
  final double? effectiveTotalPrice;
  final int? customerId;
  final String customerFullName;
  final String customerPhoneNumber;
  final int? buildingNumber;
  final int? roomNumber;
  final bool? customerHasHanger;
  final String? customerNote;
  final int orderType;
  final int orderStatus;
  final int? paymentMethod;
  final int? deliveryType;
  final String? countryCode;
  final String? countryName;
  final String? sourceCode;
  final String? laundryName;
  final String? laundryPhoneNumber;
  final String sourceAddress;
  final String targetAddress;
  final double? distanceKm;
  final int? etaMinutes;
  final double totalPrice;
  final String? itemDescription;
  final DateTime? createdOn;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final List<MobileOrderOfferSubServiceModel> subServices;
  final double? sourceLatitude;
  final double? sourceLongitude;
  final double? targetLatitude;
  final double? targetLongitude;

  factory MobileOrderOfferModel.fromJson(Map<String, dynamic> json) {
    return MobileOrderOfferModel(
      offerId: _readInt(json['offerId']),
      orderId: _readInt(json['orderId']),
      orderNumber: _readInt(json['orderNumber']),
      orderTrackingId: (json['orderTrackingId'] as String?)?.trim(),
      offeredAt: _readDateTime(json['offeredAt']),
      expiresAt: _readDateTime(json['expiresAt']),
      serverTimeUtc: _readDateTime(json['serverTimeUtc']),
      remainingSeconds: _readInt(json['remainingSeconds']),
      attemptNumber: _readInt(json['attemptNumber']),
      bonusAmount: _readDouble(json['bonusAmount']),
      effectiveTotalPrice: _readNullableDouble(json['effectiveTotalPrice']),
      customerId: _readNullableInt(json['customerId']),
      customerFullName: (json['customerFullName'] as String?)?.trim() ?? '',
      customerPhoneNumber:
          (json['customerPhoneNumber'] as String?)?.trim() ?? '',
      buildingNumber: _readNullableInt(json['buildingNumber']),
      roomNumber: _readNullableInt(json['roomNumber']),
      customerHasHanger: json['customerHasHanger'] as bool?,
      customerNote: (json['customerNote'] as String?)?.trim(),
      orderType: _readInt(json['orderType']),
      orderStatus: _readInt(json['orderStatus']),
      paymentMethod: _readNullableInt(json['paymentMethod']),
      deliveryType: _readNullableInt(json['deliveryType']),
      countryCode: (json['countryCode'] as String?)?.trim(),
      countryName: (json['countryName'] as String?)?.trim(),
      sourceCode: (json['sourceCode'] as String?)?.trim(),
      laundryName: (json['laundryName'] as String?)?.trim(),
      laundryPhoneNumber: (json['laundryPhoneNumber'] as String?)?.trim(),
      sourceAddress: (json['sourceAddress'] as String?)?.trim() ?? '',
      targetAddress: (json['targetAddress'] as String?)?.trim() ?? '',
      distanceKm: _readNullableDouble(json['distanceKm']),
      etaMinutes: _readNullableInt(json['etaMinutes']),
      totalPrice: _readDouble(json['totalPrice']),
      itemDescription: (json['itemDescription'] as String?)?.trim(),
      createdOn: _readDateTime(json['createdOn']),
      pickupTime: _readDateTime(json['pickupTime']),
      deliveryTime: _readDateTime(json['deliveryTime']),
      subServices: _readSubServices(json['subServices']),
      sourceLatitude: _readNullableDouble(
        json['sourceLatitude'] ?? json['sourceLat'],
      ),
      sourceLongitude: _readNullableDouble(
        json['sourceLongitude'] ?? json['sourceLng'],
      ),
      targetLatitude: _readNullableDouble(
        json['targetLatitude'] ?? json['targetLat'],
      ),
      targetLongitude: _readNullableDouble(
        json['targetLongitude'] ?? json['targetLng'],
      ),
    );
  }

  MobileOrderOffer toEntity() {
    return MobileOrderOffer(
      offerId: offerId,
      orderId: orderId,
      orderNumber: orderNumber,
      orderTrackingId: orderTrackingId,
      offeredAt: offeredAt,
      expiresAt: expiresAt,
      serverTimeUtc: serverTimeUtc,
      remainingSeconds: remainingSeconds,
      attemptNumber: attemptNumber,
      bonusAmount: bonusAmount,
      effectiveTotalPrice: effectiveTotalPrice,
      customerId: customerId,
      customerFullName: customerFullName,
      customerPhoneNumber: customerPhoneNumber,
      buildingNumber: buildingNumber,
      roomNumber: roomNumber,
      customerHasHanger: customerHasHanger,
      customerNote: customerNote,
      orderType: _mapOrderType(orderType),
      orderStatus: _mapOrderStatus(orderStatus),
      paymentMethod: _mapPaymentMethod(paymentMethod),
      deliveryType: deliveryType,
      countryCode: countryCode,
      countryName: countryName,
      sourceCode: sourceCode,
      laundryName: laundryName,
      laundryPhoneNumber: laundryPhoneNumber,
      sourceAddress: sourceAddress,
      targetAddress: targetAddress,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      totalPrice: totalPrice,
      itemDescription: itemDescription,
      createdOn: createdOn,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      subServices: subServices.map((item) => item.toEntity()).toList(),
      sourceLatitude: sourceLatitude,
      sourceLongitude: sourceLongitude,
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
    );
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return _readDouble(value);
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return _readInt(value);
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<MobileOrderOfferSubServiceModel> _readSubServices(dynamic value) {
    if (value is! List) {
      return const <MobileOrderOfferSubServiceModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(MobileOrderOfferSubServiceModel.fromJson)
        .toList(growable: false);
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

  static MobilePaymentMethod? _mapPaymentMethod(int? value) {
    switch (value) {
      case 1:
        return MobilePaymentMethod.online;
      case 2:
        return MobilePaymentMethod.cash;
      default:
        return null;
    }
  }
}

class MobileOrderOfferSubServiceModel {
  const MobileOrderOfferSubServiceModel({
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

  factory MobileOrderOfferSubServiceModel.fromJson(Map<String, dynamic> json) {
    return MobileOrderOfferSubServiceModel(
      id: MobileOrderOfferModel._readInt(json['id']),
      orderServiceId: MobileOrderOfferModel._readInt(json['orderServiceId']),
      serviceNameEn: (json['serviceNameEn'] as String?)?.trim() ?? '',
      serviceNameAr: (json['serviceNameAr'] as String?)?.trim() ?? '',
      nameEn: (json['nameEn'] as String?)?.trim() ?? '',
      nameAr: (json['nameAr'] as String?)?.trim() ?? '',
      quantity: MobileOrderOfferModel._readInt(json['quantity']),
    );
  }

  MobileOfferSubService toEntity() {
    return MobileOfferSubService(
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
