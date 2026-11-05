// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_community_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Angka di halaman menu; menu tetap bisa dipakai bila gagal dimuat.

@ProviderFor(adminSummary)
final adminSummaryProvider = AdminSummaryProvider._();

/// Angka di halaman menu; menu tetap bisa dipakai bila gagal dimuat.

final class AdminSummaryProvider extends $FunctionalProvider<
        AsyncValue<AdminPanelSummary>,
        AdminPanelSummary,
        FutureOr<AdminPanelSummary>>
    with
        $FutureModifier<AdminPanelSummary>,
        $FutureProvider<AdminPanelSummary> {
  /// Angka di halaman menu; menu tetap bisa dipakai bila gagal dimuat.
  AdminSummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminSummaryHash();

  @$internal
  @override
  $FutureProviderElement<AdminPanelSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AdminPanelSummary> create(Ref ref) {
    return adminSummary(ref);
  }
}

String _$adminSummaryHash() => r'be5f806aa617e981954f23911340646799dcf3be';

/// Kelola Komunitas: semua status, terbaru di atas.

@ProviderFor(AdminCommunitiesNotifier)
final adminCommunitiesProvider = AdminCommunitiesNotifierProvider._();

/// Kelola Komunitas: semua status, terbaru di atas.
final class AdminCommunitiesNotifierProvider extends $AsyncNotifierProvider<
    AdminCommunitiesNotifier, AdminCommunitiesState> {
  /// Kelola Komunitas: semua status, terbaru di atas.
  AdminCommunitiesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminCommunitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminCommunitiesNotifierHash();

  @$internal
  @override
  AdminCommunitiesNotifier create() => AdminCommunitiesNotifier();
}

String _$adminCommunitiesNotifierHash() =>
    r'5758d69d6a0fb594c2c6cd85e8fc3743e4b2b6cf';

/// Kelola Komunitas: semua status, terbaru di atas.

abstract class _$AdminCommunitiesNotifier
    extends $AsyncNotifier<AdminCommunitiesState> {
  FutureOr<AdminCommunitiesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<AdminCommunitiesState>, AdminCommunitiesState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AdminCommunitiesState>, AdminCommunitiesState>,
        AsyncValue<AdminCommunitiesState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

/// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

@ProviderFor(AdminCommunityDetailNotifier)
final adminCommunityDetailProvider = AdminCommunityDetailNotifierFamily._();

/// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
final class AdminCommunityDetailNotifierProvider extends $AsyncNotifierProvider<
    AdminCommunityDetailNotifier, AdminCommunityDetail> {
  /// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
  /// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
  AdminCommunityDetailNotifierProvider._(
      {required AdminCommunityDetailNotifierFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'adminCommunityDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminCommunityDetailNotifierHash();

  @override
  String toString() {
    return r'adminCommunityDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminCommunityDetailNotifier create() => AdminCommunityDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is AdminCommunityDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminCommunityDetailNotifierHash() =>
    r'3845f7cdd1543c432d31a0dc8786f1d8e1f5bf73';

/// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

final class AdminCommunityDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            AdminCommunityDetailNotifier,
            AsyncValue<AdminCommunityDetail>,
            AdminCommunityDetail,
            FutureOr<AdminCommunityDetail>,
            String> {
  AdminCommunityDetailNotifierFamily._()
      : super(
          retry: null,
          name: r'adminCommunityDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
  /// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

  AdminCommunityDetailNotifierProvider call(
    String id,
  ) =>
      AdminCommunityDetailNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'adminCommunityDetailProvider';
}

/// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

abstract class _$AdminCommunityDetailNotifier
    extends $AsyncNotifier<AdminCommunityDetail> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<AdminCommunityDetail> build(
    String id,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<AdminCommunityDetail>, AdminCommunityDetail>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AdminCommunityDetail>, AdminCommunityDetail>,
        AsyncValue<AdminCommunityDetail>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
