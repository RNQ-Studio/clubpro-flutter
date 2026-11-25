import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/money_movement.dart';
part 'movement_sharing.g.dart';

abstract interface class MovementSharing {
  Future<bool> openComposer(Uri uri);
  Future<void> shareProof(ProofFile file, String text, Rect origin);
}

class PlatformMovementSharing implements MovementSharing {
  const PlatformMovementSharing();
  @override
  Future<bool> openComposer(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
  @override
  Future<void> shareProof(ProofFile file, String text, Rect origin) async {
    await SharePlus.instance.share(ShareParams(
        text: text,
        title: 'Bukti pencairan',
        files: [XFile.fromData(file.bytes, mimeType: file.mimeType)],
        fileNameOverrides: [
          'bukti-pencairan.${file.mimeType == 'image/png' ? 'png' : file.mimeType == 'image/webp' ? 'webp' : 'jpg'}'
        ],
        sharePositionOrigin: origin));
  }
}

@riverpod
MovementSharing movementSharing(Ref ref) => const PlatformMovementSharing();
