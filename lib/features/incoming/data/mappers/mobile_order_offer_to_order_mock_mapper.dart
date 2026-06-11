import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';

OrderMock fromMobileOrderOffer(MobileOrderOffer offer) {
  final orderType = offer.orderType == MobileOrderType.delivery
      ? OrderTypeMock.delivery
      : OrderTypeMock.pickup;
  final customerAddress = orderType == OrderTypeMock.delivery
      ? offer.targetAddress
      : offer.sourceAddress;

  return OrderMock(
    id: offer.orderId.toString(),
    orderNumber: offer.orderNumber.toString(),
    type: orderType,
    status: _mapOfferStatus(offer.orderStatus),
    area: _extractArea(customerAddress),
    district: _extractDistrict(customerAddress),
    scheduledAt: offer.serverTimeUtc ?? DateTime.now(),
    customerName: offer.customerFullName,
    customerPhone: offer.customerPhoneNumber,
    buildingNumber: offer.buildingNumber != null && offer.buildingNumber! > 0
        ? offer.buildingNumber
        : null,
    roomNumber:
        offer.roomNumber != null && offer.roomNumber! > 0 ? offer.roomNumber : null,
    createdOn: offer.serverTimeUtc,
    pickupTime: offer.pickupTime,
    deliveryTime: offer.deliveryTime,
    laundryName: (offer.laundryName?.trim().isNotEmpty ?? false)
        ? offer.laundryName
        : _extractDistrict(
            orderType == OrderTypeMock.delivery
                ? offer.sourceAddress
                : offer.targetAddress,
          ),
    laundryPhone:
        (offer.laundryPhoneNumber?.trim().isNotEmpty ?? false)
            ? offer.laundryPhoneNumber
            : null,
    itemDescription: offer.itemDescription,
    distanceKm: offer.distanceKm,
    etaMin: offer.etaMinutes,
    lat: orderType == OrderTypeMock.delivery
        ? offer.targetLatitude
        : offer.sourceLatitude,
    lng: orderType == OrderTypeMock.delivery
        ? offer.targetLongitude
        : offer.sourceLongitude,
    sourceLat: offer.sourceLatitude,
    sourceLng: offer.sourceLongitude,
    targetLat: offer.targetLatitude,
    targetLng: offer.targetLongitude,
    totalPrice: offer.effectiveTotalPrice ?? offer.totalPrice,
    isCash: offer.paymentMethod == MobilePaymentMethod.cash,
    notes: offer.customerNote,
    sourceAddress: offer.sourceAddress,
    targetAddress: offer.targetAddress,
    customerHasHanger: offer.customerHasHanger,
  );
}

OrderStatusMock _mapOfferStatus(MobileOrderStatus status) {
  switch (status) {
    case MobileOrderStatus.newOrder:
      return OrderStatusMock.newOrder;
    case MobileOrderStatus.assigned:
      return OrderStatusMock.assigned;
    case MobileOrderStatus.inProgress:
      return OrderStatusMock.inProgress;
    case MobileOrderStatus.deliveryAttempted:
      return OrderStatusMock.attemptedDelivery;
    case MobileOrderStatus.delivered:
      return OrderStatusMock.completed;
    case MobileOrderStatus.cancelled:
      return OrderStatusMock.cancelled;
    case MobileOrderStatus.unknown:
      return OrderStatusMock.unknown;
  }
}

String _extractArea(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return parts.last;
  }
  return parts.isNotEmpty ? parts.first : 'Riyadh';
}

String _extractDistrict(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isNotEmpty ? parts.first : address;
}
