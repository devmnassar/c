import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';

MobileOrder sampleMobileOrder({
  int id = 42,
  MobileOrderType orderType = MobileOrderType.delivery,
}) {
  return MobileOrder(
    id: id,
    orderNumber: 1001,
    orderTrackingId: 'TRK-$id',
    customerId: 1,
    customerFullName: 'Test Customer',
    customerPhoneNumber: '+966500000000',
    buildingNumber: 10,
    roomNumber: 2,
    orderType: orderType,
    status: MobileOrderStatus.assigned,
    paymentMethod: MobilePaymentMethod.cash,
    deliveryType: MobileDeliveryType.sixHour,
    countryCode: 'SA',
    countryName: 'Saudi Arabia',
    sourceCode: 'LAUNDRY-1',
    sourceAddress: 'Laundry Street',
    sourceLatitude: 24.7136,
    sourceLongitude: 46.6753,
    targetAddress: 'Customer Street',
    targetLatitude: 24.72,
    targetLongitude: 46.68,
    totalPrice: 120,
    createdOn: DateTime.utc(2026, 6, 7, 10, 0),
    isActive: true,
    subServices: const [],
  );
}

MobileOrderOffer sampleMobileOrderOffer({
  int offerId = 101,
  int orderId = 42,
  MobileOrderType orderType = MobileOrderType.delivery,
  int remainingSeconds = 60,
}) {
  return MobileOrderOffer(
    offerId: offerId,
    orderId: orderId,
    orderNumber: 1001,
    expiresAt: DateTime.utc(2026, 6, 7, 12, 0),
    serverTimeUtc: DateTime.utc(2026, 6, 7, 11, 59),
    remainingSeconds: remainingSeconds,
    attemptNumber: 1,
    bonusAmount: 5,
    customerFullName: 'Offer Customer',
    customerPhoneNumber: '+966511111111',
    orderType: orderType,
    orderStatus: MobileOrderStatus.newOrder,
    sourceAddress: 'Offer Source',
    targetAddress: 'Offer Target',
    totalPrice: 99,
  );
}

OrderMock sampleOrderMock({
  String id = '42',
  OrderTypeMock type = OrderTypeMock.delivery,
}) {
  return OrderMock(
    id: id,
    type: type,
    status: OrderStatusMock.assigned,
    area: 'Riyadh',
    district: 'District 1',
    scheduledAt: DateTime.utc(2026, 6, 7, 12, 0),
    customerName: 'Route Customer',
    customerPhone: '+966522222222',
  );
}
