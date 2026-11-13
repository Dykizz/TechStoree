import 'package:flutter/material.dart';
import '../../../core/models/survey.dart';
import '../../../core/utils/app_date_formatter.dart';

/// Khung hiển thị danh sách ý kiến tự luận kèm tìm kiếm và mở rộng/thu gọn.
class SurveyResultTextAnswersPanel extends StatefulWidget {
  final int questionId;
  final List<TextAnswer> textAnswers;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const SurveyResultTextAnswersPanel({
    super.key,
    required this.questionId,
    required this.textAnswers,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<SurveyResultTextAnswersPanel> createState() => _SurveyResultTextAnswersPanelState();
}

class _SurveyResultTextAnswersPanelState extends State<SurveyResultTextAnswersPanel> {
  static const int _initialVisibleTextAnswers = 5;

  final TextEditingController _textSearchCtrl = TextEditingController();
  String _textSearchQuery = '';
  bool _showAllTextAnswers = false;

  @override
  void didUpdateWidget(covariant SurveyResultTextAnswersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionId != widget.questionId) {
      _textSearchQuery = '';
      _textSearchCtrl.clear();
      _showAllTextAnswers = false;
    }
  }

  @override
  void dispose() {
    _textSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.textAnswers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Chưa có ý kiến phản hồi nào cho câu tự luận này.',
            style: TextStyle(fontSize: 12, color: widget.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final query = _textSearchQuery.trim().toLowerCase();
    final filteredAnswers = query.isEmpty
        ? widget.textAnswers
        : widget.textAnswers
            .where(
              (item) =>
                  item.customerName.toLowerCase().contains(query) ||
                  item.text.toLowerCase().contains(query),
            )
            .toList();

    final showSearch = widget.textAnswers.length > 3;
    final canToggleExpand = query.isEmpty && filteredAnswers.length > _initialVisibleTextAnswers;
    final visibleAnswers = (canToggleExpand && !_showAllTextAnswers)
        ? filteredAnswers.take(_initialVisibleTextAnswers).toList()
        : filteredAnswers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearch) ...[
          TextField(
            controller: _textSearchCtrl,
            style: TextStyle(fontSize: 12, color: widget.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tìm theo tên khách hàng hoặc nội dung phản hồi...',
              hintStyle: TextStyle(fontSize: 12, color: widget.textSecondary),
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: widget.textSecondary),
              suffixIcon: _textSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 15, color: widget.textSecondary),
                      tooltip: 'Xóa từ khóa',
                      onPressed: () {
                        _textSearchCtrl.clear();
                        setState(() => _textSearchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: widget.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: widget.borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: (val) => setState(() => _textSearchQuery = val),
          ),
          const SizedBox(height: 10),
        ],
        if (visibleAnswers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'Không tìm thấy phản hồi phù hợp với từ khóa.',
                style: TextStyle(fontSize: 12, color: widget.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                for (int idx = 0; idx < visibleAnswers.length; idx++) ...[
                  if (idx > 0) Divider(height: 1, color: widget.borderColor.withValues(alpha: 0.5)),
                  _buildTextAnswerItem(visibleAnswers[idx]),
                ],
              ],
            ),
          ),
        if (canToggleExpand) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showAllTextAnswers = !_showAllTextAnswers),
              icon: Icon(
                _showAllTextAnswers ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 16,
              ),
              label: Text(
                _showAllTextAnswers
                    ? 'Thu gọn danh sách'
                    : 'Xem tất cả (${filteredAnswers.length} phản hồi)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextAnswerItem(TextAnswer item) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 16, color: widget.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.customerName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppDateFormatter.formatDateTime(item.submittedAt),
                style: TextStyle(fontSize: 11, color: widget.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.text, style: TextStyle(fontSize: 12, color: widget.textPrimary)),
          ),
        ],
      ),
    );
  }
}

