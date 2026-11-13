import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';

/// Bọc nội dung danh sách, bảng dữ liệu hoặc panel khi tải dữ liệu mà không làm sập chiều cao
/// hay nháy trắng toàn màn hình lúc người dùng click bộ lọc / chuyển tab / phân trang.
///
/// - Lần đầu chưa có dữ liệu (`isLoading && !hasData`): hiển thị khung thẻ chờ có nền đồng bộ theme.
/// - Các lần tải lại (`isLoading && hasData`): giữ nguyên [child] tại chỗ, giảm nhẹ độ rõ và chạy
///   thanh tiến trình mỏng ở cạnh trên.
class SmoothLoadingWrapper extends StatelessWidget {
  final bool isLoading;
  final bool hasData;
  final Widget child;
  final double initialMinHeight;
  final BorderRadius borderRadius;
  final Widget? initialPlaceholder;
  final bool blockInteraction;

  const SmoothLoadingWrapper({
    super.key,
    required this.isLoading,
    this.hasData = true,
    required this.child,
    this.initialMinHeight = 360,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.initialPlaceholder,
    this.blockInteraction = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasData) {
      if (initialPlaceholder != null) {
        return initialPlaceholder!;
      }

      final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
      final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
      final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
      final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

      return LayoutBuilder(
        builder: (context, constraints) {
          final effectiveMinHeight = constraints.hasBoundedHeight
              ? initialMinHeight.clamp(0.0, constraints.maxHeight)
              : initialMinHeight;

          return Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: effectiveMinHeight),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đang tải dữ liệu...',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        IgnorePointer(
          ignoring: blockInteraction && isLoading,
          child: AnimatedOpacity(
            opacity: isLoading ? 0.55 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: child,
          ),
        ),
        if (isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: borderRadius.topLeft),
              child: const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Phiên bản nâng cấp của [FutureBuilder] có lưu cache dữ liệu lần gần nhất.
/// Khi [future] được gán lại lúc tải lại dữ liệu, `snapshot.data` cũ vẫn được giữ nguyên
/// (`snapshot.hasData == true`) trong khi `snapshot.connectionState == ConnectionState.waiting`
/// để tránh xóa trắng giao diện giữa các nhịp click.
class CachedFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;

  const CachedFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
  });

  @override
  State<CachedFutureBuilder<T>> createState() => _CachedFutureBuilderState<T>();
}

class _CachedFutureBuilderState<T> extends State<CachedFutureBuilder<T>> {
  Future<T>? _subscribedFuture;
  T? _cachedData;
  bool _hasCachedValue = false;
  bool _isLoading = true;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.future);
  }

  @override
  void didUpdateWidget(covariant CachedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.future, _subscribedFuture)) {
      _subscribe(widget.future);
    }
  }

  void _subscribe(Future<T> future) {
    _subscribedFuture = future;
    _isLoading = true;
    _error = null;
    _stackTrace = null;

    future.then(
      (value) {
        if (!mounted || !identical(future, _subscribedFuture)) return;
        setState(() {
          _cachedData = value;
          _hasCachedValue = value != null;
          _isLoading = false;
          _error = null;
          _stackTrace = null;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || !identical(future, _subscribedFuture)) return;
        setState(() {
          _isLoading = false;
          _error = error;
          _stackTrace = stackTrace;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = _isLoading ? ConnectionState.waiting : ConnectionState.done;
    final AsyncSnapshot<T> snapshot;
    if (_error != null && !_hasCachedValue) {
      snapshot = AsyncSnapshot<T>.withError(connectionState, _error!, _stackTrace ?? StackTrace.empty);
    } else if (_hasCachedValue) {
      snapshot = AsyncSnapshot<T>.withData(connectionState, _cachedData as T);
    } else {
      snapshot = AsyncSnapshot<T>.nothing().inState(connectionState);
    }
    return widget.builder(context, snapshot);
  }
}
