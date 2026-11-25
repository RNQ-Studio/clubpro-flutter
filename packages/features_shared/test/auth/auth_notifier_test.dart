import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:features_shared/features_shared.dart';
import 'package:core/core.dart';

import 'mock_auth_repository.dart';

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  const tUser = User(id: '1', name: 'Test', email: 'test@test.com');

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is AuthInitial', () {
    expect(container.read(authProvider), isA<AuthInitial>());
  });

  test('login success → AuthAuthenticated', () async {
    when(() => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => tUser);

    await container
        .read(authProvider.notifier)
        .login(email: 'test@test.com', password: 'password');

    final state = container.read(authProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).user, tUser);
  });

  test('login failure → AuthError with message', () async {
    when(() => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const ServerException('Invalid credentials'));

    await container
        .read(authProvider.notifier)
        .login(email: 'wrong@test.com', password: 'wrongpass');

    final state = container.read(authProvider);
    expect(state, isA<AuthError>());
    expect((state as AuthError).message, 'Invalid credentials');
  });

  test('logout → AuthUnauthenticated', () async {
    when(() => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => tUser);
    when(() => mockRepo.logout()).thenAnswer((_) async {});

    await container
        .read(authProvider.notifier)
        .login(email: 'test@test.com', password: 'password');
    await container.read(authProvider.notifier).logout();

    expect(container.read(authProvider), isA<AuthUnauthenticated>());
  });

  test('checkCurrentUser with cached session → AuthAuthenticated', () async {
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => tUser);

    await container.read(authProvider.notifier).checkCurrentUser();

    final state = container.read(authProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).user, tUser);
  });

  test('checkCurrentUser with no session → AuthUnauthenticated', () async {
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);

    await container.read(authProvider.notifier).checkCurrentUser();

    expect(container.read(authProvider), isA<AuthUnauthenticated>());
  });
  test(
      'expired session is unauthenticated before cleanup and late bootstrap cannot revive it',
      () async {
    final restore = Completer<User?>(), cleanup = Completer<void>();
    when(mockRepo.getCurrentUser).thenAnswer((_) => restore.future);
    when(mockRepo.clearSession).thenAnswer((_) => cleanup.future);
    final auth = container.read(authProvider.notifier);
    final checking = auth.checkCurrentUser();
    expect(container.read(authProvider), isA<AuthLoading>());
    final expiring = auth.sessionExpired();
    expect(container.read(authProvider), isA<AuthUnauthenticated>());
    restore.complete(tUser);
    await checking;
    expect(container.read(authProvider), isA<AuthUnauthenticated>());
    cleanup.complete();
    await expiring;
    expect(container.read(authProvider), isA<AuthUnauthenticated>());
  });
  test('late session restore cannot replace newer authenticated identity',
      () async {
    final restore = Completer<User?>();
    when(mockRepo.getCurrentUser).thenAnswer((_) => restore.future);
    final auth = container.read(authProvider.notifier);
    final checking = auth.checkCurrentUser();
    const fresh =
        User(id: '2', name: 'Baru', email: 'baru@anaklangit.manahpro.web.id');
    auth.acceptAuthenticatedUser(fresh);
    restore.complete(tUser);
    await checking;
    expect((container.read(authProvider) as AuthAuthenticated).user.id, '2');
  });
  test('logout invalidates a pending cached session read', () async {
    final restore = Completer<User?>();
    when(mockRepo.getCurrentUser).thenAnswer((_) => restore.future);
    when(mockRepo.logout).thenAnswer((_) async {});
    final auth = container.read(authProvider.notifier);
    final checking = auth.checkCurrentUser();
    await auth.logout();
    restore.complete(tUser);
    await checking;
    expect(container.read(authProvider), isA<AuthUnauthenticated>());
  });
}
