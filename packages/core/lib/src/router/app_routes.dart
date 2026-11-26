abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String authCheck = '/auth/check';
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

  // Saldo, penerimaan manual, dan siklus keanggotaan
  static const String wallet = '/wallet';
  static const String primaryBank = '/wallet/bank-account';
  static const String payouts = '/wallet/payouts';
  static const String newPayout = '/wallet/payouts/new';
  static String payoutProof(String id, String partId) =>
      '$payouts/$id/parts/$partId/proof';
  static String payoutFragment(String id, String partId, String fragmentId) =>
      '$payouts/$id/parts/$partId/fragments/$fragmentId';
  static String payout(String id) => '$payouts/$id';
  static const String transfers = '/wallet/transfers';
  static const String newTransfer = '/wallet/transfers/new';
  static const String billingNotices = '/billing-notices';
  static const String topup = '/wallet/topup';
  static const String paymentReceipts = '/wallet/receipts';
  static String walletTransaction(String id) => '$wallet/transactions/$id';
  static String communityBilling(String id) => '${community(id)}/billing';
  static String communityBillingSettings(String id) =>
      '${communityBilling(id)}/settings';
  static String communityLifecycle(String id) =>
      '${communityBilling(id)}/inactive';

  // Paket, latihan, dan pembagian nominal
  static String communityTraining(String id) => '${community(id)}/training';
  static String trainingSettings(String id) =>
      '${communityTraining(id)}/settings';
  static String trainingNewLocation(String id) =>
      '${communityTraining(id)}/locations/new';
  static String trainingLocation(String id, String locationId) =>
      '${communityTraining(id)}/locations/$locationId';
  static String trainingNewSession(String id) =>
      '${communityTraining(id)}/sessions/new';
  static String trainingReport(String id) => '${communityTraining(id)}/report';

  // Iuran komunitas
  static String communityCard(String id) => '${community(id)}/card';
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

  // Marketplace
  static const String marketProducts = '/explore/products';
  static String marketProduct(String id) => '$marketProducts/$id';
  static String marketSeller(String id) => '/explore/sellers/$id';
  static String marketCatalogue({String? communityId, String? sellerId}) =>
      sellerId != null
          ? marketSeller(sellerId)
          : Uri(path: marketProducts, queryParameters: {
              if (communityId != null) 'community': communityId
            }).toString();
  static const String myMarketProducts = '/marketplace/my-products';
  static const String newMarketProduct = '$myMarketProducts/new';
  static String editMarketProduct(String id) => '$myMarketProducts/$id/edit';
  static String marketCheckout(String id) => '/marketplace/checkout/$id';
  static const String marketOrders = '/marketplace/orders';
  static String marketOrder(String id) => '$marketOrders/$id';

  // Quotes
  static const String quotes = '/quotes';
  static const String createQuote = '/quotes/create';
  static const String editQuote = '/quotes/edit';
}
