import '../domain/models/order_mock.dart';
import '../../../../core/orders/mock_order_matcher.dart';

class MockOrdersData {
  static final Map<String, OrderStatusMock> _statusOverrides = {};
  static final Map<String, OrderMock> _customOrders = {};

  /// Fetches order by id from mock data (includes incoming order GX-INCOMING-001).
  static OrderMock? getOrderById(String id) {
    try {
      // Check custom orders first
      OrderMock? order = _customOrders[id];
      if (order == null) {
        order = getMockOrders().firstWhere((o) => o.id == id);
      }

      final override = _statusOverrides[id];
      return override != null ? order.copyWith(status: override) : order;
    } catch (_) {
      return null;
    }
  }

  /// Adds a custom mock order that can be retrieved by id.
  static void addMockOrder(OrderMock order) {
    _customOrders[order.id] = order;
  }

  /// Updates order status (e.g. arrivedAtLaundry).
  static void updateOrderStatus(String id, OrderStatusMock status) {
    _statusOverrides[id] = status;
  }

  static List<OrderMock> getMockOrders() {
    final now = DateTime.now();
    return [
      // Incoming order from "Go To Online" flow (ensure it appears in details)
      MockOrderMatcher.fallbackOrder,
      OrderMock(
        id: 'GX-10421',
        type: OrderTypeMock.pickup,
        status: OrderStatusMock.newOrder,
        area: 'Al Olaya',
        district: 'King Fahd Road',
        scheduledAt: now.add(const Duration(hours: 2)),
        customerName: 'Ahmed Al-Saud',
        customerPhone: '+966501234567',
        laundryTypeName: 'Laundry',
        laundryTypeNameAr: 'غسيل',
        lat: 24.7118,
        lng: 46.6742,
        distanceKm: 2.5,
        etaMin: 15,
        isCash: true,
        notes: 'Ring doorbell twice',
      ),
      OrderMock(
        id: 'GX-10422',
        type: OrderTypeMock.delivery,
        status: OrderStatusMock.inProgress,
        area: 'Al Malaz',
        district: 'Prince Sultan Street',
        scheduledAt: now.add(const Duration(hours: 3)),
        customerName: 'Fatima Al-Rashid',
        customerPhone: '+966507654321',
        laundryName: 'Clean Express',
        laundryPhone: '+966112345678',
        laundryTypeName: 'Iron',
        laundryTypeNameAr: 'كوي',
        lat: 24.6696,
        lng: 46.7312,
        distanceKm: 4.2,
        etaMin: 22,
        isCash: false,
        notes: 'Leave at front door',
      ),
      OrderMock(
        id: 'GX-10423',
        type: OrderTypeMock.pickup,
        status: OrderStatusMock.newOrder,
        area: 'Al Naseem',
        district: 'Al Khaleej Road',
        scheduledAt: now.add(const Duration(days: 1)),
        customerName: 'Mohammed Al-Qahtani',
        customerPhone: '+966501112233',
        laundryTypeName: 'Both',
        laundryTypeNameAr: 'كلاهما',
        lat: 24.7911,
        lng: 46.8286,
        distanceKm: 1.8,
        etaMin: 10,
        isCash: true,
      ),
      OrderMock(
        id: 'GX-10424',
        type: OrderTypeMock.delivery,
        status: OrderStatusMock.completed,
        area: 'Al Wurud',
        district: 'King Abdulaziz Road',
        scheduledAt: now.subtract(const Duration(hours: 2)),
        customerName: 'Sara Al-Mutairi',
        customerPhone: '+966509998877',
        laundryName: 'Fresh Laundry',
        laundryPhone: '+966113456789',
        laundryTypeName: 'Carpet Washing',
        laundryTypeNameAr: 'غسيل سجاد',
        lat: 24.7494,
        lng: 46.7001,
        distanceKm: 3.5,
        etaMin: 18,
        isCash: false,
        notes: 'Delivered successfully',
      ),
      OrderMock(
        id: 'GX-10425',
        type: OrderTypeMock.pickup,
        status: OrderStatusMock.completed,
        area: 'Al Falah',
        district: 'Olaya Street',
        scheduledAt: now.subtract(const Duration(days: 1)),
        customerName: 'Khalid Al-Dosari',
        customerPhone: '+966505556677',
        laundryTypeName: 'Laundry',
        laundryTypeNameAr: 'غسيل',
        lat: 24.8016,
        lng: 46.7234,
        distanceKm: 5.1,
        etaMin: 28,
        isCash: true,
      ),
      OrderMock(
        id: 'GX-10426',
        type: OrderTypeMock.delivery,
        status: OrderStatusMock.newOrder,
        area: 'Al Murabba',
        district: 'King Faisal Road',
        scheduledAt: now.add(const Duration(hours: 5)),
        customerName: 'Noura Al-Shammari',
        customerPhone: '+966503334455',
        laundryName: 'Quick Clean',
        laundryPhone: '+966114567890',
        laundryTypeName: 'Carpet Washing',
        laundryTypeNameAr: 'غسيل سجاد',
        lat: 24.6585,
        lng: 46.7092,
        distanceKm: 2.9,
        etaMin: 14,
        isCash: true,
        notes: 'Call before arrival',
      ),
      OrderMock(
        id: 'GX-10427',
        type: OrderTypeMock.pickup,
        status: OrderStatusMock.inProgress,
        area: 'Al Aziziyah',
        district: 'Prince Turki Road',
        scheduledAt: now.add(const Duration(hours: 1)),
        customerName: 'Yousef Al-Harbi',
        customerPhone: '+966504445566',
        laundryTypeName: 'Iron',
        laundryTypeNameAr: 'كوي',
        lat: 24.5675,
        lng: 46.7810,
        distanceKm: 3.7,
        etaMin: 20,
        isCash: false,
      ),
      OrderMock(
        id: 'GX-10428',
        type: OrderTypeMock.delivery,
        status: OrderStatusMock.newOrder,
        area: 'Al Sulaimaniyah',
        district: 'Tahlia Street',
        scheduledAt: now.add(const Duration(hours: 4)),
        customerName: 'Layla Al-Mutawa',
        customerPhone: '+966506667788',
        laundryName: 'Premium Wash',
        laundryPhone: '+966115678901',
        laundryTypeName: 'Both',
        laundryTypeNameAr: 'كلاهما',
        lat: 24.7027,
        lng: 46.6893,
        distanceKm: 1.5,
        etaMin: 8,
        isCash: true,
      ),
    ];
  }
}
