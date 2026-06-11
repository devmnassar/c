/// Shared business constants used across courier operational flows.
///
/// Phase 1: additive only — not imported by production code yet.
/// Confirm all values against live screens before replacing inline usages.
class BusinessConstants {
  const BusinessConstants._();

  // ---------------------------------------------------------------------------
  // SharedPreferences / session (courier state)
  // ---------------------------------------------------------------------------

  /// Used in map-status, orders, incoming order pages, and [HeartbeatCubit].
  static const courierOnlineKey = 'courier_online';

  /// Cached via [SharedPrefKeys.courierTypeId] / CourierProfileLocalDataSource.
  /// Full-time courier branch in active trip and orders flows.
  static const fullTimeCourierTypeId = 3;

  /// Freelancer offer polling on map-status when courierTypeId == 1.
  static const freelancerCourierTypeId = 1;

  // ---------------------------------------------------------------------------
  // Delivery rider status integers (UpdateRiderStatusUseCase payloads)
  // Confirmed in active_trip_page.dart and delivery_completion_cubit.dart.
  // TODO: Verify backend contract before replacing all inline usages.
  // ---------------------------------------------------------------------------

  static const deliveryStatusPendingStart = 0;

  static const riderStatusEnRouteToLaundry = 1;
  static const riderStatusArrivedAtLaundry = 2;
  static const riderStatusPickedUp = 3;
  static const riderStatusEnRouteToCustomer = 4;
  static const riderStatusArrivedAtCustomer = 5;

  /// Used by DeliveryCompletionCubit.deliverOrder.
  static const riderStatusDelivered = 6;

  /// Used by DeliveryCompletionCubit.attemptDelivery.
  static const riderStatusAttemptedDelivery = 7;

  // ---------------------------------------------------------------------------
  // Pickup rider status integers (UpdatePickupStatusUseCase payloads)
  // Confirmed in active_trip_page.dart private constants.
  // TODO: Verify backend contract before replacing all inline usages.
  // ---------------------------------------------------------------------------

  static const pickupStatusPendingStart = 0;
  static const pickupStatusEnRouteToCustomer = 1;
  static const pickupStatusArrivedAtCustomer = 2;
  static const pickupStatusPickedUp = 3;
  static const pickupStatusEnRouteToLaundry = 4;
  static const pickupStatusArrivedAtLaundry = 5;
  static const pickupStatusDroppedOffAtLaundry = 6;
}
