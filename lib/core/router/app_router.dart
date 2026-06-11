import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/login/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/stats/presentation/pages/stats_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../screens/courier_map_status_screen.dart';
import '../../core/onboarding/onboarding_state.dart';
import '../../features/onboarding/presentation/pages/permissions_page.dart';
import '../../features/onboarding/presentation/pages/location_setup_page.dart';
import '../../features/onboarding/presentation/pages/awaiting_review_page.dart';
import '../../features/auth/sign_up/presentation/pages/sign_up_phone_page.dart';
import '../../features/auth/sign_up/presentation/pages/sign_up_page.dart'
    as auth_signup;
import '../../features/auth/sign_up/presentation/pages/welcome_page.dart';
import '../../features/auth/documents/document_upload/presentation/pages/document_upload_page.dart';
import '../../features/auth/documents/driver_card_details/presentation/pages/driver_card_details_page.dart';
import '../../features/auth/documents/iqama_details/presentation/pages/iqama_details_page.dart';
import '../../features/auth/documents/license_details/presentation/pages/license_details_page.dart';
import '../../features/auth/documents/selfie_details/presentation/pages/selfie_details_page.dart';
import '../../features/auth/documents/vehicle_registration_details/presentaion/pages/vehicle_registration_details_page.dart';
import '../../features/auth/forget_password/presentation/pages/forget_password_page.dart';
import '../../features/auth/forget_password/presentation/pages/forget_passoword_otp_verification_page.dart';
import '../../features/auth/forget_password/presentation/pages/create_new_password_page.dart';
import '../../features/auth/otp/presentation/page/otp_verification_page.dart'
    as auth_otp;
import '../../features/incoming/presentation/pages/incoming_order_full_map_page.dart';
import '../../features/incoming/presentation/pages/incoming_order_page.dart';
import '../../features/trip/presentation/pages/active_trip_page.dart';
import '../../features/trip/presentation/pages/active_trip_full_map_page.dart';
import '../../core/di/dependency_injection.dart';
import '../../features/driver_availability/presentation/cubit/go_online_cubit.dart';
import '../../features/driver_availability/presentation/cubit/go_offline_cubit.dart';
import '../../features/orders/domain/models/order_mock.dart';
import '../../features/incoming/presentation/cubit/incoming_order_cubit.dart';
import '../../features/incoming/presentation/models/incoming_order_route_args.dart';
import '../../features/courier_profile/presentation/cubit/courier_profile_cubit.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: OnboardingState.instance,
    redirect: (context, state) async {
      await OnboardingState.instance.ensureLoaded();
      final hasCompletedSplash = await SharedPrefHelper.getBool(
        SharedPrefKeys.splashCompleted,
      );

      final s = OnboardingState.instance;
      final loc = state.matchedLocation;
      if (loc == '/splash' && hasCompletedSplash) {
        if (!s.isLoggedIn) {
          return s.welcomeEntered ? WelcomePage.id : '/login';
        }
        if (!s.permissionsGranted) return '/permissions';
        if (!s.locationServiceEnabled) return '/location-setup';
        return '/map-status';
      }

      // Legacy route: keep working but route into onboarding.
      if (loc == '/permission') {
        return '/permissions';
      }

      // Allow access to login and signup flows when not logged in
      if (!s.isLoggedIn) {
        // If user already reached welcome before, reopen app directly on welcome.
        if (s.welcomeEntered && loc == '/login') {
          return WelcomePage.id;
        }
        if (loc == '/splash' ||
            loc == '/login' ||
            loc.startsWith('/signup') ||
            loc.startsWith('/forget-password')) {
          return null;
        }
        return '/login';
      }

      // If logged in but basic setup not complete
      if (!s.permissionsGranted)
        return loc == '/permissions' ? null : '/permissions';
      if (!s.locationServiceEnabled)
        return loc == '/location-setup' ? null : '/location-setup';

      // SignUp/Documents/Review are and handled via /signup before logging in.
      // We don't force them after login to satisfy "not after login" request.

      // Onboarding complete -> map-status (first screen after login+profile); block going back to onboarding/login
      if (loc == '/login' ||
          loc == '/splash' ||
          loc.startsWith('/signup') ||
          loc.startsWith('/forget-password') ||
          loc == '/permissions' ||
          loc == '/location-setup') {
        return '/map-status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: ForgetPasswordPage.id,
        name: 'forgetPassword',
        builder: (context, state) => const ForgetPasswordPage(),
      ),
      GoRoute(
        path: ForgetPasswordOtpVerificationPage.id,
        name: 'forgetPasswordOtp',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return ForgetPasswordOtpVerificationPage(
              phoneNumber: extra['phoneNumber'] as String? ?? '',
              nextRoute:
                  extra['nextRoute'] as String? ?? CreateNewPasswordPage.id,
              expiresInSeconds: (extra['expiresInSeconds'] as num?)?.toInt(),
              debugOtpCode: extra['debugOtpCode'] as String?,
            );
          }
          return const ForgetPasswordOtpVerificationPage(
            phoneNumber: '',
            nextRoute: CreateNewPasswordPage.id,
          );
        },
      ),
      GoRoute(
        path: CreateNewPasswordPage.id,
        name: 'createNewPassword',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return CreateNewPasswordPage(
              phoneNumber: extra['phoneNumber'] as String? ?? '',
            );
          }
          return const CreateNewPasswordPage(phoneNumber: '');
        },
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPhonePage(),
        routes: [
          GoRoute(
            path: 'otp',
            name: 'signupOtp',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return auth_otp.OtpVerificationPage(
                  phoneNumber: extra['phoneNumber'] as String? ?? '',
                  nextRoute: extra['nextRoute'] as String? ??
                      auth_signup.SignUpPage.id,
                );
              }
              final phoneNumber = extra as String? ?? '';
              return auth_otp.OtpVerificationPage(
                phoneNumber: phoneNumber,
                nextRoute: auth_signup.SignUpPage.id,
              );
            },
          ),
          GoRoute(
            path: 'documents',
            name: 'signupDocuments',
            builder: (context, state) => const DocumentUploadPage(),
          ),
          GoRoute(
            path: 'awaiting-review',
            name: 'signupReview',
            builder: (context, state) => const AwaitingReviewPage(),
          ),
        ],
      ),
      GoRoute(
        path: IqamaDetailsPage.id,
        name: 'docIqama',
        builder: (context, state) => const IqamaDetailsPage(),
      ),
      GoRoute(
        path: SelfieDetailsPage.id,
        name: 'docSelfie',
        builder: (context, state) => const SelfieDetailsPage(),
      ),
      GoRoute(
        path: LicenseDetailsPage.id,
        name: 'docLicense',
        builder: (context, state) => const LicenseDetailsPage(),
      ),
      GoRoute(
        path: VehicleRegistrationDetailsPage.id,
        name: 'docRegistration',
        builder: (context, state) => const VehicleRegistrationDetailsPage(),
      ),
      GoRoute(
        path: DriverCardDetailsPage.id,
        name: 'docDriverCard',
        builder: (context, state) => const DriverCardDetailsPage(),
      ),
      GoRoute(
        path: auth_signup.SignUpPage.id,
        name: 'signupDetails',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          return auth_signup.SignUpPage(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: WelcomePage.id,
        name: 'signupWelcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CourierProfileCubit>(),
          child: const PermissionsPage(),
        ),
      ),
      GoRoute(
        path: '/location-setup',
        name: 'locationSetup',
        builder: (context, state) => const LocationSetupPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeShellPage(),
        routes: [
          GoRoute(
            path: 'orders',
            name: 'homeOrders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: 'stats',
            name: 'stats',
            builder: (context, state) => const StatsPage(),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: NotificationsPage.id,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/map-status',
        name: 'mapStatus',
        builder: (context, state) {
          final autoSearch =
              state.extra is Map && (state.extra as Map)['autoSearch'] == true;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<GoOnlineCubit>(),
              ),
              BlocProvider(
                create: (_) => getIt<GoOfflineCubit>(),
              ),
            ],
            child: CourierMapStatusScreen(autoSearch: autoSearch),
          );
        },
      ),
      GoRoute(
        path: '/active-trip/:id',
        name: 'activeTrip',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          OrderMock? initialOrder;
          String entrySource = 'map-status';

          if (extra is OrderMock) {
            initialOrder = extra;
          } else if (extra is Map<String, dynamic>) {
            initialOrder = extra['order'] as OrderMock?;
            entrySource =
                extra['entrySource'] as String? ?? entrySource;
          }

          return ActiveTripPage(
            orderId: id,
            initialOrder: initialOrder,
            entrySource: entrySource,
          );
        },
        routes: [
          GoRoute(
            path: 'map',
            name: 'activeTripFullMap',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return ActiveTripFullMapPage(
                  orderId: id,
                  initialOrder: extra['order'] as OrderMock?,
                  deliveryRiderStatus:
                      (extra['deliveryRiderStatus'] as num?)?.toInt(),
                  pickupRiderStatus:
                      (extra['pickupRiderStatus'] as num?)?.toInt(),
                );
              }
              return ActiveTripFullMapPage(orderId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/incoming-order',
        name: 'incomingOrder',
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is IncomingOrderRouteArgs
              ? extra
              : IncomingOrderRouteArgs(initialOrder: extra as OrderMock?);
          return BlocProvider(
            create: (_) => getIt<IncomingOrderCubit>(),
            child: IncomingOrderPage(
              initialOrder: args.initialOrder,
              initialOffer: args.initialOffer,
              loadCurrentOfferOnOpen: args.loadCurrentOfferOnOpen,
              showEmptyState: args.showEmptyState,
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'map',
            name: 'incomingOrderFullMap',
            builder: (context, state) {
              final order = state.extra as OrderMock?;
              if (order == null) {
                return const IncomingOrderPage();
              }
              return IncomingOrderFullMapPage(order: order);
            },
          ),
        ],
      ),
    ],
  );
}
