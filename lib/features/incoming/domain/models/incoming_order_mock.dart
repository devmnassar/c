/// Stop point type: laundry or home.
enum StopPointType {
  laundry,
  home,
}

/// A single stop in the route (laundry or home).
class StopPoint {
  final StopPointType type;
  final String title;
  final String addressLine1;
  final String addressLine2;
  final LatLngMock latLng;

  const StopPoint({
    required this.type,
    required this.title,
    required this.addressLine1,
    required this.addressLine2,
    required this.latLng,
  });
}

/// Simple lat/lng for mock models (avoids coupling to google_maps_flutter).
class LatLngMock {
  final double lat;
  final double lng;
  const LatLngMock(this.lat, this.lng);
}

/// Order type for incoming orders.
enum IncomingOrderType {
  pickup,
  delivery,
}

/// Clean mock model for incoming order used by `/incoming-order`.
class IncomingOrderMock {
  final String id;
  final IncomingOrderType orderType;

  final String laundryName;
  final LatLngMock laundryLatLng;
  final String? laundryLogoUrl;

  final String customerLabel;
  final LatLngMock customerLatLng;

  final StopPointType firstStopType;
  final StopPointType secondStopType;

  final String firstStopTitle;
  final String secondStopTitle;

  final double? distanceToFirstKm;
  final double? distanceFirstToSecondKm;

  final String? etaLabel;
  final String? serviceName;

  final String firstStopAddressLine1;
  final String firstStopAddressLine2;
  final String secondStopAddressLine1;
  final String secondStopAddressLine2;

  const IncomingOrderMock({
    required this.id,
    required this.orderType,
    required this.laundryName,
    required this.laundryLatLng,
    this.laundryLogoUrl,
    required this.customerLabel,
    required this.customerLatLng,
    required this.firstStopType,
    required this.secondStopType,
    required this.firstStopTitle,
    required this.secondStopTitle,
    this.distanceToFirstKm,
    this.distanceFirstToSecondKm,
    this.etaLabel,
    this.serviceName,
    required this.firstStopAddressLine1,
    required this.firstStopAddressLine2,
    required this.secondStopAddressLine1,
    required this.secondStopAddressLine2,
  });

  /// Returns [firstStop, secondStop] with proper type and labels.
  List<StopPoint> buildStops() {
    return [
      StopPoint(
        type: firstStopType,
        title: firstStopTitle,
        addressLine1: firstStopAddressLine1,
        addressLine2: firstStopAddressLine2,
        latLng: firstStopType == StopPointType.laundry
            ? laundryLatLng
            : customerLatLng,
      ),
      StopPoint(
        type: secondStopType,
        title: secondStopTitle,
        addressLine1: secondStopAddressLine1,
        addressLine2: secondStopAddressLine2,
        latLng: secondStopType == StopPointType.laundry
            ? laundryLatLng
            : customerLatLng,
      ),
    ];
  }
}
