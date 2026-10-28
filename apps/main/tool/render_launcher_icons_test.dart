// Merender ikon launcher Android, iOS, web, dan aset logo app dari sumber
// logo `tool/brand/logo-ceo.jpeg`.
//
// Jalankan dari apps/main setelah mengganti sumber logo:
//   flutter test tool/render_launcher_icons_test.dart
// Pratinjau satu PNG 512px tanpa menimpa ikon:
//   RENDER_PREVIEW=/tmp/logo.png flutter test tool/render_launcher_icons_test.dart
//
// Aset app `assets/branding/logo_ceo.jpg` (512px) dibuat terpisah dengan:
//   sips -Z 512 -s format jpeg -s formatOptions 86 tool/brand/logo-ceo.jpeg \
//     --out assets/branding/logo_ceo.jpg
//
// Ada di tool/ (bukan test/) supaya tidak ikut `melos run test`.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = 'tool/brand/logo-ceo.jpeg';

const _android = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

void main() {
  test('render launcher icons', () async {
    final source = File(_source).readAsBytesSync();
    final preview = Platform.environment['RENDER_PREVIEW'];
    if (preview != null) {
      await _render(source, 512, preview, cornerRadius: 0.22);
      return;
    }

    for (final entry in _android.entries) {
      await _render(
        source,
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
      await _render(source, (points * scale).round(), '$iosDir/$filename',
          cornerRadius: 0);
    }

    await _render(source, 192, 'web/icons/Icon-192.png', cornerRadius: 0.22);
    await _render(source, 512, 'web/icons/Icon-512.png', cornerRadius: 0.22);
    // Maskable: latar penuh; emblem berada di dalam zona aman 80%.
    await _render(source, 192, 'web/icons/Icon-maskable-192.png',
        cornerRadius: 0);
    await _render(source, 512, 'web/icons/Icon-maskable-512.png',
        cornerRadius: 0);
    // Favicon 32px: dipotong rapat ke emblem agar tetap terbaca.
    await _render(source, 32, 'web/favicon.png',
        cornerRadius: 0.22, crop: const Rect.fromLTRB(0.12, 0.1, 0.88, 0.86));
  });
}

/// Decoder memperkecil langsung ke ukuran akhir (kualitas lebih baik daripada
/// menggambar 1254px ke kanvas kecil), lalu sudut dibulatkan bila perlu.
/// [crop] = bagian sumber (pecahan 0–1) yang dipakai; bawaannya seluruh logo.
Future<void> _render(List<int> source, int px, String path,
    {required double cornerRadius,
    Rect crop = const Rect.fromLTRB(0, 0, 1, 1)}) async {
  final decoded = (px / crop.width).round();
  final codec = await ui.instantiateImageCodec(
    Uint8List.fromList(source),
    targetWidth: decoded,
    targetHeight: decoded,
  );
  final logo = (await codec.getNextFrame()).image;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble());
  if (cornerRadius > 0) {
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(px * cornerRadius)));
  }
  canvas.drawImageRect(
    logo,
    Rect.fromLTRB(crop.left * decoded, crop.top * decoded, crop.right * decoded,
        crop.bottom * decoded),
    rect,
    Paint()..filterQuality = FilterQuality.high,
  );
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
