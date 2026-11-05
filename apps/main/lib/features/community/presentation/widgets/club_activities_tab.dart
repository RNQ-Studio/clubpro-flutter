import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import 'club_common.dart';
import 'community_visuals.dart';

class ClubActivitiesTab extends ConsumerWidget {
  const ClubActivitiesTab({super.key, required this.community});

  final CommunityDetail community;

  void _refresh(WidgetRef ref) {
    ref.invalidate(communityActivitiesProvider(community.id));
    ref.invalidate(communityDetailProvider(community.id));
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    CommunityActivity? activity,
  ]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => ClubActivitySheet(
        communityId: community.id,
        activity: activity,
      ),
    );
    if (saved == true && context.mounted) _refresh(ref);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CommunityActivity activity,
  ) async {
    final confirmed = await confirmClubAction(
      context,
      title: 'Hapus kegiatan?',
      message: '${activity.title} akan dihapus dari jadwal komunitas.',
      action: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runClubAction(
      context,
      () => ref
          .read(communityRepositoryProvider)
          .deleteActivity(community.id, activity.id),
      success: 'Kegiatan dihapus',
    );
    if (context.mounted) _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = communityActivitiesProvider(community.id);
    final canManage = community.canManage;
    final addButton = OutlinedButton.icon(
      key: const Key('club-add-activity'),
      onPressed: () => _edit(context, ref),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Tambah Kegiatan'),
    );

    return ClubTabScroll(
      storageKey: 'club-activities',
      child: ref.watch(provider).when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ClubEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat kegiatan',
              message: error.toString(),
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Coba Lagi'),
              ),
            ),
            data: (activities) {
              if (activities.upcoming.isEmpty && activities.past.isEmpty) {
                return ClubEmptyState(
                  icon: Icons.event_rounded,
                  title: 'Belum ada kegiatan',
                  message: canManage
                      ? 'Buat kegiatan pertama dan ajak anggota berkumpul.'
                      : 'Jadwal kegiatan komunitas akan tampil di sini.',
                  action: canManage ? addButton : null,
                );
              }

              final next = activities.upcoming.firstOrNull;
              final later = activities.upcoming.skip(1).toList();
              Widget? menu(CommunityActivity activity, {Color? iconColor}) =>
                  !canManage
                      ? null
                      : _ActivityMenu(
                          activity: activity,
                          iconColor: iconColor,
                          onEdit: () => _edit(context, ref, activity),
                          onDelete: () => _delete(context, ref, activity),
                        );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canManage) ...[
                    addButton,
                    const SizedBox(height: 14),
                  ],
                  if (next != null) ...[
                    _NextActivityCard(
                      activity: next,
                      menu: menu(next, iconColor: Colors.white),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (later.isNotEmpty) ...[
                    const ClubGroupTitle('Berikutnya'),
                    for (final activity in later)
                      _ActivityTile(activity: activity, menu: menu(activity)),
                    const SizedBox(height: 14),
                  ],
                  if (activities.past.isNotEmpty) ...[
                    const ClubGroupTitle('Sudah Berlangsung'),
                    for (final activity in activities.past)
                      _ActivityTile(
                        activity: activity,
                        past: true,
                        menu: menu(activity),
                      ),
                  ],
                ],
              );
            },
          ),
    );
  }
}

class _ActivityMenu extends StatelessWidget {
  const _ActivityMenu({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    this.iconColor,
  });

  final CommunityActivity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      key: Key('club-activity-menu-${activity.id}'),
      tooltip: 'Kelola kegiatan',
      iconColor: iconColor,
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(value: onEdit, child: const Text('Ubah')),
        PopupMenuItem(value: onDelete, child: const Text('Hapus')),
      ],
    );
  }
}

/// Sorotan kegiatan terdekat dengan hitung mundur.
class _NextActivityCard extends StatelessWidget {
  const _NextActivityCard({required this.activity, this.menu});

  final CommunityActivity activity;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startsAt = activity.startsAt.toLocal();
    final location = activity.location;
    final description = activity.description;
    const muted = Colors.white70;

    return Container(
      key: const Key('club-next-activity-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CommunityColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: CommunityColors.goldLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ClubDates.countdown(startsAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: CommunityColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (menu != null) menu!,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activity.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _Fact(
            icon: Icons.calendar_month_rounded,
            text: '${ClubDates.full(startsAt)}, '
                '${AppDateUtils.formatTime(startsAt)}',
            color: muted,
          ),
          if (location != null) ...[
            const SizedBox(height: 3),
            _Fact(icon: Icons.place_rounded, text: location, color: muted),
          ],
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    this.past = false,
    this.menu,
  });

  final CommunityActivity activity;
  final bool past;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startsAt = activity.startsAt.toLocal();
    final muted = theme.colorScheme.onSurfaceVariant;
    final location = activity.location;

    return Opacity(
      opacity: past ? 0.65 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: communityHairline(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: CommunityColors.gold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${startsAt.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: CommunityColors.brown,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    ClubDates.month(startsAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: CommunityColors.brown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Fact(
                    icon: Icons.schedule_rounded,
                    text: AppDateUtils.formatTime(startsAt),
                    color: muted,
                  ),
                  if (location != null)
                    _Fact(
                      icon: Icons.place_outlined,
                      text: location,
                      color: muted,
                    ),
                ],
              ),
            ),
            if (menu != null) menu!,
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Form kegiatan baru atau yang diubah.
class ClubActivitySheet extends ConsumerStatefulWidget {
  const ClubActivitySheet({
    super.key,
    required this.communityId,
    this.activity,
  });

  final String communityId;
  final CommunityActivity? activity;

  @override
  ConsumerState<ClubActivitySheet> createState() => _ClubActivitySheetState();
}

class _ClubActivitySheetState extends ConsumerState<ClubActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late DateTime _startsAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _title = TextEditingController(text: activity?.title);
    _location = TextEditingController(text: activity?.location);
    _description = TextEditingController(text: activity?.description);
    _startsAt = activity?.startsAt.toLocal() ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startsAt.hour,
        _startsAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final input = CommunityActivityInput(
      title: _title.text,
      startsAt: _startsAt,
      location: _location.text,
      description: _description.text,
    );
    final repository = ref.read(communityRepositoryProvider);
    final activity = widget.activity;
    try {
      if (activity == null) {
        await repository.createActivity(widget.communityId, input);
      } else {
        await repository.updateActivity(
          widget.communityId,
          activity.id,
          input,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.activity == null ? 'Kegiatan Baru' : 'Ubah Kegiatan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('club-activity-title'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nama Kegiatan',
                  hintText: 'Mis. Latihan Bersama',
                  prefixIcon: Icon(Icons.flag_rounded),
                  counterText: '',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Nama kegiatan minimal 3 karakter'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      key: const Key('club-activity-date'),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        AppDateUtils.longDateId(_startsAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      key: const Key('club-activity-time'),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(AppDateUtils.formatTime(_startsAt)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('club-activity-location'),
                controller: _location,
                textCapitalization: TextCapitalization.words,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Lokasi (opsional)',
                  prefixIcon: Icon(Icons.place_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('club-activity-description'),
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('club-activity-save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Kegiatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
