import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
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
import '../../features/onboarding/presentation/pages/sign_up_page.dart';
import '../../features/onboarding/presentation/pages/otp_verification_page.dart';
import '../../features/onboarding/presentation/pages/document_upload_page.dart';
import '../../features/onboarding/presentation/pages/awaiting_review_page.dart';
import '../../features/incoming/presentation/pages/incoming_order_full_map_page.dart';
import '../../features/incoming/presentation/pages/incoming_order_page.dart';
import '../../features/trip/presentation/pages/active_trip_page.dart';
import '../../features/trip/presentation/pages/active_trip_full_map_page.dart';
import '../../core/orders/mock_order_matcher.dart';
import '../../features/orders/domain/models/order_mock.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: OnboardingState.instance,
    redirect: (context, state) async {
      await OnboardingState.instance.ensureLoaded();

      final s = OnboardingState.instance;
      final loc = state.matchedLocation;

      // Legacy route: keep working but route into onboarding.
      if (loc == '/permission') {
        return '/permissions';
      }

      // Allow access to login and signup flows when not logged in
      if (!s.isLoggedIn) {
        if (loc == '/login' ||
            loc == '/signup' ||
            loc.startsWith('/signup/otp') ||
            loc.startsWith('/signup/documents') ||
            loc.startsWith('/signup/awaiting-review')) {
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
          loc == '/signup' ||
          loc == '/signup/documents' ||
          loc == '/signup/awaiting-review' ||
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
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
        routes: [
          GoRoute(
            path: 'otp',
            name: 'signupOtp',
            builder: (context, state) {
              final phoneNumber = state.extra as String? ?? '';
              return OtpVerificationPage(phoneNumber: phoneNumber);
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
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsPage(),
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
          return CourierMapStatusScreen(autoSearch: autoSearch);
        },
      ),
      GoRoute(
        path: '/active-trip/:id',
        name: 'activeTrip',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ActiveTripPage(orderId: id);
        },
        routes: [
          GoRoute(
            path: 'map',
            name: 'activeTripFullMap',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ActiveTripFullMapPage(orderId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/incoming-order',
        name: 'incomingOrder',
        builder: (context, state) {
          final order = state.extra as OrderMock?;
          return IncomingOrderPage(
            order: order ?? MockOrderMatcher.fallbackOrder,
          );
        },
        routes: [
          GoRoute(
            path: 'map',
            name: 'incomingOrderFullMap',
            builder: (context, state) {
              final order = state.extra as OrderMock?;
              return IncomingOrderFullMapPage(
                order: order ?? MockOrderMatcher.fallbackOrder,
              );
            },
          ),
        ],
      ),
    ],
  );
}
