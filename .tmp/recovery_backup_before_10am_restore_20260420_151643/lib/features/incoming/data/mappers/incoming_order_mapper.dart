import '../../../orders/domain/models/order_mock.dart';
import '../../domain/models/incoming_order_mock.dart';
import '../../../../core/localization/app_localizations.dart';

/// Maps [OrderMock] to [IncomingOrderMock] with localized labels.
/// Requires [AppLocalizations] for Laundry/Home labels.
IncomingOrderMock fromOrderMock(OrderMock order, AppLocalizations l10n) {
  final orderType = order.type == OrderTypeMock.delivery
      ? IncomingOrderType.delivery
      : IncomingOrderType.pickup;

  // delivery: first Laundry, second Home | pickup: first Home, second Laundry
  final firstStopType = orderType == IncomingOrderType.delivery
      ? StopPointType.laundry
      : StopPointType.home;
  final secondStopType = orderType == IncomingOrderType.delivery
      ? StopPointType.home
      : StopPointType.laundry;

  final laundryName = order.laundryName ?? 'Laundry';
  final laundryLatLng = const LatLngMock(24.7136, 46.6753); // Mock laundry coords
  final customerLatLng = LatLngMock(
    order.lat ?? 24.7118,
    order.lng ?? 46.6742,
  );

  final firstStopTitle = firstStopType == StopPointType.laundry
      ? '${l10n.labelLaundry}: $laundryName'
      : '${l10n.labelHome}: ${order.customerName}';
  final secondStopTitle = secondStopType == StopPointType.laundry
      ? '${l10n.labelLaundry}: $laundryName'
      : '${l10n.labelHome}: ${order.customerName}';

  final area = order.area;
  final district = order.district;
  final addressLine2Home = '$district, $area, Riyadh, Saudi Arabia';
  final addressLine2Laundry = '$laundryName Branch, Prince Sultan St, Riyadh, Saudi Arabia';

  final firstStopAddressLine1 = firstStopType == StopPointType.laundry
      ? 'Al Olaya, King Fahd Road'
      : '$area, $district';
  final firstStopAddressLine2 = firstStopType == StopPointType.laundry
      ? addressLine2Laundry
      : addressLine2Home;

  final secondStopAddressLine1 = secondStopType == StopPointType.laundry
      ? 'Al Olaya, King Fahd Road'
      : '$area, $district';
  final secondStopAddressLine2 = secondStopType == StopPointType.laundry
      ? addressLine2Laundry
      : addressLine2Home;

  final scheduled = order.scheduledAt;
  final to = scheduled.add(const Duration(minutes: 45));
  final etaFrom = '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';
  final etaTo = '${to.hour.toString().padLeft(2, '0')}:${to.minute.toString().padLeft(2, '0')}';

  return IncomingOrderMock(
    id: order.id,
    orderType: orderType,
    laundryName: laundryName,
    laundryLatLng: laundryLatLng,
    laundryLogoUrl: null,
    customerLabel: l10n.labelHome,
    customerLatLng: customerLatLng,
    firstStopType: firstStopType,
    secondStopType: secondStopType,
    firstStopTitle: firstStopTitle,
    secondStopTitle: secondStopTitle,
    distanceToFirstKm: order.distanceKm,
    distanceFirstToSecondKm: order.distanceKm * 1.2,
    etaFrom: etaFrom,
    etaTo: etaTo,
    firstStopAddressLine1: firstStopAddressLine1,
    firstStopAddressLine2: firstStopAddressLine2,
    secondStopAddressLine1: secondStopAddressLine1,
    secondStopAddressLine2: secondStopAddressLine2,
  );
}
