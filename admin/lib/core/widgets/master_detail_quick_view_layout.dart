import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_tokens.dart';

/// Bố cục Master-Detail 2 cột (Desktop) / xếp dọc (Compact) tự đo chiều cao
/// phần đầu trang, bảng trái và vị trí cuộn để khung Quick View mở rộng tối đa
/// khoảng trống khả dụng mà vẫn giữ nút hành động trong tầm mắt.
class MasterDetailQuickViewLayout extends StatefulWidget {
  final Widget headerSection;
  final Widget leftTable;
  final Widget rightPanel;
  final bool hasSelection;
  final double initialHeaderHeight;
  final EdgeInsetsGeometry padding;
  final double placeholderMaxHeight;
  final Widget Function(Widget child)? bodyWrapper;

  const MasterDetailQuickViewLayout({
    super.key,
    required this.headerSection,
    required this.leftTable,
    required this.rightPanel,
    required this.hasSelection,
    this.initialHeaderHeight = 220.0,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.placeholderMaxHeight = 380.0,
    this.bodyWrapper,
  });

  @override
  State<MasterDetailQuickViewLayout> createState() =>
      _MasterDetailQuickViewLayoutState();
}

class _MasterDetailQuickViewLayoutState
    extends State<MasterDetailQuickViewLayout> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _leftTableKey = GlobalKey();

  late double _headerHeight = widget.initialHeaderHeight;
  double _tableHeight = 0.0;
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(covariant MasterDetailQuickViewLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasurement();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleMeasurement() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final headerBox =
          _headerKey.currentContext?.findRenderObject() as RenderBox?;
      final tableBox =
          _leftTableKey.currentContext?.findRenderObject() as RenderBox?;
      final nextHeader = (headerBox != null && headerBox.hasSize)
          ? headerBox.size.height
          : _headerHeight;
      final nextTable = (tableBox != null && tableBox.hasSize)
          ? tableBox.size.height
          : _tableHeight;

      if ((nextHeader - _headerHeight).abs() > 2.0 ||
          (nextTable - _tableHeight).abs() > 2.0) {
        setState(() {
          _headerHeight = nextHeader;
          _tableHeight = nextTable;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = widget.padding.resolve(Directionality.of(context));

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final viewportHeight = viewportConstraints.hasBoundedHeight
            ? viewportConstraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        _scheduleMeasurement();

        final masterDetailContent = LayoutBuilder(
          builder: (context, contentConstraints) {
            final isCompact = contentConstraints.maxWidth < 680;
            final panelWidth = contentConstraints.maxWidth > 1350
                ? 450.0
                : (contentConstraints.maxWidth > 1050 ? 415.0 : 380.0);

            final measuredLeftTable = KeyedSubtree(
              key: _leftTableKey,
              child: widget.leftTable,
            );

            if (isCompact) {
              if (!widget.hasSelection) {
                return measuredLeftTable;
              }
              final compactMaxHeight = math.max(
                360.0,
                viewportHeight - resolvedPadding.vertical,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  measuredLeftTable,
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: compactMaxHeight),
                    child: widget.rightPanel,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: measuredLeftTable),
                const SizedBox(width: 14),
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, panelChild) {
                    final scrollOffset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    final rowTopAtZero = resolvedPadding.top + _headerHeight;
                    final bottomMargin = resolvedPadding.bottom;
                    final minPanelHeight = math.min(
                      340.0,
                      math.max(200.0, viewportHeight - resolvedPadding.vertical),
                    );

                    final unscrolledRoom = math.max(
                      minPanelHeight,
                      viewportHeight - rowTopAtZero - bottomMargin,
                    );
                    final visibleRowTop = math.max(
                      resolvedPadding.top,
                      rowTopAtZero - scrollOffset,
                    );
                    final roomInViewport = math.max(
                      minPanelHeight,
                      viewportHeight - visibleRowTop - bottomMargin,
                    );
                    // Giữ tổng chiều cao Row không vượt ngưỡng ban đầu của bảng để tránh vòng lặp tăng scrollExtent.
                    final scrollCap = math.max(unscrolledRoom, _tableHeight);
                    final panelMaxHeight = widget.hasSelection
                        ? math.min(roomInViewport, scrollCap)
                        : math.min(widget.placeholderMaxHeight, unscrolledRoom);

                    if (!widget.hasSelection) {
                      return SizedBox(
                        width: panelWidth,
                        height: panelMaxHeight,
                        child: panelChild,
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: panelWidth,
                        maxWidth: panelWidth,
                        maxHeight: panelMaxHeight,
                      ),
                      child: panelChild,
                    );
                  },
                  child: widget.rightPanel,
                ),
              ],
            );
          },
        );

        final wrappedBody = widget.bodyWrapper != null
            ? widget.bodyWrapper!(masterDetailContent)
            : masterDetailContent;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(
                key: _headerKey,
                child: widget.headerSection,
              ),
              wrappedBody,
            ],
          ),
        );
      },
    );
  }
}

