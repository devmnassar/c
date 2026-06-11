part of 'incoming_order_cubit.dart';

enum IncomingOrderStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

enum IncomingOrderFlowType {
  fullTimeCurrentOrder,
  freelancerOffer,
}

enum IncomingOrderActionStatus {
  initial,
  submitting,
  success,
  failure,
}

class IncomingOrderState {
  const IncomingOrderState({
    this.status = IncomingOrderStatus.initial,
    this.actionStatus = IncomingOrderActionStatus.initial,
    this.flowType = IncomingOrderFlowType.fullTimeCurrentOrder,
    this.order,
    this.currentOrderId,
    this.offer,
    this.errorMessage,
    this.actionErrorMessage,
  });

  final IncomingOrderStatus status;
  final IncomingOrderActionStatus actionStatus;
  final IncomingOrderFlowType flowType;
  final OrderMock? order;
  final int? currentOrderId;
  final MobileOrderOffer? offer;
  final String? errorMessage;
  final String? actionErrorMessage;

  bool get isLoading => status == IncomingOrderStatus.loading;
  bool get isSubmitting => actionStatus == IncomingOrderActionStatus.submitting;
  bool get isFreelancerOfferFlow =>
      flowType == IncomingOrderFlowType.freelancerOffer;

  IncomingOrderState copyWith({
    IncomingOrderStatus? status,
    IncomingOrderActionStatus? actionStatus,
    IncomingOrderFlowType? flowType,
    OrderMock? order,
    Object? currentOrderId = _unset,
    Object? offer = _unset,
    Object? errorMessage = _unset,
    Object? actionErrorMessage = _unset,
  }) {
    return IncomingOrderState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      flowType: flowType ?? this.flowType,
      order: order ?? this.order,
      currentOrderId: identical(currentOrderId, _unset)
          ? this.currentOrderId
          : currentOrderId as int?,
      offer: identical(offer, _unset) ? this.offer : offer as MobileOrderOffer?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      actionErrorMessage: identical(actionErrorMessage, _unset)
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
    );
  }
}

const Object _unset = Object();
