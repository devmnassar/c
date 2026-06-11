import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';

class IncomingOrderRouteArgs {
  const IncomingOrderRouteArgs({
    this.initialOrder,
    this.initialOffer,
    this.loadCurrentOfferOnOpen = false,
    this.showEmptyState = false,
  });

  final OrderMock? initialOrder;
  final MobileOrderOffer? initialOffer;
  final bool loadCurrentOfferOnOpen;
  final bool showEmptyState;
}
