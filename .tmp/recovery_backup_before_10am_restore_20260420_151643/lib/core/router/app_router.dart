import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_passoword_otp_verification_page.dart';
import 'package:gaseel_courier/features/auth/login/presentation/pages/login_page.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_password_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/pages/sign_up_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/pages/sign_up_phone_page.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/stats/presentation/pages/stats_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../screens/courier_map_status_screen.dart';
import '../../core/onboarding/onboarding_state.dart';
import '../../features/onboarding/presentation/pages/permissions_page.dart';
import '../../features/onboarding/presentation/pages/location_setup_page.dart';
import '../../features/auth/otp/presentation/page/otp_verification_page.dart';
import '../../features/auth/documents/document_upload/presentation/pages/document_upload_page.dart';
import '../../features/onboarding/presentation/pages/awaiting_review_page.dart';
import '../../features/onboarding/presentation/pages/documents_review_page.dart';
import '../../features/auth/documents/iqama_details/presentation/pages/iqama_details_page.dart';
import '../../features/auth/documents/selfie_details/presentation/pages/selfie_details_page.dart';
import '../../features/auth/documents/license_details/presentation/pages/license_details_page.dart';
import '../../features/auth/documents/vehicle_registration_details/presentaion/pages/vehicle_registration_details_page.dart';
import '../../features/auth/documents/driver_card_details/presentation/pages/driver_card_details_page.dart';
import '../../features/incoming/presentation/pages/incoming_order_full_map_page.dart';
import '../../features/incoming/presentation/pages/incoming_order_page.dart';
import '../../features/trip/presentation/pages/active_trip_page.dart';
import '../../features/trip/presentation/pages/active_trip_full_map_page.dart';
import '../../features/orders/domain/models/order_mock.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: LoginPage.id,
    refreshListenable: OnboardingState.instance,
    redirect: (context, state) async {
      await OnboardingState.instance.ensureLoaded();

      final s = OnboardingState.instance;
      final loc = state.matchedLocation;

      if (loc == '/permission') {
        return PermissionsPage.id;
      }

      if (!s.isLoggedIn) {
        if (loc == LoginPage.id ||
            loc == ForgetPasswordPage.id ||
            loc == SignUpPhonePage.id ||
            loc == SignUpPage.id ||
            loc.startsWith(SignUpOtpVerificationPage.id) ||
            loc.startsWith(ForgetPasswordOtpVerificationPage.id) ||
            loc.startsWith(DocumentUploadPage.id) ||
            loc.startsWith(DocumentsReviewPage.id) ||
            loc.startsWith(AwaitingReviewPage.id)) {
          return null;
        }
        return LoginPage.id;
      }

      if (!s.permissionsGranted) {
        return loc == PermissionsPage.id ? null : PermissionsPage.id;
      }
      if (!s.locationServiceEnabled) {
        return loc == LocationSetupPage.id ? null : LocationSetupPage.id;
      }

      if (loc == LoginPage.id ||
          loc == ForgetPasswordPage.id ||
          loc == SignUpPhonePage.id ||
          loc == SignUpPage.id ||
          loc.startsWith('${SignUpPage.id}/') ||
          loc == PermissionsPage.id ||
          loc == LocationSetupPage.id) {
        return CourierMapStatusScreen.id;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashPage.id,
        name: SplashPage.id,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.id,
        name: LoginPage.id,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: SignUpPhonePage.id,
        name: SignUpPhonePage.id,
        builder: (context, state) => const SignUpPhonePage(),
      ),
      GoRoute(
        path: ForgetPasswordPage.id,
        name: ForgetPasswordPage.id,
        builder: (context, state) => const ForgetPasswordPage(),
      ),
      GoRoute(
        path: SignUpPage.id,
        name: SignUpPage.id,
        builder: (context, state) {
          final extra = state.extra;
          final phoneNumber = extra is String
              ? extra
              : extra is Map<String, dynamic>
                  ? extra['phoneNumber'] as String?
                  : null;
          return SignUpPage(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: SignUpOtpVerificationPage.id,
        name: SignUpOtpVerificationPage.id,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return SignUpOtpVerificationPage(
              phoneNumber: extra['phoneNumber'] as String? ?? '',
              nextRoute: extra['nextRoute'] as String? ?? DocumentUploadPage.id,
            );
          }

          return SignUpOtpVerificationPage(
            phoneNumber: extra as String? ?? '',
            nextRoute: DocumentUploadPage.id,
          );
        },
      ),
      GoRoute(
        path: ForgetPasswordOtpVerificationPage.id,
        name: ForgetPasswordOtpVerificationPage.id,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return ForgetPasswordOtpVerificationPage(
              phoneNumber: extra['phoneNumber'] as String? ?? '',
              nextRoute: extra['nextRoute'] as String? ?? LoginPage.id,
            );
          }

          return ForgetPasswordOtpVerificationPage(
            phoneNumber: extra as String? ?? '',
            nextRoute: LoginPage.id,
          );
        },
      ),
      GoRoute(
        path: DocumentUploadPage.id,
        name: DocumentUploadPage.id,
        builder: (context, state) => const DocumentUploadPage(),
      ),
      GoRoute(
        path: IqamaDetailsPage.id,
        name: IqamaDetailsPage.id,
        builder: (context, state) => const IqamaDetailsPage(),
      ),
      GoRoute(
        path: SelfieDetailsPage.id,
        name: SelfieDetailsPage.id,
        builder: (context, state) => const SelfieDetailsPage(),
      ),
      GoRoute(
        path: LicenseDetailsPage.id,
        name: LicenseDetailsPage.id,
        builder: (context, state) => const LicenseDetailsPage(),
      ),
      GoRoute(
        path: VehicleRegistrationDetailsPage.id,
        name: VehicleRegistrationDetailsPage.id,
        builder: (context, state) => const VehicleRegistrationDetailsPage(),
      ),
      GoRoute(
        path: DriverCardDetailsPage.id,
        name: DriverCardDetailsPage.id,
        builder: (context, state) => const DriverCardDetailsPage(),
      ),
      GoRoute(
        path: DocumentsReviewPage.id,
        name: DocumentsReviewPage.id,
        builder: (context, state) => const DocumentsReviewPage(),
      ),
      GoRoute(
        path: AwaitingReviewPage.id,
        name: AwaitingReviewPage.id,
        builder: (context, state) => const AwaitingReviewPage(),
      ),
      GoRoute(
        path: PermissionsPage.id,
        name: PermissionsPage.id,
        builder: (context, state) => const PermissionsPage(),
      ),
      GoRoute(
        path: LocationSetupPage.id,
        name: LocationSetupPage.id,
        builder: (context, state) => const LocationSetupPage(),
      ),
      GoRoute(
        path: HomeShellPage.id,
        name: HomeShellPage.id,
        builder: (context, state) => const HomeShellPage(),
      ),
      GoRoute(
        path: CourierMapStatusScreen.id,
        name: CourierMapStatusScreen.id,
        builder: (context, state) => const CourierMapStatusScreen(),
      ),
      GoRoute(
        path: OrdersPage.id,
        name: OrdersPage.id,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: StatsPage.id,
        name: StatsPage.id,
        builder: (context, state) => const StatsPage(),
      ),
      GoRoute(
        path: ProfilePage.id,
        name: ProfilePage.id,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: SettingsPage.id,
        name: SettingsPage.id,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: MapPage.id,
        name: MapPage.id,
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: IncomingOrderPage.id,
        name: IncomingOrderPage.id,
        builder: (context, state) {
          final order = state.extra as OrderMock;
          return IncomingOrderPage(order: order);
        },
      ),
      GoRoute(
        path: IncomingOrderFullMapPage.id,
        name: IncomingOrderFullMapPage.id,
        builder: (context, state) {
          final order = state.extra as OrderMock;
          return IncomingOrderFullMapPage(order: order);
        },
      ),
      GoRoute(
        path: ActiveTripPage.id,
        name: ActiveTripPage.id,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ActiveTripPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: ActiveTripFullMapPage.id,
        name: ActiveTripFullMapPage.id,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ActiveTripFullMapPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: NotificationsPage.id,
        name: NotificationsPage.id,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
