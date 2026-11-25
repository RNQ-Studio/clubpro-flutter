import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/directory_repository.dart';
import '../data/directory_repository_impl.dart';
part 'directory_providers.g.dart';

@riverpod
DirectoryRepository directoryRepository(Ref ref) =>
    DirectoryRepositoryImpl(ref.watch(apiClientProvider).dio);
@Riverpod(retry: _noRetry)
Future<DirectoryPage> directoryResults(Ref ref,
        {bool members = false,
        String search = '',
        String? communityId,
        String? role,
        int page = 1}) =>
    ref.watch(directoryRepositoryProvider).search(
        members: members,
        search: search,
        communityId: communityId,
        role: role,
        page: page);
Duration? _noRetry(int retryCount, Object error) => null;
@Riverpod(retry: _noRetry)
Future<DirectoryItem> publicCommunity(Ref ref, String id) =>
    ref.watch(directoryRepositoryProvider).community(id);
@Riverpod(retry: _noRetry)
Future<List<Map<String, dynamic>>> guardianInvitations(Ref ref) =>
    ref.watch(directoryRepositoryProvider).invitations();
@Riverpod(retry: _noRetry)
Future<List<Map<String, dynamic>>> guardianDependents(Ref ref) =>
    ref.watch(directoryRepositoryProvider).dependents();
@Riverpod(retry: _noRetry)
Future<Map<String, dynamic>> dependentDetail(Ref ref, String id) =>
    ref.watch(directoryRepositoryProvider).dependent(id);

@Riverpod(retry: _noRetry)
Future<List<Map<String, dynamic>>> internalMemberResults(
        Ref ref, String communityId,
        {String search = '',
        String? role,
        String status = 'active',
        int page = 1}) =>
    ref.watch(directoryRepositoryProvider).internalMembers(communityId,
        search: search, role: role, status: status, page: page);
