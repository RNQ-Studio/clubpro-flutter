import 'package:app_main/features/home/domain/repositories/promotion_popup_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Waktu tampil popup per akun, di memori.
class FakePromotionPopupStore implements PromotionPopupStore {
  FakePromotionPopupStore([Map<String, DateTime>? shown]) : shown = {...?shown};

  final Map<String, DateTime> shown;

  /// Setiap pencatatan, berurutan.
  final marks = <(String, DateTime)>[];

  @override
  Future<DateTime?> lastShown(String userId) async => shown[userId];

  @override
  Future<void> markShown(String userId, DateTime at) async {
    shown[userId] = at;
    marks.add((userId, at));
  }
}

/// Mencatat tautan yang dibuka di luar app, tanpa membukanya.
class FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  FakeUrlLauncher({this.canOpen = true});

  final bool canOpen;
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canOpen;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return canOpen;
  }

  /// Dipasang untuk satu test, lalu dikembalikan.
  static FakeUrlLauncher install({bool canOpen = true}) {
    final previous = UrlLauncherPlatform.instance;
    final fake = FakeUrlLauncher(canOpen: canOpen);
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    return fake;
  }
}
