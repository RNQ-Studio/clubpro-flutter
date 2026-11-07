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

  /// Langkah sesudah Lengkapi Data Diri: cari atau daftarkan komunitas.
  static const String communityStart = '/start';
  static String community(String id) => '$communities/$id';
  static String member(String userId) => '/members/$userId';

  // Iuran komunitas
  static String communityDues(String id) => '${community(id)}/dues';
  static String communityDuesPay(String id) => '${communityDues(id)}/pay';
  static String communityDuesSettings(String id) =>
      '${communityDues(id)}/settings';
  static String communityDuesPayments(String id) =>
      '${communityDues(id)}/payments';
  static String communityDuesMembers(String id) =>
      '${communityDues(id)}/members';
  static String communityDuesMember(String id, String userId) =>
      '${communityDuesMembers(id)}/$userId';

  // Admin Panel (khusus super admin)
  static const String adminPanel = '/admin';
  static const String adminUsers = '$adminPanel/users';
  static String adminUser(String id) => '$adminUsers/$id';
  static const String adminCommunities = '$adminPanel/communities';
  static String adminCommunity(String id) => '$adminCommunities/$id';
  static const String adminBanners = '$adminPanel/banners';
  static const String adminBannerNew = '$adminBanners/new';
  static String adminBanner(String id) => '$adminBanners/$id';

  // Quotes
  static const String quotes = '/quotes';
  static const String createQuote = '/quotes/create';
  static const String editQuote = '/quotes/edit';
}
