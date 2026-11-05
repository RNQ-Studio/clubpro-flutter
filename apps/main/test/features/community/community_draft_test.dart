import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_community_repository.dart';

void main() {
  test('draft lengkap lolos semua langkah', () {
    expect(completeDraft().firstInvalidStep, isNull);
  });

  test('draft kosong tertahan di langkah pertama dengan semua galatnya', () {
    const draft = CommunityDraft();

    expect(draft.firstInvalidStep, CommunityFormStep.identity);
    expect(draft.errorsFor(CommunityFormStep.identity).keys,
        containsAll(['logo_asset_id', 'name', 'short_name', 'type']));
    expect(draft.errorsFor(CommunityFormStep.location).keys,
        containsAll(['province_code', 'city_code', 'address']));
    expect(draft.errorsFor(CommunityFormStep.contact).keys,
        containsAll(['contact_name', 'contact_phone']));
    expect(draft.errorsFor(CommunityFormStep.story).keys,
        containsAll(['description', 'photo_asset_ids']));
  });

  test('email kontak opsional, tetapi harus benar bila diisi', () {
    final draft = completeDraft();
    const step = CommunityFormStep.contact;

    expect(draft.errorsFor(step), isEmpty);
    expect(draft.copyWith(contactEmail: 'bukan-email').errorsFor(step).keys,
        ['contact_email']);
    expect(draft.copyWith(contactEmail: 'a@b.co').errorsFor(step), isEmpty);
  });

  test('nomor kontak boleh ditulis bebas, tetapi harus angka', () {
    final draft = completeDraft();
    const step = CommunityFormStep.contact;

    for (final phone in [
      '0812-3456 7890',
      '+62 812 3456 7890',
      '(022) 4231234'
    ]) {
      expect(draft.copyWith(contactPhone: phone).errorsFor(step), isEmpty,
          reason: phone);
    }
    for (final phone in ['abc', '123', '08123456789012345678']) {
      expect(draft.copyWith(contactPhone: phone).errorsFor(step).keys,
          ['contact_phone'],
          reason: phone);
    }
  });

  test('jenis Lainnya wajib menyebut jenisnya', () {
    final draft = completeDraft().copyWith(type: testTypes.last);
    const step = CommunityFormStep.identity;

    expect(draft.errorsFor(step).keys, ['type_other']);
    expect(draft.copyWith(typeOther: 'Burung Kicau').errorsFor(step), isEmpty);
    expect(draft.copyWith(typeOther: 'Burung Kicau').typeLabel, 'Burung Kicau');
  });

  test('panjang isian mengikuti aturan server', () {
    final draft = completeDraft();

    expect(draft.copyWith(name: 'AB').errorsFor(CommunityFormStep.identity),
        containsPair('name', 'Nama komunitas minimal 3 karakter'));
    expect(
        draft.copyWith(address: 'Jl. A').errorsFor(CommunityFormStep.location),
        containsPair('address', 'Alamat lengkap minimal 10 karakter'));
    expect(
        draft
            .copyWith(description: 'Pendek')
            .errorsFor(CommunityFormStep.story),
        containsPair('description', 'Deskripsi minimal 30 karakter'));
  });

  test('spasi saja dianggap kosong', () {
    expect(
      completeDraft()
          .copyWith(name: '    ')
          .errorsFor(CommunityFormStep.identity),
      containsPair('name', 'Nama komunitas wajib diisi'),
    );
  });

  test('mengganti provinsi bisa mengosongkan kota', () {
    final draft =
        completeDraft().copyWith(province: testJatim, clearCity: true);

    expect(draft.city, isNull);
    expect(draft.province, testJatim);
  });

  test('payload memakai kode wilayah dan id aset, nomor hanya angka', () {
    final draft = completeDraft().copyWith(
      logo: testImage().withAssetId('logo-1'),
      photos: [testImage().withAssetId('foto-1')],
    );

    expect(draft.toPayload(), {
      'name': 'Pemanah Nusantara',
      'short_name': 'PN',
      'type': 'panahan',
      'description':
          'Komunitas pecinta panahan tradisional yang rutin berlatih.',
      'address': 'Jl. Merdeka No. 10, Sumur Bandung',
      'province_code': '32',
      'city_code': '32.73',
      'contact_name': 'Rina Ayu',
      'contact_phone': '081234567890',
      'logo_asset_id': 'logo-1',
      'photo_asset_ids': ['foto-1'],
    });
  });

  test('isian dari server menunjuk langkah yang benar', () {
    expect(CommunityDraft.stepOf('name'), CommunityFormStep.identity);
    expect(CommunityDraft.stepOf('logo_asset_id'), CommunityFormStep.identity);
    expect(CommunityDraft.stepOf('city_code'), CommunityFormStep.location);
    expect(CommunityDraft.stepOf('contact_phone'), CommunityFormStep.contact);
    expect(CommunityDraft.stepOf('photo_asset_ids'), CommunityFormStep.story);
  });

  test('status tak dikenal dianggap menunggu, bukan terverifikasi', () {
    expect(CommunityStatus.fromApi('baru'), CommunityStatus.pending);
    expect(CommunityStatus.fromApi(null), CommunityStatus.pending);
    expect(CommunityStatus.fromApi('approved'), CommunityStatus.approved);
  });
}
