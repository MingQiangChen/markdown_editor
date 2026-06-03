import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

PreferredSizeWidget buildFindBar(
    BuildContext context, CodeFindController controller, bool readonly) {
  final cs = Theme.of(context).colorScheme;
  final value = controller.value;
  final replaceMode = value?.replaceMode ?? false;
  final result = value?.result;
  final matchCount = result?.matches.length ?? 0;
  final currentIdx = result != null && matchCount > 0 ? result.index + 1 : 0;

  return PreferredSize(
    preferredSize: Size.fromHeight(replaceMode ? 72 : 36),
    child: Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: controller.close,
                    padding: EdgeInsets.zero,
                    splashRadius: 14,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 180,
                  height: 28,
                  child: TextField(
                    controller: controller.findInputController,
                    focusNode: controller.findInputFocusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '查找...',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (value != null &&
                    controller.findInputController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      matchCount > 0
                          ? '$currentIdx/$matchCount'
                          : '无匹配',
                      style: TextStyle(
                        fontSize: 12,
                        color: matchCount == 0
                            ? Colors.red
                            : cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.arrow_upward,
                  onPressed: controller.previousMatch,
                ),
                _IconBtn(
                  icon: Icons.arrow_downward,
                  onPressed: controller.nextMatch,
                ),
                _IconBtn(
                  icon: Icons.find_replace,
                  onPressed: controller.toggleMode,
                  active: replaceMode,
                ),
                _IconBtn(
                  icon: Icons.text_fields,
                  tooltip: '大小写敏感',
                  onPressed: controller.toggleCaseSensitive,
                  active: value?.option.caseSensitive ?? false,
                ),
                _IconBtn(
                  icon: Icons.code,
                  tooltip: '正则表达式',
                  onPressed: controller.toggleRegex,
                  active: value?.option.regex ?? false,
                ),
              ],
            ),
          ),
          if (replaceMode)
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 180,
                    height: 28,
                    child: TextField(
                      controller: controller.replaceInputController,
                      focusNode: controller.replaceInputFocusNode,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '替换为...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4)),
                        isDense: true,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TextBtn('替换', controller.replaceMatch),
                  const SizedBox(width: 4),
                  _TextBtn('全部', controller.replaceAllMatches),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool active;

  const _IconBtn({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: active ? cs.primary : null,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 14,
        tooltip: tooltip,
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TextBtn(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 12),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label),
      ),
    );
  }
}
