abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String profileSetup = '/profile/setup';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // Komunitas
  static const String communities = '/communities';
  static const String createCommunity = '$communities/new';
  static String community(String id) => '$communities/$id';
  static String member(String userId) => '/members/$userId';

  // Admin Panel (khusus super admin)
  static const String adminPanel = '/admin';
  static const String adminUsers = '$adminPanel/users';
  static String adminUser(String id) => '$adminUsers/$id';
  static const String adminCommunities = '$adminPanel/communities';
  static String adminCommunity(String id) => '$adminCommunities/$id';

  // Quotes
  static const String quotes = '/quotes';
  static const String createQuote = '/quotes/create';
  static const String editQuote = '/quotes/edit';
}
