import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';

class MobileOrderOffer {
  const MobileOrderOffer({
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
    this.subServices = const <MobileOfferSubService>[],
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
  final MobileOrderType orderType;
  final MobileOrderStatus orderStatus;
  final MobilePaymentMethod? paymentMethod;
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
  final List<MobileOfferSubService> subServices;
  final double? sourceLatitude;
  final double? sourceLongitude;
  final double? targetLatitude;
  final double? targetLongitude;
}

class MobileOfferSubService {
  const MobileOfferSubService({
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
