import '../../domain/models/order.dart';
import '../../domain/repositories/orders_repository.dart';

class MockOrdersRepository implements OrdersRepository {
  final List<Order> _allOrders = [
    Order(
      id: '1',
      orderType: OrderType.pickup,
      status: OrderStatus.pending,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 2)),
      area: 'Al Olaya',
      district: 'King Fahd Road',
      customerName: 'Ahmed Al-Saud',
      customerPhone: '+966501234567',
      lat: 24.7136,
      lng: 46.6753,
      notes: 'Ring doorbell twice',
      homePhotos: ['https://example.com/home1.jpg'],
      clothesPhotos: [],
    ),
    Order(
      id: '2',
      orderType: OrderType.dropoff,
      status: OrderStatus.inProgress,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 3)),
      area: 'Al Malaz',
      district: 'Prince Sultan Street',
      customerName: 'Fatima Al-Rashid',
      customerPhone: '+966507654321',
      lat: 24.6408,
      lng: 46.7167,
      notes: 'Leave at front door',
      homePhotos: [],
      clothesPhotos: [],
    ),
    Order(
      id: '3',
      orderType: OrderType.pickup,
      status: OrderStatus.pending,
      scheduledDateTime: DateTime.now().add(const Duration(days: 1)),
      area: 'Al Naseem',
      district: 'Al Khaleej Road',
      customerName: 'Mohammed Al-Qahtani',
      customerPhone: '+966501112233',
      lat: 24.7136,
      lng: 46.6753,
      notes: null,
      homePhotos: [],
      clothesPhotos: [],
    ),
    Order(
      id: '4',
      orderType: OrderType.dropoff,
      status: OrderStatus.completed,
      scheduledDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      area: 'Al Wurud',
      district: 'King Abdulaziz Road',
      customerName: 'Sara Al-Mutairi',
      customerPhone: '+966509998877',
      lat: 24.7136,
      lng: 46.6753,
      notes: 'Delivered successfully',
      homePhotos: [],
      clothesPhotos: [],
    ),
    Order(
      id: '5',
      orderType: OrderType.pickup,
      status: OrderStatus.completed,
      scheduledDateTime: DateTime.now().subtract(const Duration(days: 1)),
      area: 'Al Falah',
      district: 'Olaya Street',
      customerName: 'Khalid Al-Dosari',
      customerPhone: '+966505556677',
      lat: null,
      lng: null,
      notes: null,
      homePhotos: [],
      clothesPhotos: [],
    ),
    Order(
      id: '6',
      orderType: OrderType.dropoff,
      status: OrderStatus.pending,
      scheduledDateTime: DateTime.now().add(const Duration(hours: 5)),
      area: 'Al Murabba',
      district: 'King Faisal Road',
      customerName: 'Noura Al-Shammari',
      customerPhone: '+966503334455',
      lat: 24.6408,
      lng: 46.7167,
      notes: 'Call before arrival',
      homePhotos: [],
      clothesPhotos: [],
    ),
  ];

  @override
  Future<List<Order>> getTodayOrders() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _allOrders.where((order) {
      return order.scheduledDateTime.isAfter(todayStart) &&
          order.scheduledDateTime.isBefore(todayEnd) &&
          order.status != OrderStatus.completed;
    }).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  @override
  Future<List<Order>> getUpcomingOrders() async {
    final now = DateTime.now();
    final todayEnd =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    return _allOrders.where((order) {
      return order.scheduledDateTime.isAfter(todayEnd) &&
          order.status != OrderStatus.completed;
    }).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  @override
  Future<List<Order>> getCompletedOrders() async {
    return _allOrders
        .where((order) => order.status == OrderStatus.completed)
        .toList()
      ..sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
  }

  @override
  Future<Order?> getOrderById(String id) async {
    try {
      return _allOrders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _allOrders.where((order) {
      return order.customerName.toLowerCase().contains(lowerQuery) ||
          order.area.toLowerCase().contains(lowerQuery) ||
          order.district.toLowerCase().contains(lowerQuery) ||
          order.customerPhone.contains(query);
    }).toList();
  }
}
