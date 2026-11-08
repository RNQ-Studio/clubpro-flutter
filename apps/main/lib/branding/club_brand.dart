import 'package:flutter/material.dart';

/// Identitas app anggota CEO (Community E-Commerce Operator).
abstract final class ClubBrand {
  static const name = 'CEO';
  static const shortName = 'CEO';
  static const tagline = 'Community E-Commerce Operator';

  /// Judul tab browser / pengalih tugas.
  static const title = '$name · $tagline';

  // Aksen emas dari logo di atas tema monokrom.
  static const gold = Color(0xFFBE8815);
  static const goldDeep = Color(0xFF8A5C06);
}
