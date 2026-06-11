import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/incoming/data/mappers/mobile_order_offer_to_order_mock_mapper.dart';
import 'package:gaseel_courier/features/incoming/data/mappers/mobile_order_to_order_mock_mapper.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/accept_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_order_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/reject_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_pickup_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_rider_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';

part 'incoming_order_state.dart';

class IncomingOrderCubit extends Cubit<IncomingOrderState> {
  IncomingOrderCubit({
    required GetCurrentOrderUseCase getCurrentOrderUseCase,
    required GetCurrentOfferUseCase getCurrentOfferUseCase,
    required AcceptOrderOfferUseCase acceptOrderOfferUseCase,
    required RejectOrderOfferUseCase rejectOrderOfferUseCase,
    required UpdateRiderStatusUseCase updateRiderStatusUseCase,
    required UpdatePickupStatusUseCase updatePickupStatusUseCase,
  })  : _getCurrentOrderUseCase = getCurrentOrderUseCase,
        _getCurrentOfferUseCase = getCurrentOfferUseCase,
        _acceptOrderOfferUseCase = acceptOrderOfferUseCase,
        _rejectOrderOfferUseCase = rejectOrderOfferUseCase,
        _updateRiderStatusUseCase = updateRiderStatusUseCase,
        _updatePickupStatusUseCase = updatePickupStatusUseCase,
        super(const IncomingOrderState());

  final GetCurrentOrderUseCase _getCurrentOrderUseCase;
  final GetCurrentOfferUseCase _getCurrentOfferUseCase;
  final AcceptOrderOfferUseCase _acceptOrderOfferUseCase;
  final RejectOrderOfferUseCase _rejectOrderOfferUseCase;
  final UpdateRiderStatusUseCase _updateRiderStatusUseCase;
  final UpdatePickupStatusUseCase _updatePickupStatusUseCase;
  bool _loadingInProgress = false;

  @override
  void emit(IncomingOrderState state) {
    _log(
      'State change: '
      'status=${this.state.status.name} -> ${state.status.name}, '
      'actionStatus=${this.state.actionStatus.name} -> ${state.actionStatus.name}, '
      'flowType=${this.state.flowType.name} -> ${state.flowType.name}, '
      'currentOrderId=${state.currentOrderId}, '
      'offerId=${state.offer?.offerId}',
    );
    if ((state.errorMessage ?? '').trim().isNotEmpty) {
      _log('State errorMessage=${state.errorMessage}');
    }
    if ((state.actionErrorMessage ?? '').trim().isNotEmpty) {
      _log('State actionErrorMessage=${state.actionErrorMessage}');
    }
    super.emit(state);
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('================ INCOMING ORDER CUBIT ================');
    debugPrint('[INCOMING ORDER CUBIT] $message');
  }

  Future<void> loadCurrentOrder({
    OrderMock? initialOrder,
    MobileOrderOffer? initialOffer,
    bool loadCurrentOfferOnOpen = false,
    bool showEmptyState = false,
  }) async {
    if (_loadingInProgress) {
      _log('loadCurrentOrder ignored because another load is already running');
      return;
    }

    final hasInitialOrder = initialOrder != null;
    final hasInitialOffer = initialOffer != null;
    _log(
      'loadCurrentOrder started. '
      'hasInitialOrder=$hasInitialOrder hasInitialOffer=$hasInitialOffer '
      'loadCurrentOfferOnOpen=$loadCurrentOfferOnOpen '
      'showEmptyState=$showEmptyState',
    );
    if (showEmptyState) {
      _log('Showing empty state immediately because showEmptyState=true');
      emit(
        state.copyWith(
          status: IncomingOrderStatus.empty,
          flowType: IncomingOrderFlowType.freelancerOffer,
          currentOrderId: null,
          offer: null,
          errorMessage: 'No current offer found.',
        ),
      );
      return;
    }

    if (initialOffer != null) {
      _log(
        'Emitting success from initialOffer without current-order fetch. '
        'offerId=${initialOffer.offerId}, orderId=${initialOffer.orderId}, '
        'remainingSeconds=${initialOffer.remainingSeconds}, '
        'distanceKm=${initialOffer.distanceKm}, etaMinutes=${initialOffer.etaMinutes}',
      );
      emit(
        state.copyWith(
          status: IncomingOrderStatus.success,
          order: fromMobileOrderOffer(initialOffer),
          currentOrderId: initialOffer.orderId,
          offer: initialOffer,
          flowType: IncomingOrderFlowType.freelancerOffer,
          errorMessage: null,
        ),
      );
      return;
    }

    if (loadCurrentOfferOnOpen) {
      _log('Loading current offer on open for freelancer flow');
      emit(
        state.copyWith(
          status: IncomingOrderStatus.loading,
          flowType: IncomingOrderFlowType.freelancerOffer,
          errorMessage: null,
        ),
      );

      final offerResult = await _getCurrentOfferUseCase();
      offerResult.fold(
        (error) {
          _log('Current offer fetch failed on open: ${error.message}');
          emit(
            state.copyWith(
              status: IncomingOrderStatus.failure,
              flowType: IncomingOrderFlowType.freelancerOffer,
              errorMessage: error.message,
            ),
          );
        },
        (offer) {
          if (offer == null) {
            _log('Current offer fetch on open returned data=null');
            emit(
              state.copyWith(
                status: IncomingOrderStatus.empty,
                flowType: IncomingOrderFlowType.freelancerOffer,
                currentOrderId: null,
                offer: null,
                errorMessage: 'No current offer found.',
              ),
            );
            return;
          }

          _log(
            'Current offer fetch on open succeeded. '
            'offerId=${offer.offerId}, orderId=${offer.orderId}, '
            'type=${offer.orderType.name}, orderStatus=${offer.orderStatus.name}, '
            'remainingSeconds=${offer.remainingSeconds}',
          );

          emit(
            state.copyWith(
              status: IncomingOrderStatus.success,
              order: fromMobileOrderOffer(offer),
              currentOrderId: offer.orderId,
              offer: offer,
              flowType: IncomingOrderFlowType.freelancerOffer,
              errorMessage: null,
            ),
          );
        },
      );
      return;
    }

    if (initialOrder != null) {
      _log(
        'Emitting success from initialOrder before API fetch. '
        'orderId=${initialOrder.id}, type=${initialOrder.type.name}',
      );
      emit(
        state.copyWith(
          status: IncomingOrderStatus.success,
          order: initialOrder,
          currentOrderId: null,
          offer: null,
          flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
          errorMessage: null,
        ),
      );
    }

    _loadingInProgress = true;
    if (!hasInitialOrder) {
      _log('Emitting loading state while fetching current order');
      emit(
        state.copyWith(
          status: IncomingOrderStatus.loading,
          errorMessage: null,
        ),
      );
    }

    final result = await _getCurrentOrderUseCase();
    result.fold(
      (error) {
        _log('Current order fetch failed: ${error.message}');
        if (!hasInitialOrder) {
          emit(
            state.copyWith(
              status: IncomingOrderStatus.failure,
              flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
              errorMessage: error.message,
            ),
          );
        }
      },
      (order) {
        if (order == null) {
          _log('Current order fetch returned null order');
          emit(
            state.copyWith(
              status: IncomingOrderStatus.empty,
              flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
              errorMessage: 'No current order found.',
            ),
          );
          return;
        }

        if (kDebugMode) {
          debugPrint('================ CURRENT ORDER FLOW ================');
          debugPrint(
              '[CURRENT ORDER FLOW] extracted data.orderId = ${order.id}');
          debugPrint('[CURRENT ORDER FLOW] stored currentOrderId in cubit');
        }
        _log(
          'Current order fetch succeeded. orderId=${order.id}, '
          'type=${order.orderType}, riderStatus=${order.riderStatus}, '
          'status=${order.status}',
        );

        emit(
          state.copyWith(
            status: IncomingOrderStatus.success,
            order: fromMobileOrder(order),
            currentOrderId: order.id,
            offer: null,
            flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
            errorMessage: null,
          ),
        );
      },
    );
    _log('loadCurrentOrder finished');
    _loadingInProgress = false;
  }

  Future<bool> acceptDeliveryOrder() async {
    if (state.isFreelancerOfferFlow) {
      _log('acceptDeliveryOrder detected freelancer offer flow');
      return _acceptFreelancerOffer(expectedOrderType: OrderTypeMock.delivery);
    }

    final currentOrderId = state.currentOrderId;
    if (currentOrderId == null || currentOrderId <= 0) {
      _log('acceptDeliveryOrder failed before request: invalid currentOrderId');
      emit(
        state.copyWith(
          actionStatus: IncomingOrderActionStatus.failure,
          actionErrorMessage: 'No valid current order id is stored yet.',
        ),
      );
      return false;
    }

    _log('acceptDeliveryOrder started for orderId=$currentOrderId');
    emit(
      state.copyWith(
        actionStatus: IncomingOrderActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );

    const riderStatusStepOne = 1;
    if (kDebugMode) {
      debugPrint('================ ACCEPT DELIVERY FLOW ================');
      debugPrint('[ACCEPT FLOW] using stored currentOrderId = $currentOrderId');
      debugPrint(
          '[ACCEPT FLOW] sending rider status step = $riderStatusStepOne');
    }
    final result = await _updateRiderStatusUseCase(
      orderId: currentOrderId.toString(),
      status: riderStatusStepOne,
    );

    return result.fold(
      (error) {
        _log('acceptDeliveryOrder failed after request: ${error.message}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.failure,
            actionErrorMessage: error.message,
          ),
        );
        return false;
      },
      (_) {
        _log(
          'acceptDeliveryOrder succeeded. '
          'Emitting actionStatus=success for orderId=$currentOrderId',
        );
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.success,
            actionErrorMessage: null,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> acceptPickupOrder() async {
    if (state.isFreelancerOfferFlow) {
      _log('acceptPickupOrder detected freelancer offer flow');
      return _acceptFreelancerOffer(expectedOrderType: OrderTypeMock.pickup);
    }

    final currentOrderId = state.currentOrderId;
    if (currentOrderId == null || currentOrderId <= 0) {
      _log('acceptPickupOrder failed before request: invalid currentOrderId');
      emit(
        state.copyWith(
          actionStatus: IncomingOrderActionStatus.failure,
          actionErrorMessage: 'No valid current order id is stored yet.',
        ),
      );
      return false;
    }

    _log('acceptPickupOrder started for orderId=$currentOrderId');
    emit(
      state.copyWith(
        actionStatus: IncomingOrderActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );

    const pickupStatusStepOne = 1;
    final result = await _updatePickupStatusUseCase(
      orderId: currentOrderId.toString(),
      status: pickupStatusStepOne,
    );

    return result.fold(
      (error) {
        _log('acceptPickupOrder failed after request: ${error.message}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.failure,
            actionErrorMessage: error.message,
          ),
        );
        return false;
      },
      (_) {
        _log(
          'acceptPickupOrder succeeded. '
          'Emitting actionStatus=success for orderId=$currentOrderId',
        );
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.success,
            actionErrorMessage: null,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> rejectCurrentOffer() async {
    final offer = state.offer;
    if (offer == null) {
      _log('rejectCurrentOffer failed because state.offer is null');
      emit(
        state.copyWith(
          actionStatus: IncomingOrderActionStatus.failure,
          actionErrorMessage: 'No active offer is available to reject.',
        ),
      );
      return false;
    }

    _log(
      'rejectCurrentOffer started for offerId=${offer.offerId}, '
      'orderId=${offer.orderId}',
    );
    emit(
      state.copyWith(
        actionStatus: IncomingOrderActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );

    final result = await _rejectOrderOfferUseCase(offer.offerId);
    return result.fold(
      (error) {
        _log('rejectCurrentOffer failed: ${error.message}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.failure,
            actionErrorMessage: error.message,
          ),
        );
        return false;
      },
      (_) {
        _log('rejectCurrentOffer succeeded for offerId=${offer.offerId}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.success,
            actionErrorMessage: null,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> _acceptFreelancerOffer({
    required OrderTypeMock expectedOrderType,
  }) async {
    final offer = state.offer;
    if (offer == null) {
      _log('_acceptFreelancerOffer failed because state.offer is null');
      emit(
        state.copyWith(
          actionStatus: IncomingOrderActionStatus.failure,
          actionErrorMessage: 'No active offer is available to accept.',
        ),
      );
      return false;
    }

    _log(
      '_acceptFreelancerOffer started. '
      'offerId=${offer.offerId}, orderId=${offer.orderId}, '
      'expectedOrderType=${expectedOrderType.name}, '
      'remainingSeconds=${offer.remainingSeconds}',
    );
    emit(
      state.copyWith(
        actionStatus: IncomingOrderActionStatus.submitting,
        actionErrorMessage: null,
      ),
    );

    final acceptResult = await _acceptOrderOfferUseCase(offer.offerId);
    final accepted = await acceptResult.fold(
      (error) async {
        _log('Offer accept API failed: ${error.message}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.failure,
            actionErrorMessage: error.message,
          ),
        );
        return false;
      },
      (_) async {
        _log('Offer accept API succeeded for offerId=${offer.offerId}');
        return true;
      },
    );
    if (!accepted) {
      return false;
    }

    _log('Fetching current order immediately after offer acceptance');
    final currentOrderResult = await _getCurrentOrderUseCase();
    final currentOrder = currentOrderResult.fold(
      (error) {
        _log(
            'Current order fetch after offer acceptance failed: ${error.message}');
        emit(
          state.copyWith(
            actionStatus: IncomingOrderActionStatus.failure,
            actionErrorMessage: error.message,
          ),
        );
        return null;
      },
      (order) => order,
    );
    if (currentOrder == null) {
      _log('Current order fetch after offer acceptance returned data=null');
      emit(
        state.copyWith(
          actionStatus: IncomingOrderActionStatus.failure,
          actionErrorMessage:
              'Offer was accepted, but no active order was returned yet.',
        ),
      );
      return false;
    }

    _log(
      'Current order fetched after acceptance. '
      'orderId=${currentOrder.id}, type=${currentOrder.orderType.name}, '
      'status=${currentOrder.status.name}, '
      'riderStatus=${currentOrder.riderStatus?.name}, '
      'pickupRiderStatus=${currentOrder.pickupRiderStatus?.name}',
    );

    emit(
      state.copyWith(
        order: fromMobileOrder(currentOrder),
        currentOrderId: currentOrder.id,
        flowType: IncomingOrderFlowType.freelancerOffer,
      ),
    );

    _log(
      'Offer accept flow completed without sending step-1 rider status. '
      'orderId=${currentOrder.id}, expectedOrderType=${expectedOrderType.name}',
    );
    emit(
      state.copyWith(
        actionStatus: IncomingOrderActionStatus.success,
        actionErrorMessage: null,
      ),
    );
    return true;
  }
}
