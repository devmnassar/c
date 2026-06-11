import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';

OrderMock fromMobileOrder(MobileOrder order) {
  final orderType = order.orderType == MobileOrderType.delivery
      ? OrderTypeMock.delivery
      : OrderTypeMock.pickup;
  final customerAddress = orderType == OrderTypeMock.delivery
      ? order.targetAddress
      : order.sourceAddress;
  final laundryAddress = orderType == OrderTypeMock.delivery
      ? order.sourceAddress
      : order.targetAddress;
  final customerLat = orderType == OrderTypeMock.delivery
      ? order.targetLatitude
      : order.sourceLatitude;
  final customerLng = orderType == OrderTypeMock.delivery
      ? order.targetLongitude
      : order.sourceLongitude;

  return OrderMock(
    id: order.id.toString(),
    orderNumber: order.orderNumber.toString(),
    type: orderType,
    status: _mapStatus(order.status),
    area: _extractArea(customerAddress),
    district: _extractDistrict(customerAddress),
    scheduledAt: order.pickupTime ?? order.deliveryTime ?? order.createdOn,
    customerName: order.customerFullName,
    customerPhone: order.customerPhoneNumber,
    buildingNumber: order.buildingNumber > 0 ? order.buildingNumber : null,
    roomNumber: order.roomNumber > 0 ? order.roomNumber : null,
    createdOn: order.createdOn,
    pickupTime: order.pickupTime,
    deliveryTime: order.deliveryTime,
    laundryName: (order.laundryName?.trim().isNotEmpty ?? false)
        ? order.laundryName
        : null,
    laundryPhone: (order.laundryPhoneNumber?.trim().isNotEmpty ?? false)
        ? order.laundryPhoneNumber
        : null,
    laundryTypeName: _serviceName(order),
    laundryTypeNameAr: _serviceNameAr(order),
    orderItems: _mapOrderItems(order),
    itemDescription: order.itemDescription,
    distanceKm: order.distanceKm,
    etaMin: order.etaMinutes,
    lat: customerLat,
    lng: customerLng,
    sourceLat: order.sourceLatitude,
    sourceLng: order.sourceLongitude,
    targetLat: order.targetLatitude,
    targetLng: order.targetLongitude,
    totalPrice: order.totalPrice,
    isCash: order.paymentMethod == MobilePaymentMethod.cash,
    notes: order.customerNote,
    sourceAddress: order.sourceAddress,
    targetAddress: order.targetAddress,
    customerHasHanger: order.customerHasHanger,
    riderStatus: order.riderStatus,
    pickupRiderStatus: order.pickupRiderStatus,
  );
}

OrderMock mergeOrderWithLiveProgress({
  required OrderMock displayOrder,
  required OrderMock liveOrder,
}) {
  return OrderMock(
    id: displayOrder.id,
    orderNumber: displayOrder.orderNumber ?? liveOrder.orderNumber,
    type: liveOrder.type,
    status: liveOrder.status,
    area: displayOrder.area.isNotEmpty ? displayOrder.area : liveOrder.area,
    district: displayOrder.district.isNotEmpty
        ? displayOrder.district
        : liveOrder.district,
    scheduledAt: displayOrder.scheduledAt,
    customerName: displayOrder.customerName.isNotEmpty
        ? displayOrder.customerName
        : liveOrder.customerName,
    customerPhone: displayOrder.customerPhone.isNotEmpty
        ? displayOrder.customerPhone
        : liveOrder.customerPhone,
    buildingNumber: displayOrder.buildingNumber ?? liveOrder.buildingNumber,
    roomNumber: displayOrder.roomNumber ?? liveOrder.roomNumber,
    createdOn: displayOrder.createdOn ?? liveOrder.createdOn,
    pickupTime: displayOrder.pickupTime ?? liveOrder.pickupTime,
    deliveryTime: displayOrder.deliveryTime ?? liveOrder.deliveryTime,
    laundryName: (displayOrder.laundryName?.trim().isNotEmpty ?? false)
        ? displayOrder.laundryName
        : liveOrder.laundryName,
    laundryPhone: (displayOrder.laundryPhone?.trim().isNotEmpty ?? false)
        ? displayOrder.laundryPhone
        : liveOrder.laundryPhone,
    laundryTypeName: (displayOrder.laundryTypeName?.trim().isNotEmpty ?? false)
        ? displayOrder.laundryTypeName
        : liveOrder.laundryTypeName,
    laundryTypeNameAr:
        (displayOrder.laundryTypeNameAr?.trim().isNotEmpty ?? false)
            ? displayOrder.laundryTypeNameAr
            : liveOrder.laundryTypeNameAr,
    orderItems: (displayOrder.orderItems?.isNotEmpty ?? false)
        ? displayOrder.orderItems
        : liveOrder.orderItems,
    itemDescription: (displayOrder.itemDescription?.trim().isNotEmpty ?? false)
        ? displayOrder.itemDescription
        : liveOrder.itemDescription,
    orderImages: (displayOrder.orderImages?.isNotEmpty ?? false)
        ? displayOrder.orderImages
        : liveOrder.orderImages,
    distanceKm: displayOrder.distanceKm ?? liveOrder.distanceKm,
    etaMin: displayOrder.etaMin ?? liveOrder.etaMin,
    lat: displayOrder.lat ?? liveOrder.lat,
    lng: displayOrder.lng ?? liveOrder.lng,
    sourceLat: displayOrder.sourceLat ?? liveOrder.sourceLat,
    sourceLng: displayOrder.sourceLng ?? liveOrder.sourceLng,
    targetLat: displayOrder.targetLat ?? liveOrder.targetLat,
    targetLng: displayOrder.targetLng ?? liveOrder.targetLng,
    totalPrice: displayOrder.totalPrice != 0
        ? displayOrder.totalPrice
        : liveOrder.totalPrice,
    isCash: displayOrder.isCash ?? liveOrder.isCash,
    notes: (displayOrder.notes?.trim().isNotEmpty ?? false)
        ? displayOrder.notes
        : liveOrder.notes,
    sourceAddress: (displayOrder.sourceAddress?.trim().isNotEmpty ?? false)
        ? displayOrder.sourceAddress
        : liveOrder.sourceAddress,
    targetAddress: (displayOrder.targetAddress?.trim().isNotEmpty ?? false)
        ? displayOrder.targetAddress
        : liveOrder.targetAddress,
    customerHasHanger:
        displayOrder.customerHasHanger ?? liveOrder.customerHasHanger,
    riderStatus: liveOrder.riderStatus ?? displayOrder.riderStatus,
    pickupRiderStatus:
        liveOrder.pickupRiderStatus ?? displayOrder.pickupRiderStatus,
  );
}

OrderStatusMock _mapStatus(MobileOrderStatus status) {
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

List<OrderItemMock> _mapOrderItems(MobileOrder order) {
  if (order.subServices.isNotEmpty) {
    return order.subServices
        .map(
          (item) => OrderItemMock(
            nameEn: item.nameEn.isNotEmpty ? item.nameEn : item.serviceNameEn,
            nameAr: item.nameAr.isNotEmpty ? item.nameAr : item.serviceNameAr,
            quantity: item.quantity,
          ),
        )
        .toList();
  }

  return const <OrderItemMock>[];
}

String _extractArea(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return parts[parts.length - 1];
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

String? _serviceName(MobileOrder order) {
  if (order.subServices.isNotEmpty) {
    final first = order.subServices.first;
    final value = first.serviceNameEn.trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}

String? _serviceNameAr(MobileOrder order) {
  if (order.subServices.isNotEmpty) {
    final first = order.subServices.first;
    final value = first.serviceNameAr.trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}
