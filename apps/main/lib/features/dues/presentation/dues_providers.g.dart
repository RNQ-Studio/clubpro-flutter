// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(duesRepository)
final duesRepositoryProvider = DuesRepositoryProvider._();

final class DuesRepositoryProvider
    extends $FunctionalProvider<DuesRepository, DuesRepository, DuesRepository>
    with $Provider<DuesRepository> {
  DuesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'duesRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$duesRepositoryHash();

  @$internal
  @override
  $ProviderElement<DuesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DuesRepository create(Ref ref) {
    return duesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DuesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DuesRepository>(value),
    );
  }
}

String _$duesRepositoryHash() => r'bb71efd7ebff1780723bdd31c4e82cf98a9405df';

/// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).

@ProviderFor(duesOverview)
final duesOverviewProvider = DuesOverviewFamily._();

/// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).

final class DuesOverviewProvider extends $FunctionalProvider<
        AsyncValue<DuesOverview>, DuesOverview, FutureOr<DuesOverview>>
    with $FutureModifier<DuesOverview>, $FutureProvider<DuesOverview> {
  /// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).
  DuesOverviewProvider._(
      {required DuesOverviewFamily super.from,
      required (
        String,
        int?,
      )
          super.argument})
      : super(
          retry: noRetry,
          name: r'duesOverviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$duesOverviewHash();

  @override
  String toString() {
    return r'duesOverviewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DuesOverview> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DuesOverview> create(Ref ref) {
    final argument = this.argument as (
      String,
      int?,
    );
    return duesOverview(
      ref,
      argument.$1,
      argument.$2,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DuesOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$duesOverviewHash() => r'5080af62e2736ba5162f8dbf01e089158afb28ef';

/// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).

final class DuesOverviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<DuesOverview>,
            (
              String,
              int?,
            )> {
  DuesOverviewFamily._()
      : super(
          retry: noRetry,
          name: r'duesOverviewProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).

  DuesOverviewProvider call(
    String communityId,
    int? year,
  ) =>
      DuesOverviewProvider._(argument: (
        communityId,
        year,
      ), from: this);

  @override
  String toString() => r'duesOverviewProvider';
}

@ProviderFor(memberDues)
final memberDuesProvider = MemberDuesFamily._();

final class MemberDuesProvider extends $FunctionalProvider<
        AsyncValue<MemberDuesDetail>,
        MemberDuesDetail,
        FutureOr<MemberDuesDetail>>
    with $FutureModifier<MemberDuesDetail>, $FutureProvider<MemberDuesDetail> {
  MemberDuesProvider._(
      {required MemberDuesFamily super.from,
      required (
        String,
        String,
        int,
      )
          super.argument})
      : super(
          retry: noRetry,
          name: r'memberDuesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memberDuesHash();

  @override
  String toString() {
    return r'memberDuesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MemberDuesDetail> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MemberDuesDetail> create(Ref ref) {
    final argument = this.argument as (
      String,
      String,
      int,
    );
    return memberDues(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberDuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberDuesHash() => r'062c48d3e61d15f21ca69ff3f1fbad60489d181d';

final class MemberDuesFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MemberDuesDetail>,
            (
              String,
              String,
              int,
            )> {
  MemberDuesFamily._()
      : super(
          retry: noRetry,
          name: r'memberDuesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MemberDuesProvider call(
    String communityId,
    String userId,
    int year,
  ) =>
      MemberDuesProvider._(argument: (
        communityId,
        userId,
        year,
      ), from: this);

  @override
  String toString() => r'memberDuesProvider';
}

/// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).

@ProviderFor(DuesPaymentsNotifier)
final duesPaymentsProvider = DuesPaymentsNotifierFamily._();

/// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).
final class DuesPaymentsNotifierProvider extends $AsyncNotifierProvider<
    DuesPaymentsNotifier, PagedState<DuesPayment>> {
  /// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).
  DuesPaymentsNotifierProvider._(
      {required DuesPaymentsNotifierFamily super.from,
      required (
        String,
        DuesPaymentStatus?,
      )
          super.argument})
      : super(
          retry: noRetry,
          name: r'duesPaymentsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$duesPaymentsNotifierHash();

  @override
  String toString() {
    return r'duesPaymentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DuesPaymentsNotifier create() => DuesPaymentsNotifier();

  @override
  bool operator ==(Object other) {
    return other is DuesPaymentsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$duesPaymentsNotifierHash() =>
    r'3a8675b11ddd5f9beac5c3847f0a37ac6390c24d';

/// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).

final class DuesPaymentsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            DuesPaymentsNotifier,
            AsyncValue<PagedState<DuesPayment>>,
            PagedState<DuesPayment>,
            FutureOr<PagedState<DuesPayment>>,
            (
              String,
              DuesPaymentStatus?,
            )> {
  DuesPaymentsNotifierFamily._()
      : super(
          retry: noRetry,
          name: r'duesPaymentsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).

  DuesPaymentsNotifierProvider call(
    String communityId,
    DuesPaymentStatus? status,
  ) =>
      DuesPaymentsNotifierProvider._(argument: (
        communityId,
        status,
      ), from: this);

  @override
  String toString() => r'duesPaymentsProvider';
}

/// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).

abstract class _$DuesPaymentsNotifier
    extends $AsyncNotifier<PagedState<DuesPayment>> {
  late final _$args = ref.$arg as (
    String,
    DuesPaymentStatus?,
  );
  String get communityId => _$args.$1;
  DuesPaymentStatus? get status => _$args.$2;

  FutureOr<PagedState<DuesPayment>> build(
    String communityId,
    DuesPaymentStatus? status,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<PagedState<DuesPayment>>, PagedState<DuesPayment>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PagedState<DuesPayment>>,
            PagedState<DuesPayment>>,
        AsyncValue<PagedState<DuesPayment>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args.$1,
              _$args.$2,
            ));
  }
}

/// Kalender iuran semua anggota untuk [year], bisa dicari per nama.

@ProviderFor(MembersDuesNotifier)
final membersDuesProvider = MembersDuesNotifierFamily._();

/// Kalender iuran semua anggota untuk [year], bisa dicari per nama.
final class MembersDuesNotifierProvider extends $AsyncNotifierProvider<
    MembersDuesNotifier, PagedState<MemberDues>> {
  /// Kalender iuran semua anggota untuk [year], bisa dicari per nama.
  MembersDuesNotifierProvider._(
      {required MembersDuesNotifierFamily super.from,
      required (
        String,
        int,
        String,
      )
          super.argument})
      : super(
          retry: noRetry,
          name: r'membersDuesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$membersDuesNotifierHash();

  @override
  String toString() {
    return r'membersDuesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  MembersDuesNotifier create() => MembersDuesNotifier();

  @override
  bool operator ==(Object other) {
    return other is MembersDuesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membersDuesNotifierHash() =>
    r'fcea3f7269c6e6d9cf2db85b2eb843cfe105bc05';

/// Kalender iuran semua anggota untuk [year], bisa dicari per nama.

final class MembersDuesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            MembersDuesNotifier,
            AsyncValue<PagedState<MemberDues>>,
            PagedState<MemberDues>,
            FutureOr<PagedState<MemberDues>>,
            (
              String,
              int,
              String,
            )> {
  MembersDuesNotifierFamily._()
      : super(
          retry: noRetry,
          name: r'membersDuesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Kalender iuran semua anggota untuk [year], bisa dicari per nama.

  MembersDuesNotifierProvider call(
    String communityId,
    int year,
    String search,
  ) =>
      MembersDuesNotifierProvider._(argument: (
        communityId,
        year,
        search,
      ), from: this);

  @override
  String toString() => r'membersDuesProvider';
}

/// Kalender iuran semua anggota untuk [year], bisa dicari per nama.

abstract class _$MembersDuesNotifier
    extends $AsyncNotifier<PagedState<MemberDues>> {
  late final _$args = ref.$arg as (
    String,
    int,
    String,
  );
  String get communityId => _$args.$1;
  int get year => _$args.$2;
  String get search => _$args.$3;

  FutureOr<PagedState<MemberDues>> build(
    String communityId,
    int year,
    String search,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<PagedState<MemberDues>>, PagedState<MemberDues>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PagedState<MemberDues>>, PagedState<MemberDues>>,
        AsyncValue<PagedState<MemberDues>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args.$1,
              _$args.$2,
              _$args.$3,
            ));
  }
}
