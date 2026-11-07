import 'package:app_main/features/community/data/stores/prefs_active_community_store.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_community_repository.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _signedIn(String id) =>
    AuthAuthenticated(User(id: id, name: 'Rina Ayu', email: 'rina@gmail.com'));

ProviderContainer _container(
  FakeCommunityRepository repository, {
  FakeActiveCommunityStore? store,
  AuthState? auth,
}) {
  final container = ProviderContainer(overrides: [
    communityRepositoryProvider.overrideWithValue(repository),
    activeCommunityStoreProvider
        .overrideWithValue(store ?? FakeActiveCommunityStore()),
    authProvider
        .overrideWith(() => _FixedAuthNotifier(auth ?? _signedIn('u1'))),
  ]);
  addTearDown(container.dispose);
  return container;
}

final _three = [
  testCommunity('1', name: 'Pemanah Nusantara', myRole: CommunityRole.creator),
  testCommunity('2', name: 'Futsal Bandung', myRole: CommunityRole.admin),
  testCommunity('3', name: 'Gowes Bogor', myRole: CommunityRole.member),
];

void main() {
  group('komunitas aktif', () {
    test('memuat komunitas saya beserta permintaan yang menunggu', () async {
      final repository = FakeCommunityRepository(joined: _three);
      await _container(repository).read(activeCommunityProvider.future);

      expect(repository.joinedIncludePending, isTrue);
    });

    test('satu komunitas: langsung aktif tanpa memilih', () async {
      final mine = await _container(FakeCommunityRepository(
        joined: [testCommunity('7', myRole: CommunityRole.member)],
      )).read(activeCommunityProvider.future);

      expect(mine.active?.id, '7');
      expect(mine.needsChoice, isFalse);
    });

    test('beberapa komunitas tanpa pilihan tersimpan: harus memilih', () async {
      final mine = await _container(FakeCommunityRepository(joined: _three))
          .read(activeCommunityProvider.future);

      expect(mine.active, isNull);
      expect(mine.needsChoice, isTrue);
      expect(mine.joined.map((c) => c.id), ['1', '2', '3']);
    });

    test('pilihan terakhir dipakai lagi', () async {
      final mine = await _container(
        FakeCommunityRepository(joined: _three),
        store: FakeActiveCommunityStore({'u1': '2'}),
      ).read(activeCommunityProvider.future);

      expect(mine.active?.id, '2');
      expect(mine.needsChoice, isFalse);
    });

    test('pilihan tersimpan milik akun lain tidak berlaku', () async {
      final mine = await _container(
        FakeCommunityRepository(joined: _three),
        store: FakeActiveCommunityStore({'u9': '2'}),
      ).read(activeCommunityProvider.future);

      expect(mine.needsChoice, isTrue);
    });

    test('komunitas tersimpan yang tidak lagi diikuti: memilih ulang',
        () async {
      final mine = await _container(
        FakeCommunityRepository(joined: _three),
        store: FakeActiveCommunityStore({'u1': '99'}),
      ).read(activeCommunityProvider.future);

      expect(mine.needsChoice, isTrue);
    });

    test('memilih: langsung aktif dan diingat per akun', () async {
      final store = FakeActiveCommunityStore();
      final container =
          _container(FakeCommunityRepository(joined: _three), store: store);
      await container.read(activeCommunityProvider.future);

      await container.read(activeCommunityProvider.notifier).choose('3');

      expect(container.read(activeCommunityProvider).value?.active?.id, '3');
      expect(store.saved, {'u1': '3'});
    });

    test('memilih komunitas yang tidak diikuti diabaikan', () async {
      final store = FakeActiveCommunityStore();
      final container =
          _container(FakeCommunityRepository(joined: _three), store: store);
      await container.read(activeCommunityProvider.future);

      await container.read(activeCommunityProvider.notifier).choose('99');

      expect(container.read(activeCommunityProvider).value?.active, isNull);
      expect(store.saved, isEmpty);
    });

    test('penyimpanan tidak tersedia: tetap bisa masuk', () async {
      final store = FakeActiveCommunityStore({'u1': '2'})
        ..readError = Exception('diblokir')
        ..writeError = Exception('diblokir');
      final container =
          _container(FakeCommunityRepository(joined: _three), store: store);

      final mine = await container.read(activeCommunityProvider.future);
      expect(mine.needsChoice, isTrue);

      await container.read(activeCommunityProvider.notifier).choose('1');
      expect(container.read(activeCommunityProvider).value?.active?.id, '1');
    });

    test('permintaan bergabung dipisah dan tidak bisa jadi komunitas aktif',
        () async {
      final mine = await _container(FakeCommunityRepository(joined: [
        testCommunity('1', myRole: CommunityRole.member),
        testCommunity(
          '2',
          myRole: CommunityRole.member,
          myStatus: CommunityMembershipStatus.pending,
        ),
      ])).read(activeCommunityProvider.future);

      expect(mine.joined.map((c) => c.id), ['1']);
      expect(mine.requests.map((c) => c.id), ['2']);
      // Tinggal satu yang aktif → langsung masuk.
      expect(mine.active?.id, '1');
    });

    test('hanya permintaan: belum ada komunitas, tidak perlu memilih',
        () async {
      final mine = await _container(FakeCommunityRepository(joined: [
        testCommunity(
          '2',
          myRole: CommunityRole.member,
          myStatus: CommunityMembershipStatus.pending,
        ),
      ])).read(activeCommunityProvider.future);

      expect(mine.joined, isEmpty);
      expect(mine.requests, hasLength(1));
      expect(mine.active, isNull);
      expect(mine.needsChoice, isFalse);
    });

    test('daftar komunitas disegarkan: pilihan tetap', () async {
      final repository = FakeCommunityRepository(joined: _three);
      final container = _container(repository);
      await container.read(activeCommunityProvider.future);
      await container.read(activeCommunityProvider.notifier).choose('2');

      container.invalidate(joinedCommunitiesProvider);
      final mine = await container.read(activeCommunityProvider.future);

      expect(repository.joinedCalls, 2);
      expect(mine.active?.id, '2');
    });
  });

  test('rekomendasi: terpopuler, lima teratas', () async {
    final repository = FakeCommunityRepository(pages: [
      [testCommunity('5', membersCount: 120), testCommunity('6')],
    ]);
    final items = await _container(repository)
        .read(recommendedCommunitiesProvider.future);

    expect(items.map((c) => c.id), ['5', '6']);
    expect(repository.listCalls.single.sort, CommunitySort.popular);
    expect(repository.listCalls.single.perPage, 5);
  });

  test('penyimpanan perangkat: per akun dan bertahan', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PrefsActiveCommunityStore();
    await store.write('u1', '2');
    await store.write('u2', '5');

    expect(await PrefsActiveCommunityStore().read('u1'), '2');
    expect(await PrefsActiveCommunityStore().read('u2'), '5');
    expect(await PrefsActiveCommunityStore().read('u3'), isNull);
  });
}
