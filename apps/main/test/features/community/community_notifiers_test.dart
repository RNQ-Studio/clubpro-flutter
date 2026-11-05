import 'dart:async';

import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:app_main/features/community/domain/repositories/community_repository.dart';
import 'package:app_main/features/community/presentation/community_form_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_community_repository.dart';

ProviderContainer _container(
  CommunityRepository repository, {
  FakeCommunityImagePicker? picker,
}) {
  final container = ProviderContainer(overrides: [
    communityRepositoryProvider.overrideWithValue(repository),
    communityImagePickerProvider
        .overrideWithValue(picker ?? FakeCommunityImagePicker()),
  ]);
  addTearDown(container.dispose);
  // Provider auto-dispose: tetap hidup selama test.
  container.listen(communitiesProvider, (_, __) {});
  container.listen(communityFormProvider, (_, __) {});
  return container;
}

void main() {
  group('daftar komunitas', () {
    List<String> ids(ProviderContainer container) => [
          for (final community
              in container.read(communitiesProvider).requireValue.communities)
            community.id,
        ];

    test('muat berikutnya menambah baris tanpa duplikat sampai habis',
        () async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1'), testCommunity('2')],
        [testCommunity('2'), testCommunity('3')],
      ]);
      final container = _container(repository);
      await container.read(communitiesProvider.future);

      await container.read(communitiesProvider.notifier).loadMore();

      expect(ids(container), ['1', '2', '3']);
      expect(container.read(communitiesProvider).requireValue.hasMore, isFalse);
    });

    test('gagal muat berikutnya mempertahankan baris yang sudah tampil',
        () async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1')],
        [testCommunity('2')],
      ]);
      final container = _container(repository);
      await container.read(communitiesProvider.future);

      repository.error = const ServerException('Gagal memuat');
      await container.read(communitiesProvider.notifier).loadMore();

      expect(ids(container), ['1']);
      expect(container.read(communitiesProvider).requireValue.loadMoreError,
          'Gagal memuat');
    });

    test('saringan dan pencarian ikut terkirim saat mengulang', () async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1')],
      ]);
      final container = _container(repository);
      await container.read(communitiesProvider.future);
      final notifier = container.read(communitiesProvider.notifier);

      await notifier.setType('fashion');
      await notifier.search('  bandung ');
      await notifier.retry();

      expect(repository.listCalls.last,
          (page: 1, search: 'bandung', type: 'fashion'));
    });
  });

  group('langkah form', () {
    test(
        'tidak bisa lanjut sebelum isian benar, galat baru tampil sesudah '
        'dicoba', () {
      final container = _container(FakeCommunityRepository());
      final notifier = container.read(communityFormProvider.notifier);

      expect(container.read(communityFormProvider).errorOf('name'), isNull);

      expect(notifier.next(), isFalse);

      final state = container.read(communityFormProvider);
      expect(state.step, CommunityFormStep.identity);
      expect(state.errorOf('name'), 'Nama komunitas wajib diisi');
    });

    test('isian benar berpindah langkah, kembali mempertahankan isian', () {
      final container = _container(FakeCommunityRepository());
      final notifier = container.read(communityFormProvider.notifier);
      notifier.edit((_) => completeDraft());

      expect(notifier.next(), isTrue);
      expect(container.read(communityFormProvider).step,
          CommunityFormStep.location);

      notifier.back();

      final state = container.read(communityFormProvider);
      expect(state.step, CommunityFormStep.identity);
      expect(state.draft.name, 'Pemanah Nusantara');
    });

    test('mengganti provinsi mengosongkan kota, memilih ulang yang sama tidak',
        () {
      final container = _container(FakeCommunityRepository());
      final notifier = container.read(communityFormProvider.notifier);
      notifier.edit((_) => completeDraft());

      notifier.setProvince(testJabar);
      expect(container.read(communityFormProvider).draft.city, testBandung);

      notifier.setProvince(testJatim);
      expect(container.read(communityFormProvider).draft.city, isNull);
    });

    test('foto tidak melebihi batas: pemilih hanya diberi sisa ruang',
        () async {
      final picker = FakeCommunityImagePicker();
      final container = _container(FakeCommunityRepository(), picker: picker);
      final notifier = container.read(communityFormProvider.notifier);
      notifier.edit((d) => d.copyWith(
            photos: [for (var i = 0; i < 5; i++) testImage('$i.png')],
          ));

      await notifier.addPhotos();
      expect(picker.limits, [1]);
      expect(container.read(communityFormProvider).draft.photos, hasLength(6));

      await notifier.addPhotos();
      expect(picker.limits, [1]);
    });

    test('foto bisa dihapus', () {
      final container = _container(FakeCommunityRepository());
      final notifier = container.read(communityFormProvider.notifier);
      notifier.edit((_) => completeDraft());

      notifier.removePhoto(0);

      expect(
        container.read(communityFormProvider).draft.photos.single.filename,
        'b.png',
      );
    });

    test('foto yang ditolak pemilih tampil sebagai pesan', () async {
      final picker = FakeCommunityImagePicker(
        error: const CommunityImageException('Ukuran foto maksimal 5 MB.'),
      );
      final container = _container(FakeCommunityRepository(), picker: picker);

      await container.read(communityFormProvider.notifier).pickLogo();

      expect(container.read(communityFormProvider).error,
          'Ukuran foto maksimal 5 MB.');
    });
  });

  group('kirim', () {
    ProviderContainer ready(FakeCommunityRepository repository) {
      final container = _container(repository);
      container
          .read(communityFormProvider.notifier)
          .edit((_) => completeDraft());
      return container;
    }

    test('mengunggah semua foto lalu mengirim id-nya', () async {
      final repository = FakeCommunityRepository();
      final container = ready(repository);

      await container.read(communityFormProvider.notifier).submit();

      final state = container.read(communityFormProvider);
      expect(state.phase, CommunitySubmitPhase.done);
      expect(state.result?.status, CommunityStatus.pending);
      expect(repository.uploads, [
        'community-logo:logo.png',
        'community-photo:a.png',
        'community-photo:b.png',
      ]);
      final sent = repository.submitted.single.toPayload();
      expect(sent['logo_asset_id'], 'aset-logo.png');
      expect(sent['photo_asset_ids'], ['aset-a.png', 'aset-b.png']);
    });

    test('isian belum benar: tidak ada yang diunggah, kembali ke langkahnya',
        () async {
      final repository = FakeCommunityRepository();
      final container = ready(repository);
      final notifier = container.read(communityFormProvider.notifier);
      notifier.edit((d) => d.copyWith(contactPhone: 'abc'));
      notifier.goTo(CommunityFormStep.review);

      await notifier.submit();

      final state = container.read(communityFormProvider);
      expect(state.step, CommunityFormStep.contact);
      expect(state.errorOf('contact_phone'), 'Nomor kontak tidak valid');
      expect(repository.uploads, isEmpty);
    });

    test('unggahan gagal di tengah: kirim ulang hanya melanjutkan sisanya',
        () async {
      final repository = FakeCommunityRepository()
        ..failUploadOf = 'b.png'
        ..uploadError = const NetworkException('Koneksi terputus');
      final container = ready(repository);
      final notifier = container.read(communityFormProvider.notifier);

      await notifier.submit();

      var state = container.read(communityFormProvider);
      expect(state.phase, CommunitySubmitPhase.idle);
      expect(state.error, 'Koneksi terputus');
      expect(repository.submitted, isEmpty);
      expect(repository.uploads, hasLength(2));

      await notifier.submit();

      state = container.read(communityFormProvider);
      expect(state.phase, CommunitySubmitPhase.done);
      expect(repository.uploads, [
        'community-logo:logo.png',
        'community-photo:a.png',
        'community-photo:b.png',
      ]);
    });

    test('server menolak isian: langkahnya terbuka dan galatnya tampil',
        () async {
      final repository = FakeCommunityRepository()
        ..submitError = const CommunityFieldException(
            'name', 'Komunitas ini sudah Anda ajukan.');
      final container = ready(repository);
      final notifier = container.read(communityFormProvider.notifier);

      await notifier.submit();

      final state = container.read(communityFormProvider);
      expect(state.phase, CommunitySubmitPhase.idle);
      expect(state.step, CommunityFormStep.identity);
      expect(state.errorOf('name'), 'Komunitas ini sudah Anda ajukan.');

      notifier.edit((d) => d.copyWith(name: 'Nama Baru'), fields: ['name']);
      expect(container.read(communityFormProvider).errorOf('name'), isNull);
    });

    test('foto ditolak server diunggah ulang pada kiriman berikutnya',
        () async {
      final repository = FakeCommunityRepository()
        ..submitError = const CommunityFieldException(
            'photo_asset_ids', 'Foto ini sudah dipakai komunitas lain.');
      final container = ready(repository);
      final notifier = container.read(communityFormProvider.notifier);

      await notifier.submit();
      expect(
          container.read(communityFormProvider).step, CommunityFormStep.story);

      await notifier.submit();

      expect(
          repository.uploads.where((u) => u.contains('a.png')), hasLength(2));
      expect(repository.uploads.where((u) => u.contains('logo')), hasLength(1));
    });

    test('kirim ganda hanya mengirim sekali', () async {
      final repository = FakeCommunityRepository();
      final container = ready(repository);
      final notifier = container.read(communityFormProvider.notifier);

      await Future.wait([notifier.submit(), notifier.submit()]);
      await notifier.submit();

      expect(repository.submitted, hasLength(1));
    });

    test('sukses menyegarkan Pengajuan Saya', () async {
      final repository = FakeCommunityRepository();
      final container = ready(repository);
      container.listen(myCommunitiesProvider, (_, __) {});
      expect(await container.read(myCommunitiesProvider.future), isEmpty);

      repository.mine = [
        testCommunity('1', status: CommunityStatus.pending),
      ];
      await container.read(communityFormProvider.notifier).submit();

      expect(await container.read(myCommunitiesProvider.future), hasLength(1));
    });
  });
}
