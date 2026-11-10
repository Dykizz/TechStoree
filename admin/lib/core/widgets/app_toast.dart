import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastItem {
  final String id;
  final String message;
  final String? title;
  final ToastType type;
  final Duration duration;

  ToastItem({
    required this.id,
    required this.message,
    this.title,
    this.type = ToastType.info,
    this.duration = const Duration(milliseconds: 3500),
  });
}

/// Hệ thống thông báo nổi góc trên bên phải (Top-Right Floating Toast)
/// Chuẩn thiết kế Enterprise Web/Desktop Dashboard
class AppToast {
  static _ToastOverlayManager? _manager;

  /// Hiển thị thông báo tùy chỉnh
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _manager ??= _ToastOverlayManager();
    _manager!.show(
      overlay: overlay,
      item: ToastItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        message: message,
        title: title,
        type: type,
        duration: duration,
      ),
    );
  }

  /// Thông báo Thành công (Màu xanh lá)
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thành công',
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Thông báo Lỗi / Thất bại (Màu đỏ)
  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thất bại',
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Thông báo Cảnh báo (Màu vàng hổ phách)
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Cảnh báo',
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Thông báo Thông tin (Màu xanh dương)
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thông báo',
      type: ToastType.info,
      duration: duration,
    );
  }
}

class _ToastOverlayManager {
  OverlayEntry? _entry;
  final List<ToastItem> _items = [];
  final GlobalKey<_ToastContainerState> _containerKey = GlobalKey<_ToastContainerState>();

  void show({required OverlayState overlay, required ToastItem item}) {
    _items.insert(0, item); // Thêm vào đầu để thông báo mới nhất nằm trên cùng
    if (_items.length > 5) {
      _items.removeLast(); // Giữ tối đa 5 thông báo cùng lúc để không tràn màn hình
    }

    if (_entry == null || !(_entry!.mounted)) {
      _entry = OverlayEntry(
        builder: (context) => _ToastContainer(
          key: _containerKey,
          manager: this,
          initialItems: List.from(_items),
        ),
      );
      overlay.insert(_entry!);
    } else {
      _containerKey.currentState?.updateItems(List.from(_items));
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    if (_items.isEmpty) {
      if (_entry != null && _entry!.mounted) {
        _entry?.remove();
      }
      _entry = null;
    } else {
      _containerKey.currentState?.updateItems(List.from(_items));
    }
  }
}

class _ToastContainer extends StatefulWidget {
  final _ToastOverlayManager manager;
  final List<ToastItem> initialItems;

  const _ToastContainer({
    super.key,
    required this.manager,
    required this.initialItems,
  });

  @override
  State<_ToastContainer> createState() => _ToastContainerState();
}

class _ToastContainerState extends State<_ToastContainer> {
  late List<ToastItem> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.initialItems);
  }

  void updateItems(List<ToastItem> items) {
    if (mounted) {
      setState(() {
        _currentItems = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;

    return Positioned(
      top: 18,
      right: isCompact ? 12 : 24,
      left: isCompact ? 12 : null,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isCompact ? mediaQuery.size.width - 24 : 380,
            minWidth: isCompact ? mediaQuery.size.width - 24 : 320,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _currentItems.map((item) {
              return _ToastCard(
                key: ValueKey(item.id),
                item: item,
                onDismiss: () => widget.manager.removeItem(item.id),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  final ToastItem item;
  final VoidCallback onDismiss;

  const _ToastCard({
    super.key,
    required this.item,
    required this.onDismiss,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.35, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _timer = Timer(widget.item.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (Color accentColor, Color bgTint, IconData icon) _getVisuals(ToastType type) {
    switch (type) {
      case ToastType.success:
        return (AppColors.success, AppColors.successBg, Icons.check_circle_rounded);
      case ToastType.error:
        return (AppColors.danger, AppColors.dangerBg, Icons.error_rounded);
      case ToastType.warning:
        return (AppColors.warning, AppColors.warningBg, Icons.warning_rounded);
      case ToastType.info:
        return (AppColors.primary, AppColors.infoBg, Icons.info_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (accentColor, bgTint, icon) = _getVisuals(widget.item.type);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dải vạch màu trạng thái bên trái
                  Container(
                    width: 4,
                    color: accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon trạng thái có nền tròn mờ nhẹ
                          Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(top: 1, right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? accentColor.withValues(alpha: 0.2) : bgTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: accentColor, size: 16),
                          ),

                          // Nội dung Tiêu đề & Thông điệp
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.item.title != null && widget.item.title!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      widget.item.title!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                Text(
                                  widget.item.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w400,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Nút đóng nhanh
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
