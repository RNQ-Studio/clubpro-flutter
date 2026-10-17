import 'package:flutter/material.dart';

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.color,
    this.isGallery = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isGallery;
}

const _menuItems = [
  _MenuItem(
    label: 'UI Gallery',
    icon: Icons.widgets_outlined,
    color: Colors.indigo,
    isGallery: true,
  ),
  _MenuItem(
      label: 'Kutipan', icon: Icons.format_quote_rounded, color: Colors.indigo),
  _MenuItem(
      label: 'Menu 02', icon: Icons.military_tech, color: Colors.deepOrange),
  _MenuItem(label: 'Menu 03', icon: Icons.show_chart, color: Colors.teal),
  _MenuItem(label: 'Menu 04', icon: Icons.storage, color: Colors.amber),
  _MenuItem(label: 'Menu 05', icon: Icons.group_add, color: Colors.green),
  _MenuItem(
      label: 'Profil', icon: Icons.person_outline_rounded, color: Colors.cyan),
  _MenuItem(label: 'Menu 07', icon: Icons.people, color: Color(0xFF00695C)),
  _MenuItem(label: 'Menu 08', icon: Icons.bar_chart, color: Colors.deepPurple),
  _MenuItem(label: 'Menu 09', icon: Icons.search, color: Colors.teal),
  _MenuItem(label: 'Menu 10', icon: Icons.location_on, color: Colors.brown),
  _MenuItem(
      label: 'Menu 11', icon: Icons.lightbulb_outline, color: Colors.amber),
  _MenuItem(label: 'Menu 12', icon: Icons.calculate, color: Colors.blueGrey),
  _MenuItem(label: 'Menu 13', icon: Icons.timer, color: Colors.red),
  _MenuItem(
      label: 'Menu 14', icon: Icons.feedback_outlined, color: Colors.orange),
  _MenuItem(label: 'Menu 15', icon: Icons.star_outline, color: Colors.indigo),
];

class HomeMenuGrid extends StatelessWidget {
  const HomeMenuGrid({super.key, required this.onMenuTap});

  final void Function(String label) onMenuTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _MenuCell(item: item, onTap: () => onMenuTap(item.label));
      },
    );
  }
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cellBgColor = colorScheme.primaryContainer;
    final iconColor = colorScheme.onPrimaryContainer;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cellBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
