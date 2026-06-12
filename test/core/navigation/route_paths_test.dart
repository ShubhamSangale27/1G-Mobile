import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/config/route_paths.dart';

void main() {
  group('RoutePaths — all navigable routes', () {
    test('auth routes', () {
      expect(RoutePaths.login, '/login');
      expect(RoutePaths.signup, '/signup');
      expect(RoutePaths.forgotPassword, '/forgot-password');
      expect(RoutePaths.verifyOtp, '/verify-otp');
    });

    test('shell routes', () {
      expect(RoutePaths.home, '/');
      expect(RoutePaths.search, '/search');
      expect(RoutePaths.blog, '/blog');
      expect(RoutePaths.favorites, '/favorites');
      expect(RoutePaths.profile, '/profile');
      expect(RoutePaths.agent, '/agent');
    });

    test('detail routes', () {
      expect(RoutePaths.propertyDetail(42), '/property/42');
      expect(RoutePaths.propertyEdit(42), '/property/42/edit');
      expect(RoutePaths.blogDetail('my-post'), '/blog/my-post');
      expect(RoutePaths.agentVisitDetail(7), '/agent/visit/7');
    });

    test('user routes', () {
      expect(RoutePaths.dashboard, '/dashboard');
      expect(RoutePaths.myProperties, '/my-properties');
      expect(RoutePaths.propertyNew, '/property/new');
    });
  });
}
