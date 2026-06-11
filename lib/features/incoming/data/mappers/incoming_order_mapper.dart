import '../../../orders/domain/models/order_mock.dart';
import '../../../orders/domain/models/mobile_order.dart';
import '../../../orders/domain/models/mobile_order_offer.dart';
import '../../domain/models/incoming_order_mock.dart';
import 'package:get/get_utils/get_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Maps [OrderMock] to [IncomingOrderMock] with localized labels.
IncomingOrderMock fromOrderMock(OrderMock order, [AppLocalizations? l10n]) {
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

  final laundryName = order.laundryName?.trim() ?? '';
  final laundryLatLng = LatLngMock(
    order.type == OrderTypeMock.delivery
        ? (order.sourceLat ?? order.lat ?? 24.7136)
        : (order.targetLat ?? order.lat ?? 24.7136),
    order.type == OrderTypeMock.delivery
        ? (order.sourceLng ?? order.lng ?? 46.6753)
        : (order.targetLng ?? order.lng ?? 46.6753),
  );
  final customerLatLng = LatLngMock(
    order.type == OrderTypeMock.delivery
        ? (order.targetLat ?? order.lat ?? 24.7118)
        : (order.sourceLat ?? order.lat ?? 24.7118),
    order.type == OrderTypeMock.delivery
        ? (order.targetLng ?? order.lng ?? 46.6742)
        : (order.sourceLng ?? order.lng ?? 46.6742),
  );

  final firstStopTitle = firstStopType == StopPointType.laundry
      ? _buildLaundryTitle(laundryName)
      : '${'labelHome'.tr}: ${order.customerName}';
  final secondStopTitle = secondStopType == StopPointType.laundry
      ? _buildLaundryTitle(laundryName)
      : '${'labelHome'.tr}: ${order.customerName}';

  final homeAddress = order.type == OrderTypeMock.delivery
      ? (order.targetAddress ?? '${order.district}, ${order.area}, Riyadh')
      : (order.sourceAddress ?? '${order.district}, ${order.area}, Riyadh');
  final laundryAddress = order.type == OrderTypeMock.delivery
      ? (order.sourceAddress ?? '')
      : (order.targetAddress ?? '');

  final firstAddress =
      firstStopType == StopPointType.laundry ? laundryAddress : homeAddress;
  final secondAddress =
      secondStopType == StopPointType.laundry ? laundryAddress : homeAddress;

  final firstStopAddressLine1 = _addressLine1(firstAddress);
  final firstStopAddressLine2 = _addressLine2(firstAddress);
  final secondStopAddressLine1 = _addressLine1(secondAddress);
  final secondStopAddressLine2 = _addressLine2(secondAddress);

  final etaLabel = order.etaMin == null
      ? null
      : (l10n?.etaMinutes(order.etaMin!) ?? '${order.etaMin} min');

  return IncomingOrderMock(
    id: order.id,
    orderType: orderType,
    laundryName: laundryName,
    laundryLatLng: laundryLatLng,
    laundryLogoUrl: null,
    customerLabel: 'labelHome'.tr,
    customerLatLng: customerLatLng,
    firstStopType: firstStopType,
    secondStopType: secondStopType,
    firstStopTitle: firstStopTitle,
    secondStopTitle: secondStopTitle,
    distanceToFirstKm: order.distanceKm,
    distanceFirstToSecondKm: order.distanceKm,
    etaLabel: etaLabel,
    serviceName: order.laundryTypeName?.trim(),
    firstStopAddressLine1: firstStopAddressLine1,
    firstStopAddressLine2: firstStopAddressLine2,
    secondStopAddressLine1: secondStopAddressLine1,
    secondStopAddressLine2: secondStopAddressLine2,
  );
}

IncomingOrderMock fromOfferToIncomingOrderMock(
  MobileOrderOffer offer, [
  AppLocalizations? l10n,
]) {
  final orderType = offer.orderType == MobileOrderType.delivery
      ? IncomingOrderType.delivery
      : IncomingOrderType.pickup;

  final firstStopType = orderType == IncomingOrderType.delivery
      ? StopPointType.laundry
      : StopPointType.home;
  final secondStopType = orderType == IncomingOrderType.delivery
      ? StopPointType.home
      : StopPointType.laundry;

  final laundryName = offer.laundryName?.trim() ?? '';
  final laundryLatLng = LatLngMock(
    orderType == IncomingOrderType.delivery
        ? (offer.sourceLatitude ?? 24.7136)
        : (offer.targetLatitude ?? 24.7136),
    orderType == IncomingOrderType.delivery
        ? (offer.sourceLongitude ?? 46.6753)
        : (offer.targetLongitude ?? 46.6753),
  );
  final customerLatLng = LatLngMock(
    orderType == IncomingOrderType.delivery
        ? (offer.targetLatitude ?? 24.7118)
        : (offer.sourceLatitude ?? 24.7118),
    orderType == IncomingOrderType.delivery
        ? (offer.targetLongitude ?? 46.6742)
        : (offer.sourceLongitude ?? 46.6742),
  );

  final firstStopTitle = firstStopType == StopPointType.laundry
      ? _buildLaundryTitle(laundryName)
      : '${'labelHome'.tr}: ${offer.customerFullName}';
  final secondStopTitle = secondStopType == StopPointType.laundry
      ? _buildLaundryTitle(laundryName)
      : '${'labelHome'.tr}: ${offer.customerFullName}';

  final homeAddress = orderType == IncomingOrderType.delivery
      ? offer.targetAddress
      : offer.sourceAddress;
  final laundryAddress = orderType == IncomingOrderType.delivery
      ? offer.sourceAddress
      : offer.targetAddress;

  final firstAddress =
      firstStopType == StopPointType.laundry ? laundryAddress : homeAddress;
  final secondAddress =
      secondStopType == StopPointType.laundry ? laundryAddress : homeAddress;

  final etaLabel = offer.etaMinutes == null
      ? null
      : (l10n?.etaMinutes(offer.etaMinutes!) ?? '${offer.etaMinutes} min');

  return IncomingOrderMock(
    id: offer.orderId.toString(),
    orderType: orderType,
    laundryName: laundryName,
    laundryLatLng: laundryLatLng,
    laundryLogoUrl: null,
    customerLabel: 'labelHome'.tr,
    customerLatLng: customerLatLng,
    firstStopType: firstStopType,
    secondStopType: secondStopType,
    firstStopTitle: firstStopTitle,
    secondStopTitle: secondStopTitle,
    distanceToFirstKm: offer.distanceKm,
    distanceFirstToSecondKm: offer.distanceKm,
    etaLabel: etaLabel,
    serviceName: _offerServiceName(offer),
    firstStopAddressLine1: _addressLine1(firstAddress),
    firstStopAddressLine2: _addressLine2(firstAddress),
    secondStopAddressLine1: _addressLine1(secondAddress),
    secondStopAddressLine2: _addressLine2(secondAddress),
  );
}

String? _offerServiceName(MobileOrderOffer offer) {
  if (offer.subServices.isEmpty) {
    return null;
  }

  final value = offer.subServices.first.serviceNameEn.trim();
  return value.isEmpty ? null : value;
}

String _buildLaundryTitle(String laundryName) {
  final trimmed = laundryName.trim();
  if (trimmed.isEmpty) {
    return '${'labelLaundry'.tr}:';
  }
  return '${'labelLaundry'.tr}: $trimmed';
}

String _addressLine1(String address) {
  final parts = _normalizedAddressParts(address);
  if (parts.length >= 2) {
    return '${parts[0]}, ${parts[1]}';
  }
  if (parts.length == 1) {
    return parts.first;
  }
  return address;
}

String _addressLine2(String address) {
  final parts = _normalizedAddressParts(address);
  if (parts.length > 2) {
    return parts.sublist(2).join(', ');
  }
  return '';
}

List<String> _normalizedAddressParts(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2 &&
      parts.last.toLowerCase() == parts[parts.length - 2].toLowerCase()) {
    parts.removeLast();
  }

  return parts;
}
