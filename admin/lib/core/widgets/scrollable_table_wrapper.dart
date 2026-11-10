import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_colors.dart';

class ScrollableTableWrapper extends StatefulWidget {
  final Widget child;

  const ScrollableTableWrapper({super.key, required this.child});

  @override
  State<ScrollableTableWrapper> createState() => _ScrollableTableWrapperState();
}

class _ScrollableTableWrapperState extends State<ScrollableTableWrapper> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // We add ScrollConfiguration to allow dragging with mouse (makes desktop scrolling easier)
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          ...ScrollConfiguration.of(context).dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.dragged)) {
                  return const Color(0xFF2563EB);
                }
                if (states.contains(WidgetState.hovered)) {
                  return isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                }
                return isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
              }),
              trackColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
              trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              radius: const Radius.circular(4),
              thickness: WidgetStateProperty.all(8.0),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      dataTableTheme: DataTableThemeData(
                        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return isDark ? AppColors.primary.withValues(alpha: 0.22) : const Color(0xFFDBEAFE);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
                          }
                          return null;
                        }),
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
