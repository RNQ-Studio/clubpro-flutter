import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'features/achievements/presentation/achievements_providers.dart';
import 'features/admin/presentation/admin_banner_providers.dart';
import 'features/admin/presentation/admin_community_providers.dart';
import 'features/admin/presentation/admin_providers.dart';
import 'features/community/presentation/active_community_notifier.dart';
import 'features/community/presentation/community_providers.dart';
import 'features/directory/presentation/directory_providers.dart';
import 'features/dues/presentation/dues_providers.dart';
import 'features/finance/presentation/finance_providers.dart';
import 'features/marketplace/presentation/marketplace_providers.dart';
import 'features/member_card/presentation/member_card_providers.dart';
import 'features/money_movement/presentation/money_movement_providers.dart';
import 'features/training/presentation/training_providers.dart';

/// A response belongs to the account that requested it. Discard the old state
/// before the router handles a session transition, including in-flight requests.
/// Reload semantics prevent AsyncValue.when from displaying the previous value
/// while a different account's response is pending. Auth/token providers and the
/// per-account active-community preference store remain owned by their services.
void clearAccountData(WidgetRef ref) {
  for (final provider in <ProviderOrFamily>[
    myCommunitiesProvider,
    joinedCommunitiesProvider,
    activeCommunityProvider,
    communityDetailProvider,
    communityActivitiesProvider,
    communityMemberProfileProvider,
    communityMembersProvider,
    guardianInvitationsProvider,
    guardianDependentsProvider,
    dependentDetailProvider,
    internalMemberResultsProvider,
    walletSummaryProvider,
    fundSummaryProvider,
    walletTransactionsProvider,
    walletTransactionProvider,
    paymentReceiptsProvider,
    billingOverviewProvider,
    inactiveSubjectsProvider,
    billingNoticeFeedProvider,
    duesOverviewProvider,
    memberDuesProvider,
    duesPaymentsProvider,
    membersDuesProvider,
    memberCardProvider,
    primaryBankAccountProvider,
    transferRecipientsProvider,
    memberTransfersProvider,
    payoutsProvider,
    payoutDetailProvider,
    payoutReconciliationProvider,
    trainingOverviewProvider,
    trainingReportProvider,
    marketProductsProvider,
    marketProductProvider,
    marketOrdersProvider,
    marketOrderProvider,
    achievementRulesProvider,
    myAchievementsProvider,
    communityAchievementsProvider,
    memberAdsProvider,
    adminSummaryProvider,
    adminUsersProvider,
    adminUserDetailProvider,
    adminCommunitiesProvider,
    adminCommunityDetailProvider,
    adminBannersProvider,
  ]) {
    ref.invalidate(provider, asReload: true);
  }
}
