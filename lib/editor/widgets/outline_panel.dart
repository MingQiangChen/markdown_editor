import 'package:flutter/material.dart';

class HeadingInfo {
  final int level;
  final String text;
  final int lineIndex;

  HeadingInfo({
    required this.level,
    required this.text,
    required this.lineIndex,
  });
}

class OutlinePanel extends StatelessWidget {
  final String content;
  final int? activeLine;
  final ValueChanged<int> onHeadingTap;

  const OutlinePanel({
    super.key,
    required this.content,
    this.activeLine,
    required this.onHeadingTap,
  });

  List<HeadingInfo> _extractHeadings() {
    final headings = <HeadingInfo>[];
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(lines[i]);
      if (match != null) {
        headings.add(HeadingInfo(
          level: match.group(1)!.length,
          text: match.group(2)!.trim(),
          lineIndex: i,
        ));
      }
    }
    return headings;
  }

  @override
  Widget build(BuildContext context) {
    final headings = _extractHeadings();
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '大纲',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${headings.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: headings.isEmpty
                ? Center(
                    child: Text(
                      '暂无标题',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: headings.length,
                    itemBuilder: (context, index) {
                      final h = headings[index];
                      final isActive = activeLine != null &&
                          h.lineIndex <= activeLine! &&
                          (index == headings.length - 1 ||
                              headings[index + 1].lineIndex > activeLine!);

                      return _HeadingTile(
                        heading: h,
                        isActive: isActive,
                        onTap: () => onHeadingTap(h.lineIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeadingTile extends StatelessWidget {
  final HeadingInfo heading;
  final bool isActive;
  final VoidCallback onTap;

  const _HeadingTile({
    required this.heading,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final indent = (heading.level - 1) * 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isActive ? cs.primaryContainer.withValues(alpha: 0.3) : null,
        padding: EdgeInsets.only(left: 8 + indent, right: 8, top: 4, bottom: 4),
        child: Row(
          children: [
            _HeadingIcon(level: heading.level, isActive: isActive),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                heading.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5 - heading.level * 0.5,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadingIcon extends StatelessWidget {
  final int level;
  final bool isActive;

  const _HeadingIcon({required this.level, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.35);

    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Text(
          'H${level.clamp(1, 6)}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
