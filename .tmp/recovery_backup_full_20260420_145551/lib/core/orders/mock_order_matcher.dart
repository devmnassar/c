import 'dart:math' as math;
import '../../features/orders/domain/models/order_mock.dart';

/// Mock service that simulates finding a new order after a delay.
/// Returns a hardcoded order after 2 seconds.
class MockOrderMatcher {
  static const Duration _searchDelay = Duration(seconds: 2);

  /// Simulates search for a new order. Returns mock order after 2 seconds.
  /// - delivery: first destination Laundry, then Customer
  /// - pickup: first destination Customer, then Laundry
  static Future<OrderMock> findNewOrder() async {
    await Future.delayed(_searchDelay);
    return _mockIncomingOrder();
  }

  /// Fallback when navigating without extra (e.g. direct URL).
  static OrderMock get fallbackOrder => _mockIncomingOrder();

  static OrderMock _mockIncomingOrder() {
    final now = DateTime.now();
    final random = math.Random();
    final isPickup = random.nextBool();

    return OrderMock(
      id: 'GX-INCOMING-${random.nextInt(1000).toString().padLeft(3, '0')}',
      type: isPickup ? OrderTypeMock.pickup : OrderTypeMock.delivery,
      status: OrderStatusMock.newOrder,
      area: 'Al Olaya',
      district: 'King Fahd Road',
      scheduledAt: now.add(const Duration(hours: 1)),
      customerName: isPickup ? 'Khalid Mansour' : 'Ahmed Al-Saud',
      customerPhone: '+966501234567',
      laundryName: 'Clean Express',
      laundryPhone: '+966112345678',
      laundryTypeName: isPickup ? 'Pickup Clothes' : 'Delivery Clothes',
      laundryTypeNameAr: isPickup ? 'استلام ملابس' : 'توصيل ملابس',
      orderItems: isPickup
          ? const [
              OrderItemMock(nameEn: '5 Suits', nameAr: '5 بدلات', quantity: 5),
              OrderItemMock(
                nameEn: '2 Dresses',
                nameAr: '2 فستان',
                quantity: 2,
              ),
            ]
          : const [
              OrderItemMock(
                nameEn: '3 Large carpets',
                nameAr: 'عدد 3 سجادة كبيرة الحجم',
                quantity: 3,
              ),
              OrderItemMock(
                nameEn: '2 Medium carpets',
                nameAr: 'عدد 2 متوسط الحجم',
                quantity: 2,
              ),
            ],
      orderImages: const [
        'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400',
        'https://images.unsplash.com/photo-1600166898405-da9535204843?w=400',
      ],
      distanceKm: 2.5,
      etaMin: 15,
      lat: 24.7118,
      lng: 46.6742,
      isCash: true,
      notes:
          isPickup ? 'Please be careful with the suits' : 'Ring doorbell twice',
    );
  }
}
