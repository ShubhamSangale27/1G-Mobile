abstract final class RoutePaths {
  static const splash = '/splash';
  static const home = '/';
  static const search = '/search';
  static const blog = '/blog';
  static String blogDetail(String slug) => '/blog/$slug';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const agent = '/agent';
  static String agentVisitDetail(int id) => '/agent/visit/$id';
  static const myProperties = '/my-properties';
  static const propertyNew = '/property/new';
  static String propertyDetail(int id) => '/property/$id';
  static String propertyEdit(int id) => '/property/$id/edit';
}
