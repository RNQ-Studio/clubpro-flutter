import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/member_card.dart';

/// Kartu anggota bergaya kartu premium (rasio kartu bank): hitam-emas bila
/// berlaku, abu-abu bila kedaluwarsa atau belum aktif.
class MemberCardView extends StatelessWidget {
  const MemberCardView({super.key, required this.card});

  final MemberCard card;

  /// Rasio kartu ISO/IEC 7810 ID-1.
  static const aspectRatio = 85.6 / 53.98;

  static const validGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15110A), Color(0xFF3A2606), Color(0xFFBE8815)],
    stops: [0, 0.58, 1],
  );
  static const invalidGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1C), Color(0xFF383838), Color(0xFF6E6E6E)],
    stops: [0, 0.58, 1],
  );

  static const gold = Color(0xFFF3D58A);

  @override
  Widget build(BuildContext context) {
    final valid = card.validity.status.isValid;
    return Semantics(
      container: true,
      label: 'Kartu anggota ${card.community.name}, ${card.name}, '
          'nomor ${card.memberNumber}, ${statusLabel(card.validity.status)}',
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ukuran isi mengikuti lebar kartu; teks sistem besar dibatasi
            // agar isi tetap muat dalam rasio kartu.
            final scale = (constraints.maxWidth / 340).clamp(0.8, 1.35);
            return MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: DecoratedBox(
                key: const Key('member-card'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: (valid ? const Color(0xFF8A5C06) : Colors.black)
                          .withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20 * scale),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: valid ? validGradient : invalidGradient,
                    ),
                    child: Stack(
                      children: [
                        ..._decorations(constraints.biggest),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20 * scale),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(18 * scale),
                          child: _Content(card: card, scale: scale),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Lingkaran transparan dan kilau diagonal tipis.
  static List<Widget> _decorations(Size size) => [
        Positioned(
          right: -size.width * 0.18,
          top: -size.height * 0.45,
          child: _circle(size.width * 0.7, 0.06),
        ),
        Positioned(
          left: -size.width * 0.15,
          bottom: -size.height * 0.6,
          child: _circle(size.width * 0.6, 0.04),
        ),
        // Di antara baris nama dan baris nomor, tidak memotong teks.
        Positioned(
          left: -size.width * 0.1,
          right: -size.width * 0.1,
          top: size.height * 0.69,
          child: Transform.rotate(
            angle: -math.pi / 48,
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gold.withValues(alpha: 0),
                    gold.withValues(alpha: 0.35),
                    gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];

  static Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  static String statusLabel(MemberCardStatus status) => switch (status) {
        MemberCardStatus.active || MemberCardStatus.noDues => 'Aktif',
        MemberCardStatus.expired => 'Kedaluwarsa',
        MemberCardStatus.inactive => 'Belum aktif',
      };
}

class _Content extends StatelessWidget {
  const _Content({required this.card, required this.scale});

  final MemberCard card;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final validity = card.validity;
    final validUntil = switch (validity.status) {
      MemberCardStatus.noDues => 'Selama anggota',
      _ when validity.validUntil != null => shortDateId(validity.validUntil!),
      _ => '—',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _CommunityLogo(card: card, size: 38 * scale),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.community.name,
                    key: const Key('member-card-community'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'KARTU ANGGOTA',
                    style: TextStyle(
                      color: MemberCardView.gold,
                      fontSize: 9.5 * scale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2 * scale,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            _StatusChip(status: validity.status, scale: scale),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            _Avatar(card: card, size: 50 * scale),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    key: const Key('member-card-name'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    card.roleLabel,
                    style: TextStyle(
                      color: MemberCardView.gold,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 5,
              child: _Field(
                label: 'NO. ANGGOTA',
                value: card.memberNumber,
                valueKey: const Key('member-card-number'),
                scale: scale,
                mono: true,
              ),
            ),
            Expanded(
              flex: 4,
              child: _Field(
                label: 'SEJAK',
                value: card.joinedAt == null
                    ? '—'
                    : shortMonthYearId(card.joinedAt!),
                scale: scale,
              ),
            ),
            Expanded(
              flex: 5,
              child: _Field(
                label: 'BERLAKU S.D.',
                value: validUntil,
                valueKey: const Key('member-card-valid-until'),
                scale: scale,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.scale,
    this.valueKey,
    this.mono = false,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final double scale;
  final Key? valueKey;
  final bool mono;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2 * scale,
          ),
        ),
        SizedBox(height: 3 * scale),
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: mono ? 1.1 * scale : 0,
            fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.scale});

  final MemberCardStatus status;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MemberCardStatus.active ||
      MemberCardStatus.noDues =>
        const Color(0xFF1F9D63),
      MemberCardStatus.expired => const Color(0xFFD64545),
      MemberCardStatus.inactive => const Color(0xFFC98A00),
    };
    return Container(
      key: Key('member-card-status-${status.apiValue}'),
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        MemberCardView.statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 9 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8 * scale,
        ),
      ),
    );
  }
}

class _CommunityLogo extends StatelessWidget {
  const _CommunityLogo({required this.card, required this.size});

  final MemberCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = Text(
      card.community.shortName.characters.take(3).toString().toUpperCase(),
      style: TextStyle(
        color: const Color(0xFF5C3A02),
        fontWeight: FontWeight.w800,
        fontSize: size * 0.32,
      ),
    );
    final url = card.community.logoUrl;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initials
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initials,
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.card, required this.size});

  final MemberCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = card.avatarUrl;
    final initial = card.name.trim().isEmpty
        ? '?'
        : card.name.trim().characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF8E6A8), Color(0xFFBE8815)],
        ),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF2B2416),
        foregroundImage: url == null ? null : NetworkImage(url),
        onForegroundImageError: url == null ? null : (_, __) {},
        child: Text(
          initial,
          style: TextStyle(
            color: MemberCardView.gold,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "10 Des 2026".
String shortDateId(DateTime date) =>
    '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

/// "Mar 2026".
String shortMonthYearId(DateTime date) =>
    '${_shortMonths[date.month - 1]} ${date.year}';
