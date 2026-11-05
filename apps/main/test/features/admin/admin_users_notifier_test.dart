import 'dart:async';

import 'package:app_main/features/admin/domain/entities/admin_user.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_admin_repository.dart';

ProviderContainer _container(FakeAdminRepository repository) {
  final container = ProviderContainer(overrides: [
    adminRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);
  // Provider auto-dispose: tetap hidup selama test.
  container.listen(adminUsersProvider, (_, __) {});
  return container;
}

List<String> _ids(ProviderContainer container) => [
      for (final user in container.read(adminUsersProvider).requireValue.users)
        user.id,
    ];

void main() {
  test('memuat halaman pertama', () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1'), adminUser('2')],
      [adminUser('3')],
    ]);
    final container = _container(repository);

    final state = await container.read(adminUsersProvider.future);

    expect(state.users, hasLength(2));
    expect(state.hasMore, isTrue);
    expect(state.summary.total, adminSummary.total);
  });

  test('muat berikutnya menambah baris sampai habis', () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
      [adminUser('2')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);

    await container.read(adminUsersProvider.notifier).loadMore();

    expect(_ids(container), ['1', '2']);
    expect(container.read(adminUsersProvider).requireValue.hasMore, isFalse);

    await container.read(adminUsersProvider.notifier).loadMore();
    expect(repository.calls, hasLength(2));
  });

  test('baris yang bergeser antarhalaman tidak tampil dua kali', () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1'), adminUser('2')],
      [adminUser('2'), adminUser('3')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);

    await container.read(adminUsersProvider.notifier).loadMore();

    expect(_ids(container), ['1', '2', '3']);
  });

  test('muat berikutnya tidak berjalan ganda', () async {
    final release = Completer<void>();
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
      [adminUser('2')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);
    repository.gate = (_) => release;

    final notifier = container.read(adminUsersProvider.notifier);
    final first = notifier.loadMore();
    await notifier.loadMore();
    release.complete();
    await first;

    expect(repository.calls.where((call) => call.page == 2), hasLength(1));
  });

  test('gagal muat berikutnya mempertahankan baris yang sudah tampil',
      () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
      [adminUser('2')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);

    repository.error = const ServerException('Gagal memuat');
    await container.read(adminUsersProvider.notifier).loadMore();

    final state = container.read(adminUsersProvider).requireValue;
    expect(_ids(container), ['1']);
    expect(state.loadMoreError, 'Gagal memuat');
    expect(state.hasMore, isTrue);

    repository.error = null;
    await container.read(adminUsersProvider.notifier).loadMore();
    expect(_ids(container), ['1', '2']);
    expect(
      container.read(adminUsersProvider).requireValue.loadMoreError,
      isNull,
    );
  });

  test('hasil pencarian lama yang datang belakangan diabaikan', () async {
    final slow = Completer<void>();
    final fast = Completer<void>();
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);
    repository.gate = (call) => call.search == 'ri' ? slow : fast;

    final notifier = container.read(adminUsersProvider.notifier);
    final lama = notifier.search('ri');
    final baru = notifier.search('rina');

    repository.pages = [
      [adminUser('baru')],
    ];
    fast.complete();
    await baru;

    repository.pages = [
      [adminUser('lama')],
    ];
    slow.complete();
    await lama;

    expect(_ids(container), ['baru']);
  });

  test('saringan dan pencarian ikut terkirim saat mengulang', () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);
    final notifier = container.read(adminUsersProvider.notifier);

    await notifier.setFilter(AdminUserFilter.superAdmin);
    await notifier.search('  rina ');
    await notifier.retry();

    expect(repository.calls.last, (
      page: 1,
      search: 'rina',
      filter: AdminUserFilter.superAdmin,
    ));
  });

  test('pencarian yang sama tidak memanggil server lagi', () async {
    final repository = FakeAdminRepository(pages: [
      [adminUser('1')],
    ]);
    final container = _container(repository);
    await container.read(adminUsersProvider.future);
    final notifier = container.read(adminUsersProvider.notifier);

    await notifier.search('rina');
    await notifier.search('rina ');

    expect(repository.calls, hasLength(2));
  });

  group('hasil aksi di layar detail', () {
    test('baris dan ringkasan ikut berubah', () async {
      final repository = FakeAdminRepository(pages: [
        [adminUser('1'), adminUser('2')],
      ]);
      final container = _container(repository);
      await container.read(adminUsersProvider.future);

      container
          .read(adminUsersProvider.notifier)
          .applyUpdate(adminUser('2', isSuperAdmin: true, isActive: false));

      final state = container.read(adminUsersProvider).requireValue;
      expect(state.users.last.isSuperAdmin, isTrue);
      expect(state.summary.superAdmins, adminSummary.superAdmins + 1);
      expect(state.summary.inactive, adminSummary.inactive + 1);
    });

    test('baris yang tidak lagi cocok saringan keluar dari daftar', () async {
      final repository = FakeAdminRepository(pages: [
        [
          adminUser('1', isSuperAdmin: true),
          adminUser('2', isSuperAdmin: true)
        ],
      ]);
      final container = _container(repository);
      await container.read(adminUsersProvider.future);
      final notifier = container.read(adminUsersProvider.notifier);
      await notifier.setFilter(AdminUserFilter.superAdmin);

      notifier.applyUpdate(adminUser('2'));

      expect(_ids(container), ['1']);
    });

    test('detail memperbarui daftar yang terbuka', () async {
      final repository = FakeAdminRepository(
        pages: [
          [adminUser('7')],
        ],
        detail: adminDetail(),
      );
      final container = _container(repository);
      await container.read(adminUsersProvider.future);
      final provider = adminUserDetailProvider('7');
      container.listen(provider, (_, __) {});
      await container.read(provider.future);

      await container.read(provider.notifier).setSuperAdmin(enabled: true);

      expect(
        container
            .read(adminUsersProvider)
            .requireValue
            .users
            .single
            .isSuperAdmin,
        isTrue,
      );
    });

    test('aksi gagal meneruskan galat dan data tetap utuh', () async {
      final repository = FakeAdminRepository(
        detail: adminDetail(),
        actionError: const ServerException('Ditolak server'),
      );
      final container = _container(repository);
      final provider = adminUserDetailProvider('7');
      container.listen(provider, (_, __) {});
      await container.read(provider.future);

      await expectLater(
        container.read(provider.notifier).setSuperAdmin(enabled: true),
        throwsA(isA<ServerException>()),
      );

      expect(container.read(provider).requireValue.isSuperAdmin, isFalse);
    });
  });
}
