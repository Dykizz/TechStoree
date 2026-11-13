import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state.dart';

/// Builds a full-pane fallback view with a back header and centered [EmptyState].
Widget buildSurveyFallbackView({
  required String headerTitle,
  required Color textPrimary,
  required VoidCallback onBack,
  required IconData icon,
  required String title,
  String? message,
  Widget? action,
}) {
  return Padding(
    padding: const EdgeInsets.all(AppTokens.space16),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
            const SizedBox(width: 8),
            Text(
              headerTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
          ],
        ),
        Expanded(
          child: EmptyState(
            icon: icon,
            title: title,
            message: message,
            action: action,
          ),
        ),
      ],
    ),
  );
}

/// Builds a compact inline danger banner with a retry/reload action button.
Widget buildSurveyErrorBanner({
  required Object? error,
  required VoidCallback onRetry,
  String actionLabel = 'Tải lại',
  EdgeInsetsGeometry? margin,
  bool fullBorder = true,
  int? maxLines,
}) {
  final borderColor = AppColors.danger.withValues(alpha: 0.25);
  return Container(
    margin: margin,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: fullBorder ? BorderRadius.circular(8) : null,
      border: fullBorder
          ? Border.all(color: borderColor)
          : Border(bottom: BorderSide(color: borderColor)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            extractFriendlySurveyError(error),
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

/// Chuẩn hóa thông báo lỗi hiển thị cho người dùng từ Exception/Future error.
String extractFriendlySurveyError(
  Object? error, {
  String fallback = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.',
}) {
  if (error == null) return fallback;
  var msg = error.toString().trim();
  const prefix = 'Exception:';
  if (msg.startsWith(prefix)) {
    msg = msg.substring(prefix.length).trim();
  }
  return msg.isNotEmpty ? msg : fallback;
}

/// Xuất báo cáo CSV dùng chung cho Danh sách, Chi tiết và Thống kê khảo sát.
/// Nếu người dùng chủ động nhấn Hủy trên hộp thoại lưu file thì dừng im lặng thay vì tự ghi file.
Future<void> exportSurveyCsvReport({
  required BuildContext context,
  required int surveyId,
  required ApiService apiService,
  required String? token,
}) async {
  try {
    final (bytes, filename) = await apiService.exportSurveyCsv(surveyId, token: token);
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      final errMsg = apiService.lastErrorMessage.isNotEmpty
          ? apiService.lastErrorMessage
          : 'Không thể tải báo cáo khảo sát.';
      AppToast.error(context, errMsg);
      return;
    }

    String? targetPath;
    bool pickerFailed = false;

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Chọn nơi lưu báo cáo kết quả khảo sát CSV',
        fileName: filename,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savedUri == null) {
        // Người dùng chủ động bấm Cancel trên hộp thoại lưu file
        return;
      }
      final file = File.fromUri(savedUri);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
      targetPath = file.path;
    } catch (pickerErr) {
      pickerFailed = true;
      debugPrint('FilePicker error: $pickerErr');
    }

    if (pickerFailed && targetPath == null) {
      final baseHome = Platform.isWindows
          ? (Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public')
          : (Platform.environment['HOME'] ?? Directory.systemTemp.path);
      final sep = Platform.pathSeparator;
      final downloadsDir = Directory('$baseHome${sep}Downloads');
      final saveDir = await downloadsDir.exists() ? downloadsDir.path : baseHome;
      final fallbackFile = File('$saveDir$sep$filename');
      await fallbackFile.writeAsBytes(bytes);
      targetPath = fallbackFile.path;
    }

    if (!context.mounted) return;
    if (targetPath != null) {
      AppToast.success(context, 'Đã xuất file báo cáo thành công: $filename (lưu tại $targetPath)');
    }
  } catch (e) {
    if (!context.mounted) return;
    AppToast.error(context, 'Lỗi khi xuất file báo cáo: $e');
  }
}

