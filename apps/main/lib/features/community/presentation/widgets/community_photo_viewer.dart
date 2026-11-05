import 'package:flutter/material.dart';

import 'community_visuals.dart';

/// Kisi foto; mengetuk satu foto membuka penampil layar penuh.
class CommunityPhotoGrid extends StatelessWidget {
  const CommunityPhotoGrid({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final (index, url) in urls.indexed)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              key: Key('community-photo-thumb-$index'),
              onTap: () => showCommunityPhotoViewer(context, urls, index),
              child: CommunityNetworkImage(url: url),
            ),
          ),
      ],
    );
  }
}

/// Penampil layar penuh: geser antarfoto, cubit atau gulir untuk memperbesar.
Future<void> showCommunityPhotoViewer(
  BuildContext context,
  List<String> urls,
  int initialIndex,
) =>
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          _PhotoViewer(urls: urls, initialIndex: initialIndex),
    );

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    _controller.animateToPage(
      _index + delta,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Widget _control({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton.filled(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return Dialog.fullscreen(
      key: const Key('community-photo-viewer'),
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: CommunityNetworkImage(
                  url: urls[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _control(
                    tooltip: 'Tutup',
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (urls.length > 1)
                    Text(
                      '${_index + 1} / ${urls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Tombol untuk pengguna tetikus, yang tidak bisa menggeser PageView.
          if (_index > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _control(
                  tooltip: 'Foto sebelumnya',
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _go(-1),
                ),
              ),
            ),
          if (_index < urls.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _control(
                  tooltip: 'Foto berikutnya',
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _go(1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
