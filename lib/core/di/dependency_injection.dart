import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:gaseel_courier/core/networking/dio_client.dart';
import 'package:gaseel_courier/features/auth/forget_password/data/datasources/forget_password_remote_data_source.dart';
import 'package:gaseel_courier/features/auth/forget_password/data/repositories/forget_password_repository_impl.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/repositories/forget_password_repository.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/reset_password_use_case.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/send_reset_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/verify_reset_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_cubit.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_otp_cubit.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/reset_password_cubit.dart';
import 'package:gaseel_courier/features/auth/login/data/datasources/login_remote_data_source.dart';
import 'package:gaseel_courier/features/auth/login/data/repositories/login_repository_impl.dart';
import 'package:gaseel_courier/features/auth/login/domain/repositories/login_repository.dart';
import 'package:gaseel_courier/features/auth/login/domain/usecases/login_use_case.dart';
import 'package:gaseel_courier/features/auth/login/presentation/cubit/login_cubit.dart';
import 'package:gaseel_courier/features/courier_profile/data/datasources/courier_profile_local_data_source.dart';
import 'package:gaseel_courier/features/courier_profile/data/datasources/courier_profile_remote_data_source.dart';
import 'package:gaseel_courier/features/courier_profile/data/repositories/courier_profile_repository_impl.dart';
import 'package:gaseel_courier/features/courier_profile/domain/repositories/courier_profile_repository.dart';
import 'package:gaseel_courier/features/courier_profile/domain/usecases/get_courier_profile_use_case.dart';
import 'package:gaseel_courier/features/courier_profile/presentation/cubit/courier_profile_cubit.dart';
import 'package:gaseel_courier/features/driver_availability/data/datasources/driver_availability_remote_data_source.dart';
import 'package:gaseel_courier/features/driver_availability/data/datasources/go_online_context_local_data_source.dart';
import 'package:gaseel_courier/features/driver_availability/data/datasources/operations_hub_data_source.dart';
import 'package:gaseel_courier/features/driver_availability/data/repositories/driver_availability_repository_impl.dart';
import 'package:gaseel_courier/features/driver_availability/data/repositories/heartbeat_context_repository_impl.dart';
import 'package:gaseel_courier/features/driver_availability/data/repositories/go_offline_context_repository_impl.dart';
import 'package:gaseel_courier/features/driver_availability/data/repositories/go_online_context_repository_impl.dart';
import 'package:gaseel_courier/features/driver_availability/domain/repositories/heartbeat_context_repository.dart';
import 'package:gaseel_courier/features/driver_availability/domain/repositories/go_offline_context_repository.dart';
import 'package:gaseel_courier/features/driver_availability/domain/repositories/driver_availability_repository.dart';
import 'package:gaseel_courier/features/driver_availability/domain/repositories/go_online_context_repository.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_heartbeat_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_offline_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_online_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/heartbeat_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_offline_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_online_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/courier_location_sync_cubit.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/heartbeat_cubit.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/go_offline_cubit.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/go_online_cubit.dart';
import 'package:gaseel_courier/features/delivery/presentation/cubit/delivery_completion_cubit.dart';
import 'package:gaseel_courier/features/incoming/presentation/cubit/incoming_order_cubit.dart';
import 'package:gaseel_courier/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:gaseel_courier/features/orders/data/repositories/mobile_orders_repository_impl.dart';
import 'package:gaseel_courier/features/orders/domain/repositories/mobile_orders_repository.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_order_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_order_checklist_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_orders_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/accept_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/reject_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/submit_order_checklist_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_pickup_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/upload_proof_photo_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_rider_status_use_case.dart';
import 'package:gaseel_courier/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:gaseel_courier/features/delivery/presentation/cubit/attempted_delivery_checklist_cubit.dart';
import 'package:gaseel_courier/features/trip/presentation/cubit/pickup_status_cubit.dart';
import 'package:gaseel_courier/features/auth/sign_up/data/datasources/sign_up_phone_remote_data_source.dart';
import 'package:gaseel_courier/features/auth/sign_up/data/repositories/sign_up_phone_repository_impl.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/repositories/sign_up_phone_repository.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/register_with_phone_use_case.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/send_register_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/verify_register_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/cubit/sign_up_phone_number_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(createDioClient);
  }

  if (!getIt.isRegistered<SignUpPhoneRemoteDataSource>()) {
    getIt.registerLazySingleton<SignUpPhoneRemoteDataSource>(
      () => SignUpPhoneRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<LoginRemoteDataSource>()) {
    getIt.registerLazySingleton<LoginRemoteDataSource>(
      () => LoginRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<CourierProfileRemoteDataSource>()) {
    getIt.registerLazySingleton<CourierProfileRemoteDataSource>(
      () => CourierProfileRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<CourierProfileLocalDataSource>()) {
    getIt.registerLazySingleton<CourierProfileLocalDataSource>(
      CourierProfileLocalDataSource.new,
    );
  }

  if (!getIt.isRegistered<ForgetPasswordRemoteDataSource>()) {
    getIt.registerLazySingleton<ForgetPasswordRemoteDataSource>(
      () => ForgetPasswordRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<OrdersRemoteDataSource>()) {
    getIt.registerLazySingleton<OrdersRemoteDataSource>(
      () => OrdersRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<DriverAvailabilityRemoteDataSource>()) {
    getIt.registerLazySingleton<DriverAvailabilityRemoteDataSource>(
      () => DriverAvailabilityRemoteDataSource(getIt<Dio>()),
    );
  }

  if (!getIt.isRegistered<GoOnlineContextLocalDataSource>()) {
    getIt.registerLazySingleton<GoOnlineContextLocalDataSource>(
      GoOnlineContextLocalDataSource.new,
    );
  }

  if (!getIt.isRegistered<OperationsHubDataSource>()) {
    getIt.registerLazySingleton<OperationsHubDataSource>(
      OperationsHubDataSource.new,
    );
  }

  if (!getIt.isRegistered<LoginRepository>()) {
    getIt.registerLazySingleton<LoginRepository>(
      () => LoginRepositoryImpl(getIt<LoginRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<ForgetPasswordRepository>()) {
    getIt.registerLazySingleton<ForgetPasswordRepository>(
      () =>
          ForgetPasswordRepositoryImpl(getIt<ForgetPasswordRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<CourierProfileRepository>()) {
    getIt.registerLazySingleton<CourierProfileRepository>(
      () => CourierProfileRepositoryImpl(
        getIt<CourierProfileRemoteDataSource>(),
        getIt<CourierProfileLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<MobileOrdersRepository>()) {
    getIt.registerLazySingleton<MobileOrdersRepository>(
      () => MobileOrdersRepositoryImpl(getIt<OrdersRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<DriverAvailabilityRepository>()) {
    getIt.registerLazySingleton<DriverAvailabilityRepository>(
      () => DriverAvailabilityRepositoryImpl(
        getIt<DriverAvailabilityRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GoOnlineContextRepository>()) {
    getIt.registerLazySingleton<GoOnlineContextRepository>(
      () => GoOnlineContextRepositoryImpl(
        getIt<GoOnlineContextLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GoOfflineContextRepository>()) {
    getIt.registerLazySingleton<GoOfflineContextRepository>(
      () => GoOfflineContextRepositoryImpl(
        getIt<GoOnlineContextLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<HeartbeatContextRepository>()) {
    getIt.registerLazySingleton<HeartbeatContextRepository>(
      () => HeartbeatContextRepositoryImpl(
        getIt<GoOnlineContextLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<LoginRepository>()),
    );
  }

  if (!getIt.isRegistered<SendResetOtpUseCase>()) {
    getIt.registerLazySingleton<SendResetOtpUseCase>(
      () => SendResetOtpUseCase(getIt<ForgetPasswordRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCourierProfileUseCase>()) {
    getIt.registerLazySingleton<GetCourierProfileUseCase>(
      () => GetCourierProfileUseCase(getIt<CourierProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<VerifyResetOtpUseCase>()) {
    getIt.registerLazySingleton<VerifyResetOtpUseCase>(
      () => VerifyResetOtpUseCase(getIt<ForgetPasswordRepository>()),
    );
  }

  if (!getIt.isRegistered<ResetPasswordUseCase>()) {
    getIt.registerLazySingleton<ResetPasswordUseCase>(
      () => ResetPasswordUseCase(getIt<ForgetPasswordRepository>()),
    );
  }

  if (!getIt.isRegistered<GetOrdersUseCase>()) {
    getIt.registerLazySingleton<GetOrdersUseCase>(
      () => GetOrdersUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCurrentOrderUseCase>()) {
    getIt.registerLazySingleton<GetCurrentOrderUseCase>(
      () => GetCurrentOrderUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCurrentOfferUseCase>()) {
    getIt.registerLazySingleton<GetCurrentOfferUseCase>(
      () => GetCurrentOfferUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<GetOrderChecklistUseCase>()) {
    getIt.registerLazySingleton<GetOrderChecklistUseCase>(
      () => GetOrderChecklistUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<SubmitOrderChecklistUseCase>()) {
    getIt.registerLazySingleton<SubmitOrderChecklistUseCase>(
      () => SubmitOrderChecklistUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<AcceptOrderOfferUseCase>()) {
    getIt.registerLazySingleton<AcceptOrderOfferUseCase>(
      () => AcceptOrderOfferUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<RejectOrderOfferUseCase>()) {
    getIt.registerLazySingleton<RejectOrderOfferUseCase>(
      () => RejectOrderOfferUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateRiderStatusUseCase>()) {
    getIt.registerLazySingleton<UpdateRiderStatusUseCase>(
      () => UpdateRiderStatusUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdatePickupStatusUseCase>()) {
    getIt.registerLazySingleton<UpdatePickupStatusUseCase>(
      () => UpdatePickupStatusUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<UploadProofPhotoUseCase>()) {
    getIt.registerLazySingleton<UploadProofPhotoUseCase>(
      () => UploadProofPhotoUseCase(getIt<MobileOrdersRepository>()),
    );
  }

  if (!getIt.isRegistered<BuildGoOnlineRequestUseCase>()) {
    getIt.registerLazySingleton<BuildGoOnlineRequestUseCase>(
      () => BuildGoOnlineRequestUseCase(getIt<GoOnlineContextRepository>()),
    );
  }

  if (!getIt.isRegistered<GoOnlineUseCase>()) {
    getIt.registerLazySingleton<GoOnlineUseCase>(
      () => GoOnlineUseCase(getIt<DriverAvailabilityRepository>()),
    );
  }

  if (!getIt.isRegistered<BuildGoOfflineRequestUseCase>()) {
    getIt.registerLazySingleton<BuildGoOfflineRequestUseCase>(
      () => BuildGoOfflineRequestUseCase(getIt<GoOfflineContextRepository>()),
    );
  }

  if (!getIt.isRegistered<GoOfflineUseCase>()) {
    getIt.registerLazySingleton<GoOfflineUseCase>(
      () => GoOfflineUseCase(getIt<DriverAvailabilityRepository>()),
    );
  }

  if (!getIt.isRegistered<BuildHeartbeatRequestUseCase>()) {
    getIt.registerLazySingleton<BuildHeartbeatRequestUseCase>(
      () => BuildHeartbeatRequestUseCase(getIt<HeartbeatContextRepository>()),
    );
  }

  if (!getIt.isRegistered<HeartbeatUseCase>()) {
    getIt.registerLazySingleton<HeartbeatUseCase>(
      () => HeartbeatUseCase(getIt<DriverAvailabilityRepository>()),
    );
  }

  if (!getIt.isRegistered<SignUpPhoneRepository>()) {
    getIt.registerLazySingleton<SignUpPhoneRepository>(
      () => SignUpPhoneRepositoryImpl(getIt<SignUpPhoneRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<SendRegisterOtpUseCase>()) {
    getIt.registerLazySingleton<SendRegisterOtpUseCase>(
      () => SendRegisterOtpUseCase(getIt<SignUpPhoneRepository>()),
    );
  }

  if (!getIt.isRegistered<VerifyRegisterOtpUseCase>()) {
    getIt.registerLazySingleton<VerifyRegisterOtpUseCase>(
      () => VerifyRegisterOtpUseCase(getIt<SignUpPhoneRepository>()),
    );
  }

  if (!getIt.isRegistered<RegisterWithPhoneUseCase>()) {
    getIt.registerLazySingleton<RegisterWithPhoneUseCase>(
      () => RegisterWithPhoneUseCase(getIt<SignUpPhoneRepository>()),
    );
  }

  if (!getIt.isRegistered<SignUpPhoneNumberCubit>()) {
    getIt.registerFactory<SignUpPhoneNumberCubit>(
      () => SignUpPhoneNumberCubit(
        sendRegisterOtpUseCase: getIt<SendRegisterOtpUseCase>(),
        verifyRegisterOtpUseCase: getIt<VerifyRegisterOtpUseCase>(),
        registerWithPhoneUseCase: getIt<RegisterWithPhoneUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginCubit>()) {
    getIt.registerFactory<LoginCubit>(
      () => LoginCubit(loginUseCase: getIt<LoginUseCase>()),
    );
  }

  if (!getIt.isRegistered<CourierProfileCubit>()) {
    getIt.registerFactory<CourierProfileCubit>(
      () => CourierProfileCubit(
        getCourierProfileUseCase: getIt<GetCourierProfileUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<ForgetPasswordCubit>()) {
    getIt.registerFactory<ForgetPasswordCubit>(
      () => ForgetPasswordCubit(
        sendResetOtpUseCase: getIt<SendResetOtpUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<ForgetPasswordOtpCubit>()) {
    getIt.registerFactory<ForgetPasswordOtpCubit>(
      () => ForgetPasswordOtpCubit(
        sendResetOtpUseCase: getIt<SendResetOtpUseCase>(),
        verifyResetOtpUseCase: getIt<VerifyResetOtpUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<ResetPasswordCubit>()) {
    getIt.registerFactory<ResetPasswordCubit>(
      () => ResetPasswordCubit(
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<IncomingOrderCubit>()) {
    getIt.registerFactory<IncomingOrderCubit>(
      () => IncomingOrderCubit(
        getCurrentOrderUseCase: getIt<GetCurrentOrderUseCase>(),
        getCurrentOfferUseCase: getIt<GetCurrentOfferUseCase>(),
        acceptOrderOfferUseCase: getIt<AcceptOrderOfferUseCase>(),
        rejectOrderOfferUseCase: getIt<RejectOrderOfferUseCase>(),
        updateRiderStatusUseCase: getIt<UpdateRiderStatusUseCase>(),
        updatePickupStatusUseCase: getIt<UpdatePickupStatusUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<OrdersCubit>()) {
    getIt.registerFactory<OrdersCubit>(
      () => OrdersCubit(
        getOrdersUseCase: getIt<GetOrdersUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<DeliveryCompletionCubit>()) {
    getIt.registerFactory<DeliveryCompletionCubit>(
      () => DeliveryCompletionCubit(
        uploadProofPhotoUseCase: getIt<UploadProofPhotoUseCase>(),
        updateRiderStatusUseCase: getIt<UpdateRiderStatusUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<AttemptedDeliveryChecklistCubit>()) {
    getIt.registerFactory<AttemptedDeliveryChecklistCubit>(
      () => AttemptedDeliveryChecklistCubit(
        getOrderChecklistUseCase: getIt<GetOrderChecklistUseCase>(),
        submitOrderChecklistUseCase: getIt<SubmitOrderChecklistUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<PickupStatusCubit>()) {
    getIt.registerFactory<PickupStatusCubit>(
      () => PickupStatusCubit(
        updatePickupStatusUseCase: getIt<UpdatePickupStatusUseCase>(),
        uploadProofPhotoUseCase: getIt<UploadProofPhotoUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<GoOnlineCubit>()) {
    getIt.registerFactory<GoOnlineCubit>(
      () => GoOnlineCubit(
        buildGoOnlineRequestUseCase: getIt<BuildGoOnlineRequestUseCase>(),
        goOnlineUseCase: getIt<GoOnlineUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<GoOfflineCubit>()) {
    getIt.registerFactory<GoOfflineCubit>(
      () => GoOfflineCubit(
        buildGoOfflineRequestUseCase: getIt<BuildGoOfflineRequestUseCase>(),
        goOfflineUseCase: getIt<GoOfflineUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<HeartbeatCubit>()) {
    getIt.registerLazySingleton<HeartbeatCubit>(
      () => HeartbeatCubit(
        buildHeartbeatRequestUseCase: getIt<BuildHeartbeatRequestUseCase>(),
        heartbeatUseCase: getIt<HeartbeatUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<CourierLocationSyncCubit>()) {
    getIt.registerLazySingleton<CourierLocationSyncCubit>(
      () => CourierLocationSyncCubit(
        operationsHubDataSource: getIt<OperationsHubDataSource>(),
        locationDataSource: getIt<GoOnlineContextLocalDataSource>(),
      ),
    );
  }
}
