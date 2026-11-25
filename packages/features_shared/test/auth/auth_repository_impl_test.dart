import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

void main() {
  const cached = UserModel(id: '1', name: 'Rina', email: 'rina@gmail.com');

  setUpAll(() => registerFallbackValue(cached));

  test('gagal menyimpan data terbaru tetap memakai sesi tersimpan', () async {
    final remote = _MockRemote();
    final local = _MockLocal();
    when(local.getUser).thenAnswer((_) async => cached);
    when(remote.getMe).thenAnswer((_) async => cached);
    when(() => local.saveUser(any())).thenThrow(Exception('penyimpanan penuh'));

    final repository = AuthRepositoryImpl(remote: remote, local: local);

    expect(await repository.getCurrentUser(), same(cached));
  });
  test('rejected identity session never falls back to cached profile',
      () async {
    final remote = _MockRemote(), local = _MockLocal();
    when(local.getUser).thenAnswer((_) async => cached);
    when(remote.getMe).thenThrow(const UnauthorizedException());
    when(local.clearUser).thenAnswer((_) async {});
    final repository = AuthRepositoryImpl(remote: remote, local: local);
    expect(await repository.getCurrentUser(), null);
    verify(local.clearUser).called(1);
    verifyNever(() => local.saveUser(any()));
  });
  test('offline profile read retains existing cached session', () async {
    final remote = _MockRemote(), local = _MockLocal();
    when(local.getUser).thenAnswer((_) async => cached);
    when(remote.getMe).thenThrow(const NetworkException('Offline'));
    final repository = AuthRepositoryImpl(remote: remote, local: local);
    expect(await repository.getCurrentUser(), same(cached));
    verifyNever(local.clearUser);
  });
}
