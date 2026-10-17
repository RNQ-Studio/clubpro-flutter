// Merender ikon launcher Android, iOS, dan web dari ClubLogoPainter.
//
// Jalankan dari apps/main:
//   flutter test tool/render_launcher_icons_test.dart
// Pratinjau satu PNG 512px tanpa menimpa ikon:
//   RENDER_PREVIEW=/tmp/logo.png flutter test tool/render_launcher_icons_test.dart
//
// Ada di tool/ (bukan test/) supaya tidak ikut `melos run test`.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/branding/club_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _android = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

void main() {
  test('render launcher icons', () async {
    final preview = Platform.environment['RENDER_PREVIEW'];
    if (preview != null) {
      await _render(512, preview, cornerRadius: 0.22);
      return;
    }

    for (final entry in _android.entries) {
      await _render(
        entry.value,
        'android/app/src/main/res/${entry.key}/ic_launcher.png',
        cornerRadius: 0.22,
      );
    }

    // iOS memberi masker sudut sendiri → latar penuh tanpa sudut membulat.
    const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents =
        jsonDecode(File('$iosDir/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final image
        in (contents['images'] as List).cast<Map<String, dynamic>>()) {
      final filename = image['filename'] as String?;
      if (filename == null) continue;
      final points = double.parse((image['size'] as String).split('x').first);
      final scale =
          double.parse((image['scale'] as String).replaceAll('x', ''));
      await _render((points * scale).round(), '$iosDir/$filename',
          cornerRadius: 0);
    }

    await _render(192, 'web/icons/Icon-192.png', cornerRadius: 0.22);
    await _render(512, 'web/icons/Icon-512.png', cornerRadius: 0.22);
    await _render(192, 'web/icons/Icon-maskable-192.png', cornerRadius: 0);
    await _render(512, 'web/icons/Icon-maskable-512.png', cornerRadius: 0);
    await _render(32, 'web/favicon.png', cornerRadius: 0.22);
  });
}

Future<void> _render(int px, String path,
    {required double cornerRadius}) async {
  final recorder = ui.PictureRecorder();
  ClubLogoPainter(cornerRadius: cornerRadius)
      .paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
