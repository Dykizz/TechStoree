import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/survey.dart';
import '../../../core/models/voucher.dart';

/// Độ dài tối đa cho tiêu đề bài khảo sát (khớp `[MaxLength(255)]` ở API).
const int kMaxSurveyTitleLength = 255;

/// Độ dài tối đa cho nội dung một đáp án trắc nghiệm (khớp `[MaxLength(255)]` ở API).
const int kMaxSurveyOptionLength = 255;

final NumberFormat _voucherDiscountFormat = NumberFormat('#,##0.##', 'en_US');

/// So sánh hai mốc thời gian theo cùng instant UTC thay vì so sánh múi giờ.
bool sameSurveyMoment(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.isAtSameMomentAs(b);
}

/// Kiểm tra xem trong cùng câu hỏi có đáp án khác trùng nội dung hay không.
bool isDuplicateSurveyOptionText(
  SurveyQuestionDraft question,
  int optionIndex,
  String? rawValue,
) {
  final normalized = (rawValue ?? '').trim().toLowerCase();
  if (normalized.isEmpty) return false;
  for (int i = 0; i < question.options.length; i++) {
    if (i != optionIndex &&
        question.options[i].textCtrl.text.trim().toLowerCase() == normalized) {
      return true;
    }
  }
  return false;
}

/// Kiểm tra voucher đã hết hạn dựa theo `status` hoặc `endDate`.
bool isSurveyVoucherExpired(Voucher v) =>
    v.status == 'EXPIRED' || v.endDate.isBefore(DateTime.now());

/// Kiểm tra voucher không khả dụng để cấp mới (đang tắt hoặc hết hạn).
bool isSurveyVoucherUnavailable(Voucher v) =>
    !v.isActive || isSurveyVoucherExpired(v);

/// Định dạng nhãn hiển thị voucher trong dropdown và hộp thoại xem trước.
String formatSurveyVoucherLabel(Voucher v) {
  final formattedVal = _voucherDiscountFormat.format(v.discountValue);
  final discountText =
      v.isPercentage ? 'Giảm $formattedVal%' : 'Giảm $formattedValđ';
  String statusTag = '';
  if (!v.isActive) {
    statusTag = ' [Đang tắt]';
  } else if (isSurveyVoucherExpired(v)) {
    statusTag = ' [Hết hạn]';
  } else if (v.status == 'UPCOMING') {
    statusTag = ' [Chưa bắt đầu]';
  }
  return '${v.code} - ${v.title} ($discountText)$statusTag';
}

/// Trạng thái soạn thảo tạm của một câu hỏi trên form khảo sát.
class SurveyQuestionDraft {
  final int localId;
  final GlobalKey cardKey = GlobalKey();
  final int? questionId;
  final TextEditingController textCtrl;
  SurveyQuestionType type;
  bool isRequired;
  List<SurveyOptionDraft> options;

  SurveyQuestionDraft({
    required this.localId,
    this.questionId,
    required this.textCtrl,
    required this.type,
    required this.isRequired,
    required this.options,
  });

  void dispose() {
    textCtrl.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

/// Trạng thái soạn thảo tạm của một đáp án trắc nghiệm.
class SurveyOptionDraft {
  final TextEditingController textCtrl;

  SurveyOptionDraft({required this.textCtrl});

  void dispose() {
    textCtrl.dispose();
  }
}

