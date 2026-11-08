import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:app_main/features/admin/domain/entities/admin_user.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
String _fixture(String name) =>
    File('test/features/admin/fixtures/$name.json').readAsStringSync();

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

({AdminRemoteDataSource source, _FakeAdapter adapter}) _source(
  int status,
  String body,
) {
  final adapter = _FakeAdapter(status, body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: AdminRemoteDataSource(dio), adapter: adapter);
}

void main() {
  group('kontrak dengan respons server sungguhan', () {
    test('daftar pengguna', () async {
      final page = await _source(200, _fixture('admin_users_list'))
          .source
          .fetchUsers(page: 1);

      expect(page.users, hasLength(2));
      expect(page.summary.total, greaterThanOrEqualTo(2));
      expect(page.summary.superAdmins, greaterThanOrEqualTo(1));
      expect(page.currentPage, 1);

      final user = page.users.first;
      expect(user.id, isNotEmpty);
      expect(user.name, 'Rina Ayu');
      expect(user.email, 'rina.ayu@gmail.com');
      expect(user.isSuperAdmin, isTrue);
      expect(user.roles, contains(User.superAdminRole));
      expect(user.isActive, isTrue);
      expect(user.lastSeenAt, isNotNull);
      expect(user.lastLoginAt, isNotNull);

      final device = user.latestDevice!;
      expect(device.deviceType, 'mobile');
      expect(device.label, 'Chrome 120 · Android 13 · SM-S918B');
      expect(device.location, 'Bekasi, West Java, Indonesia');
      expect(device.ipAddress, '180.244.128.1');
    });

    test('detail pengguna', () async {
      final user = await _source(200, _fixture('admin_user_detail'))
          .source
          .fetchUser('2');

      expect(user.email, 'rina.ayu@gmail.com');
      expect(user.usesGoogle, isFalse);
      expect(user.emailVerifiedAt, isNotNull);
      expect(user.phoneVerifiedAt, isNull);
      expect(user.gender, MemberGender.female);
      expect(user.domicile?.label, 'Kota Bandung, Jawa Barat');
      expect(user.nikRegion?.cityCode, '32.73');
      expect(user.nikSameAsDomicile, isTrue);
      expect(user.completion?.total, 5);
      expect(user.completion?.missing.single.key, 'phone');
      expect(user.devices, hasLength(1));
      expect(user.devices.first.userAgent, contains('Android 13'));
    });
  });

  test('pencarian dan saringan menjadi parameter server', () async {
    final body = _fixture('admin_users_list');

    final superAdmin = _source(200, body);
    await superAdmin.source.fetchUsers(
      page: 2,
      search: 'rina',
      filter: AdminUserFilter.superAdmin,
    );
    expect(superAdmin.adapter.request!.path, 'v1/admin/users');
    expect(superAdmin.adapter.request!.queryParameters, {
      'page': 2,
      'search': 'rina',
      'role': 'super-admin',
    });

    final inactive = _source(200, body);
    await inactive.source.fetchUsers(
      page: 1,
      filter: AdminUserFilter.inactive,
    );
    expect(inactive.adapter.request!.queryParameters, {
      'page': 1,
      'status': 'inactive',
    });
  });

  test('aksi mengirim isian yang diharapkan server', () async {
    final body = _fixture('admin_user_detail');

    final grant = _source(200, body);
    await grant.source.setSuperAdmin('2', enabled: true);
    expect(grant.adapter.request!.method, 'PUT');
    expect(grant.adapter.request!.path, 'v1/admin/users/2/super-admin');
    expect(grant.adapter.request!.data, {'enabled': true});

    final status = _source(200, body);
    await status.source.setActive('2', active: false);
    expect(status.adapter.request!.path, 'v1/admin/users/2/status');
    expect(status.adapter.request!.data, {'is_active': false});
  });

  group('pesan galat berbahasa Indonesia', () {
    Future<Object?> failure(int status, [String body = '{}']) async {
      try {
        await _source(status, body).source.fetchUsers(page: 1);
      } catch (e) {
        return e;
      }
      return null;
    }

    test('403', () async {
      expect((await failure(403)).toString(),
          'Anda tidak memiliki akses ke Admin Panel.');
    });

    test('404 pada daftar = server belum memuat fitur ini', () async {
      expect((await failure(404)).toString(),
          'Admin Panel belum aktif di server.');
    });

    test('404 pada detail = pengguna tidak ada', () async {
      await expectLater(
        _source(404, '{}').source.fetchUser('9'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'Pengguna tidak ditemukan.')),
      );
    });

    test('422 meneruskan pesan validasi server', () async {
      await expectLater(
        _source(
          422,
          jsonEncode({
            'errors': {
              'super_admin': ['Aktifkan akun ini terlebih dahulu.'],
            },
          }),
        ).source.setSuperAdmin('9', enabled: true),
        throwsA(isA<ServerException>().having(
            (e) => e.message, 'message', 'Aktifkan akun ini terlebih dahulu.')),
      );
    });

    test('500 tidak membocorkan pesan teknis', () async {
      expect((await failure(500)).toString(),
          'Terjadi kesalahan pada server. Coba lagi.');
    });
  });
}
