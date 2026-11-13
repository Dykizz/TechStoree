import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/survey.dart';
import '../../../core/models/voucher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_toast.dart';
import '../dialog/survey_customer_preview_dialog.dart';
import '../survey_helpers.dart';
import 'survey_editor_bars.dart';
import 'survey_editor_drafts.dart';
import 'survey_editor_info_card.dart';
import 'survey_editor_questions_section.dart';

/// Màn hình tạo mới hoặc chỉnh sửa bài khảo sát và danh sách câu hỏi động.
class SurveyEditorView extends StatefulWidget {
  final SurveyAdminDetail? existingSurvey;
  final String backLabel;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const SurveyEditorView({
    super.key,
    this.existingSurvey,
    this.backLabel = 'Quay lại danh sách',
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<SurveyEditorView> createState() => _SurveyEditorViewState();
}

class _SurveyEditorViewState extends State<SurveyEditorView> {
  final _formKey = GlobalKey<FormState>();
  final _generalSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  int? _selectedRewardVoucherId;
  bool _isActive = true;
  DateTime? _startAt;
  DateTime? _expiredAt;
  bool _isSubmitting = false;

  List<Voucher> _availableVouchers = [];
  bool _isLoadingVouchers = false;
  String? _voucherLoadError;

  late List<SurveyQuestionDraft> _questionDrafts;
  int? _focusedQuestionIndex;
  int _nextQuestionLocalId = 0;

  bool get isEditing => widget.existingSurvey != null;
  bool get hasResponses => widget.existingSurvey?.hasResponses ?? false;

  @override
  void initState() {
    super.initState();
    _initDraftsFromSurvey(widget.existingSurvey);
    _fetchVouchers();
  }

  @override
  void didUpdateWidget(covariant SurveyEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingSurvey?.surveyId != oldWidget.existingSurvey?.surveyId) {
      final oldTitleCtrl = _titleCtrl;
      final oldDescCtrl = _descCtrl;
      final oldDrafts = List<SurveyQuestionDraft>.from(_questionDrafts);
      _initDraftsFromSurvey(widget.existingSurvey);
      _disposePostFrame(() {
        oldTitleCtrl.dispose();
        oldDescCtrl.dispose();
        for (final q in oldDrafts) {
          q.dispose();
        }
      });
    }
  }

  void _initDraftsFromSurvey(SurveyAdminDetail? existing) {
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _selectedRewardVoucherId = existing?.rewardVoucherId;
    _isActive = existing?.isActive ?? true;
    _startAt = existing?.startAt;
    _expiredAt = existing?.expiredAt;
    _focusedQuestionIndex = null;

    if (existing != null && existing.questions.isNotEmpty) {
      _questionDrafts = existing.questions.map((q) {
        return SurveyQuestionDraft(
          localId: _nextQuestionLocalId++,
          questionId: q.questionId,
          textCtrl: TextEditingController(text: q.questionText),
          type: q.questionType,
          isRequired: q.isRequired,
          options: q.options
              .map((o) => SurveyOptionDraft(textCtrl: TextEditingController(text: o.optionText)))
              .toList(),
        );
      }).toList();
    } else {
      _questionDrafts = [
        SurveyQuestionDraft(
          localId: _nextQuestionLocalId++,
          textCtrl: TextEditingController(),
          type: SurveyQuestionType.SINGLE_CHOICE,
          isRequired: true,
          options: [
            SurveyOptionDraft(textCtrl: TextEditingController()),
            SurveyOptionDraft(textCtrl: TextEditingController()),
          ],
        ),
      ];
    }
  }

  void _disposeControllers() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final q in _questionDrafts) {
      q.dispose();
    }
  }

  void _disposePostFrame(VoidCallback disposeFn) {
    WidgetsBinding.instance.addPostFrameCallback((_) => disposeFn());
  }

  Future<void> _fetchVouchers() async {
    setState(() {
      _isLoadingVouchers = true;
      _voucherLoadError = null;
    });
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final vouchers = await apiService.getAllVouchers(token: token, throwOnError: true);
      if (mounted) {
        setState(() {
          _availableVouchers = vouchers;
          _isLoadingVouchers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _voucherLoadError = extractFriendlySurveyError(
            e,
            fallback: 'Không thể tải danh sách voucher.',
          );
          _isLoadingVouchers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    final existing = widget.existingSurvey;
    if (existing == null) {
      if (_titleCtrl.text.isNotEmpty ||
          _descCtrl.text.isNotEmpty ||
          _selectedRewardVoucherId != null ||
          !_isActive ||
          _startAt != null ||
          _expiredAt != null ||
          _questionDrafts.length != 1) {
        return true;
      }
      final first = _questionDrafts.first;
      return first.textCtrl.text.isNotEmpty ||
          first.type != SurveyQuestionType.SINGLE_CHOICE ||
          !first.isRequired ||
          first.options.length != 2 ||
          first.options.any((o) => o.textCtrl.text.isNotEmpty);
    }

    if (_titleCtrl.text != existing.title ||
        _descCtrl.text != (existing.description ?? '') ||
        _selectedRewardVoucherId != existing.rewardVoucherId ||
        _isActive != existing.isActive ||
        !sameSurveyMoment(_startAt, existing.startAt) ||
        !sameSurveyMoment(_expiredAt, existing.expiredAt) ||
        _questionDrafts.length != existing.questions.length) {
      return true;
    }

    for (int i = 0; i < _questionDrafts.length; i++) {
      final d = _questionDrafts[i];
      final orig = existing.questions[i];
      if (d.textCtrl.text != orig.questionText ||
          d.type != orig.questionType ||
          d.isRequired != orig.isRequired) {
        return true;
      }
      if (d.type.isChoiceBased) {
        if (d.options.length != orig.options.length) return true;
        for (int j = 0; j < d.options.length; j++) {
          if (d.options[j].textCtrl.text != orig.options[j].optionText) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _handleCancel() async {
    if (_isSubmitting) return;
    if (!_hasUnsavedChanges()) {
      widget.onCancel();
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ các thay đổi chưa lưu?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn đã chỉnh sửa nội dung bài khảo sát nhưng chưa lưu. Nếu thoát bây giờ, các thay đổi sẽ bị mất.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      widget.onCancel();
    }
  }

  void _scrollToKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  void _openPreview() {
    final selectedVoucher = _availableVouchers.cast<Voucher?>().firstWhere(
          (v) => v?.voucherId == _selectedRewardVoucherId,
          orElse: () => widget.existingSurvey?.rewardVoucher?.voucherId == _selectedRewardVoucherId
              ? widget.existingSurvey?.rewardVoucher
              : null,
        );
    showSurveyCustomerPreviewDialog(
      context,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      rewardVoucher: selectedVoucher,
      startAt: _startAt,
      expiredAt: _expiredAt,
      questions: _questionDrafts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SurveyEditorPageHeader(
                    backLabel: widget.backLabel,
                    isEditing: isEditing,
                    surveyId: widget.existingSurvey?.surveyId,
                    isSubmitting: _isSubmitting,
                    onPreview: _openPreview,
                    onCancel: _handleCancel,
                    onSubmit: _submitForm,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 20),
                  if (hasResponses) ...[
                    SurveyEditorRespondedNotice(textPrimary: textPrimary),
                    const SizedBox(height: 20),
                  ],
                  KeyedSubtree(
                    key: _generalSectionKey,
                    child: SurveyEditorInfoCard(
                      titleCtrl: _titleCtrl,
                      descCtrl: _descCtrl,
                      existingSurvey: widget.existingSurvey,
                      hasResponses: hasResponses,
                      availableVouchers: _availableVouchers,
                      isLoadingVouchers: _isLoadingVouchers,
                      voucherLoadError: _voucherLoadError,
                      selectedRewardVoucherId: _selectedRewardVoucherId,
                      onVoucherChanged: (val) => setState(() => _selectedRewardVoucherId = val),
                      onRetryLoadVouchers: _fetchVouchers,
                      isActive: _isActive,
                      onActiveChanged: (val) => setState(() => _isActive = val),
                      startAt: _startAt,
                      onStartAtChanged: (val) => setState(() => _startAt = val),
                      expiredAt: _expiredAt,
                      onExpiredAtChanged: (val) => setState(() => _expiredAt = val),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SurveyEditorQuestionsSection(
                    questions: _questionDrafts,
                    hasResponses: hasResponses,
                    focusedQuestionIndex: _focusedQuestionIndex,
                    onAddQuestion: _addQuestion,
                    onReorderQuestions: _reorderQuestions,
                    onQuestionFocusChange: (index, hasFocus) {
                      if (hasFocus && _focusedQuestionIndex != index) {
                        setState(() => _focusedQuestionIndex = index);
                      }
                    },
                    onQuestionRequiredChanged: (index, val) => setState(() => _questionDrafts[index].isRequired = val),
                    onQuestionTypeChanged: (index, val) {
                      final q = _questionDrafts[index];
                      setState(() {
                        q.type = val;
                        if (val.isChoiceBased && q.options.isEmpty) {
                          q.options = [
                            SurveyOptionDraft(textCtrl: TextEditingController()),
                            SurveyOptionDraft(textCtrl: TextEditingController()),
                          ];
                        }
                      });
                    },
                    onDuplicateQuestion: _duplicateQuestion,
                    onMoveQuestion: _moveQuestion,
                    onDeleteQuestion: _removeQuestion,
                    onAddOption: _addOption,
                    onMoveOption: _moveOption,
                    onRemoveOption: _removeOption,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SurveyEditorBottomBar(
            isEditing: isEditing,
            isSubmitting: _isSubmitting,
            onPreview: _openPreview,
            onCancel: _handleCancel,
            onSubmit: _submitForm,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  void _addQuestion() {
    setState(() {
      _questionDrafts.add(
        SurveyQuestionDraft(
          localId: _nextQuestionLocalId++,
          textCtrl: TextEditingController(),
          type: SurveyQuestionType.SINGLE_CHOICE,
          isRequired: true,
          options: [
            SurveyOptionDraft(textCtrl: TextEditingController()),
            SurveyOptionDraft(textCtrl: TextEditingController()),
          ],
        ),
      );
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      final item = _questionDrafts.removeAt(oldIndex);
      _questionDrafts.insert(newIndex, item);
      if (_focusedQuestionIndex == oldIndex) {
        _focusedQuestionIndex = newIndex;
      } else if (_focusedQuestionIndex != null) {
        if (oldIndex < _focusedQuestionIndex! && newIndex >= _focusedQuestionIndex!) {
          _focusedQuestionIndex = _focusedQuestionIndex! - 1;
        } else if (oldIndex > _focusedQuestionIndex! && newIndex <= _focusedQuestionIndex!) {
          _focusedQuestionIndex = _focusedQuestionIndex! + 1;
        }
      }
    });
  }

  void _removeQuestion(int index) {
    final removed = _questionDrafts[index];
    setState(() {
      _questionDrafts.removeAt(index);
      if (_focusedQuestionIndex == index) {
        _focusedQuestionIndex = null;
      } else if (_focusedQuestionIndex != null && _focusedQuestionIndex! > index) {
        _focusedQuestionIndex = _focusedQuestionIndex! - 1;
      }
    });
    _disposePostFrame(removed.dispose);
  }

  void _duplicateQuestion(int index) {
    final orig = _questionDrafts[index];
    setState(() {
      _questionDrafts.insert(
        index + 1,
        SurveyQuestionDraft(
          localId: _nextQuestionLocalId++,
          textCtrl: TextEditingController(text: '${orig.textCtrl.text} (Bản sao)'),
          type: orig.type,
          isRequired: orig.isRequired,
          options: orig.options
              .map((o) => SurveyOptionDraft(textCtrl: TextEditingController(text: o.textCtrl.text)))
              .toList(),
        ),
      );
    });
  }

  void _moveQuestion(int index, int delta) {
    setState(() {
      final item = _questionDrafts.removeAt(index);
      _questionDrafts.insert(index + delta, item);
    });
  }

  void _addOption(SurveyQuestionDraft q) {
    setState(() {
      q.options.add(SurveyOptionDraft(textCtrl: TextEditingController()));
    });
  }

  void _removeOption(SurveyQuestionDraft q, int index) {
    final removed = q.options[index];
    setState(() {
      q.options.removeAt(index);
    });
    _disposePostFrame(removed.dispose);
  }

  void _moveOption(SurveyQuestionDraft q, int index, int delta) {
    setState(() {
      final item = q.options.removeAt(index);
      q.options.insert(index + delta, item);
    });
  }

  void _scrollToFirstValidationIssue() {
    final titleText = _titleCtrl.text.trim();
    if (titleText.isEmpty || titleText.length > kMaxSurveyTitleLength) {
      _scrollToKey(_generalSectionKey);
      return;
    }

    for (final q in _questionDrafts) {
      if (q.textCtrl.text.trim().isEmpty) {
        _scrollToKey(q.cardKey);
        return;
      }
      if (q.type.isChoiceBased) {
        for (int optIdx = 0; optIdx < q.options.length; optIdx++) {
          final optText = q.options[optIdx].textCtrl.text.trim();
          if (optText.isEmpty ||
              optText.length > kMaxSurveyOptionLength ||
              isDuplicateSurveyOptionText(q, optIdx, optText)) {
            _scrollToKey(q.cardKey);
            return;
          }
        }
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstValidationIssue();
      AppToast.warning(context, 'Vui lòng kiểm tra lại các trường thông tin được đánh dấu!');
      return;
    }

    if (_questionDrafts.isEmpty) {
      AppToast.warning(context, 'Bài khảo sát phải có ít nhất 1 câu hỏi!');
      return;
    }

    for (int i = 0; i < _questionDrafts.length; i++) {
      final q = _questionDrafts[i];
      if (q.type.isChoiceBased) {
        final validOpts = q.options.where((o) => o.textCtrl.text.trim().isNotEmpty).toList();
        if (validOpts.length < 2) {
          _scrollToKey(q.cardKey);
          final typeName = q.type == SurveyQuestionType.MULTI_CHOICE
              ? 'Trắc nghiệm nhiều đáp án'
              : 'Trắc nghiệm';
          AppToast.warning(context, 'Câu ${i + 1} ($typeName) phải có ít nhất 2 đáp án!');
          return;
        }
        final normalizedOpts = validOpts.map((o) => o.textCtrl.text.trim().toLowerCase()).toSet();
        if (normalizedOpts.length < validOpts.length) {
          _scrollToKey(q.cardKey);
          AppToast.warning(context, 'Câu ${i + 1} có các đáp án trùng nội dung. Vui lòng chỉnh sửa!');
          return;
        }
      }
    }

    final isExpiredChanged = !isEditing || !sameSurveyMoment(_expiredAt, widget.existingSurvey?.expiredAt);
    if (_expiredAt != null && isExpiredChanged && !_expiredAt!.isAfter(DateTime.now())) {
      _scrollToKey(_generalSectionKey);
      AppToast.warning(context, 'Hạn chót kết thúc phải lớn hơn thời điểm hiện tại!');
      return;
    }

    if (_startAt != null && _expiredAt != null && !_expiredAt!.isAfter(_startAt!)) {
      _scrollToKey(_generalSectionKey);
      AppToast.warning(context, 'Hạn chót kết thúc phải lớn hơn thời điểm bắt đầu mở khảo sát!');
      return;
    }

    setState(() => _isSubmitting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final questionDtos = _questionDrafts.asMap().entries.map((qEntry) {
      final qIdx = qEntry.key;
      final qDraft = qEntry.value;

      List<CreateSurveyOption>? optionDtos;
      if (qDraft.type.isChoiceBased) {
        optionDtos = qDraft.options.asMap().entries.map((oEntry) {
          return CreateSurveyOption(
            optionText: oEntry.value.textCtrl.text.trim(),
            orderNum: oEntry.key + 1,
          );
        }).toList();
      }

      return CreateSurveyQuestion(
        questionText: qDraft.textCtrl.text.trim(),
        questionType: qDraft.type,
        isRequired: qDraft.isRequired,
        orderNum: qIdx + 1,
        options: optionDtos,
      );
    }).toList();

    ApiResult res;
    if (isEditing) {
      final req = UpdateSurveyRequest(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        rewardVoucherId: _selectedRewardVoucherId,
        isActive: _isActive,
        startAt: _startAt,
        expiredAt: _expiredAt,
        questions: hasResponses ? null : questionDtos,
      );
      res = await apiService.updateSurvey(widget.existingSurvey!.surveyId, req, token: token);
    } else {
      final req = CreateSurveyRequest(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        rewardVoucherId: _selectedRewardVoucherId,
        isActive: _isActive,
        startAt: _startAt,
        expiredAt: _expiredAt,
        questions: questionDtos,
      );
      res = await apiService.createSurvey(req, token: token);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res.success) {
        widget.onSuccess();
        AppToast.success(context, res.message.isNotEmpty ? res.message : 'Lưu khảo sát thành công!');
      } else {
        AppToast.error(context, res.message.isNotEmpty ? res.message : 'Lưu khảo sát thất bại!');
      }
    }
  }
}

