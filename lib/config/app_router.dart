import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/agent/presentation/screens/agent_visit_detail_screen.dart';
import '../features/agent/presentation/screens/agent_visits_screen.dart';
import '../features/blog/presentation/screens/blog_detail_screen.dart';
import '../features/blog/presentation/screens/blog_list_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../core/auth/mobile_role_policy.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/my_properties/presentation/screens/my_properties_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/property/presentation/screens/property_detail_screen.dart';
import '../features/property_form/presentation/screens/property_form_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../presentation/shell/main_shell.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

bool _requiresAuth(String path) {
  return path.startsWith(RoutePaths.favorites) ||
      path.startsWith(RoutePaths.dashboard) ||
      path.startsWith(RoutePaths.agent) ||
      path.startsWith(RoutePaths.myProperties) ||
      path.startsWith(RoutePaths.propertyNew) ||
      path.contains('/edit') ||
      path.startsWith(RoutePaths.profile);
}

bool _requiresAgent(String path) =>
    path.startsWith(RoutePaths.agent) || path.contains('/agent/visit/');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.matchedLocation;

      if (path == RoutePaths.splash) {
        if (auth.status == AuthStatus.loading) return null;
        return null;
      }

      if (auth.status == AuthStatus.loading) return RoutePaths.splash;

      if (_requiresAuth(path) && !auth.isLoggedIn) {
        return '${RoutePaths.login}?redirect=${Uri.encodeComponent(path)}';
      }

      if (_requiresAgent(path) && auth.isLoggedIn && !MobileRolePolicy.isAgent(auth.user?.role)) {
        return RoutePaths.home;
      }

      if (auth.isLoggedIn &&
          (path == RoutePaths.login || path == RoutePaths.signup)) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.search,
            builder: (_, state) => SearchScreen(
              initialCity: state.uri.queryParameters['city'],
              initialListingType: state.uri.queryParameters['listingType'],
            ),
          ),
          GoRoute(
            path: RoutePaths.blog,
            builder: (_, __) => const BlogListScreen(),
          ),
          GoRoute(
            path: RoutePaths.favorites,
            builder: (_, __) => const FavoritesScreen(),
          ),
          GoRoute(
            path: RoutePaths.agent,
            builder: (_, __) => const AgentVisitsScreen(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyOtp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => OtpVerificationScreen.fromState(state),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.myProperties,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MyPropertiesScreen(),
      ),
      GoRoute(
        path: RoutePaths.propertyNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: '/property/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PropertyFormScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/blog/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final slug = state.pathParameters['slug']!;
          return BlogDetailScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/property/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/agent/visit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AgentVisitDetailScreen(visitId: id);
        },
      ),
    ],
  );
});

/// Rebuilds GoRouter when auth state changes (login/logout/session restore).
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
