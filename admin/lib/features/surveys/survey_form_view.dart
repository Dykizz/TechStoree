import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/survey.dart';
import '../../core/models/voucher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';

class SurveyFormView extends StatefulWidget {
  final SurveyAdminDetail? existingSurvey;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const SurveyFormView({
    super.key,
    this.existingSurvey,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<SurveyFormView> createState() => _SurveyFormViewState();
}

class _SurveyFormViewState extends State<SurveyFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  int? _selectedRewardVoucherId;
  bool _isActive = true;
  bool _isSubmitting = false;

  List<Voucher> _availableVouchers = [];
  bool _isLoadingVouchers = false;

  late List<_QuestionDraft> _questionDrafts;
  int? _focusedQuestionIndex;

  bool get isEditing => widget.existingSurvey != null;
  bool get hasResponses => widget.existingSurvey?.hasResponses ?? false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSurvey;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _selectedRewardVoucherId = existing?.rewardVoucherId;
    _isActive = existing?.isActive ?? true;

    if (existing != null && existing.questions.isNotEmpty) {
      _questionDrafts = existing.questions.map((q) {
        return _QuestionDraft(
          questionId: q.questionId,
          textCtrl: TextEditingController(text: q.questionText),
          type: q.questionType,
          isRequired: q.isRequired,
          options: q.options.map((o) => _OptionDraft(textCtrl: TextEditingController(text: o.optionText))).toList(),
        );
      }).toList();
    } else {
      _questionDrafts = [
        _QuestionDraft(
          textCtrl: TextEditingController(text: ''),
          type: SurveyQuestionType.SINGLE_CHOICE,
          isRequired: true,
          options: [
            _OptionDraft(textCtrl: TextEditingController(text: '')),
            _OptionDraft(textCtrl: TextEditingController(text: '')),
          ],
        ),
      ];
    }

    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoadingVouchers = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final vouchers = await apiService.getVouchers(token: token);
      if (mounted) {
        setState(() {
          _availableVouchers = vouchers;
          _isLoadingVouchers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVouchers = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (var q in _questionDrafts) {
      q.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAGE HEADER (Section 4)
            _buildPageHeader(isDark, textPrimary, textSecondary),
            const SizedBox(height: 20),

            // HAS RESPONSES NOTICE (Section 18)
            if (hasResponses) ...[
              _buildRespondedNotice(textPrimary),
              const SizedBox(height: 20),
            ],

            // GENERAL INFORMATION SECTION (Section 5)
            _buildGeneralInfoSection(isDark, cardBg, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 24),

            // QUESTIONS SECTION HEADER (Section 6)
            _buildQuestionsSectionHeader(textPrimary, textSecondary),
            const SizedBox(height: 12),

            // QUESTION CARDS (Section 7-12)
            ..._questionDrafts.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              return _buildQuestionCardItem(idx, q, isDark, cardBg, borderColor, textPrimary, textSecondary);
            }),

            const SizedBox(height: 16),

            // BOTTOM SAVE/CANCEL ACTION BAR (Sticky context)
            _buildBottomActionBar(isDark, cardBg, borderColor, textPrimary),
          ],
        ),
      ),
    );
  }

  // Section 4: Page Header Refactored
  Widget _buildPageHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onCancel,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Quay lại danh sách',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Chỉnh sửa bài khảo sát' : 'Tạo bài khảo sát mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEditing ? 'Khảo sát #${widget.existingSurvey!.surveyId}' : 'Khởi tạo thông tin và danh sách câu hỏi',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Hủy',
              variant: AppButtonVariant.outline,
              onPressed: _isSubmitting ? null : widget.onCancel,
            ),
            const SizedBox(width: 10),
            AppButton(
              label: _isSubmitting ? 'Đang lưu...' : (isEditing ? 'Lưu thay đổi' : 'Tạo khảo sát'),
              icon: Icons.check_rounded,
              onPressed: _isSubmitting ? null : _submitForm,
            ),
          ],
        ),
      ],
    );
  }

  // Section 18: Compact Notice when Survey Has Responses
  Widget _buildRespondedNotice(Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_outlined, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Khảo sát đã có phản hồi. Cấu trúc câu hỏi không thể chỉnh sửa để bảo đảm tính toàn vẹn dữ liệu.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // Section 5: General Information Section
  Widget _buildGeneralInfoSection(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chung',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 14),

          // Title field (full width)
          AppTextField(
            controller: _titleCtrl,
            labelText: 'Tiêu đề khảo sát (*)',
            hintText: 'VD: Thăm dò nhu cầu tai nghe Sony WH-1000XM6...',
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Tiêu đề không được để trống!';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Description field (full width)
          AppTextField(
            controller: _descCtrl,
            labelText: 'Mô tả khảo sát',
            hintText: 'Nhập mô tả chi tiết chương trình khảo sát thị trường...',
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // Bottom row: Reward Voucher selector + Compact Accept Responses toggle
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final voucherWidget = _isLoadingVouchers
                  ? const SizedBox(height: 40, child: Center(child: LinearProgressIndicator(color: AppColors.primary)))
                  : AppDropdown<int?>(
                      value: _selectedRewardVoucherId,
                      labelText: 'Voucher thưởng khi hoàn thành',
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Không có phần thưởng', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                        ..._availableVouchers.map((v) {
                          return DropdownMenuItem<int?>(
                            value: v.voucherId,
                            child: Text(
                              '${v.code} - ${v.title} (${v.isPercentage ? "Giảm ${v.discountValue.toInt()}%" : "Giảm ${v.discountValue.toInt()}đ"})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedRewardVoucherId = val),
                    );

              final toggleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mở nhận phản hồi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isActive,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: voucherWidget),
                    const SizedBox(width: 24),
                    toggleWidget,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  voucherWidget,
                  const SizedBox(height: 12),
                  toggleWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Section 6: Questions Section Header
  Widget _buildQuestionsSectionHeader(Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu hỏi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            Text(
              '${_questionDrafts.length} câu hỏi',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
        const Spacer(),
        if (!hasResponses)
          AppButton(
            label: 'Thêm câu hỏi',
            icon: Icons.add_rounded,
            variant: AppButtonVariant.outline,
            onPressed: _addQuestion,
          ),
      ],
    );
  }

  // Section 7-12: Question Card Item
  Widget _buildQuestionCardItem(
    int index,
    _QuestionDraft q,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isFocused = _focusedQuestionIndex == index;

    return FocusScope(
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            setState(() => _focusedQuestionIndex = index);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused ? AppColors.primary : borderColor,
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QUESTION CARD HEADER (Section 8 & 9)
              Row(
                children: [
                  Icon(Icons.drag_indicator_rounded, size: 16, color: textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Câu ${index + 1}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const Spacer(),

                  // Section 9: Compact horizontal Required Toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bắt buộc',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: q.isRequired,
                        activeColor: AppColors.primary,
                        onChanged: hasResponses ? null : (val) => setState(() => q.isRequired = val),
                      ),
                    ],
                  ),

                  const SizedBox(width: 4),

                  // Section 8: Overflow Menu (⋯)
                  if (!hasResponses)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                      tooltip: 'Tùy chọn câu hỏi',
                      onSelected: (val) {
                        switch (val) {
                          case 'DUPLICATE':
                            _duplicateQuestion(index);
                            break;
                          case 'UP':
                            _moveQuestion(index, -1);
                            break;
                          case 'DOWN':
                            _moveQuestion(index, 1);
                            break;
                          case 'DELETE':
                            if (_questionDrafts.length > 1) {
                              _removeQuestion(index);
                            }
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'DUPLICATE',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 14),
                              SizedBox(width: 8),
                              Text('Nhân bản câu hỏi', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'UP',
                          enabled: index > 0,
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: 14),
                              SizedBox(width: 8),
                              Text('Di chuyển lên', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'DOWN',
                          enabled: index < _questionDrafts.length - 1,
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 14),
                              SizedBox(width: 8),
                              Text('Di chuyển xuống', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'DELETE',
                          enabled: _questionDrafts.length > 1,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 14, color: _questionDrafts.length > 1 ? AppColors.danger : Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Xóa câu hỏi',
                                style: TextStyle(fontSize: 12, color: _questionDrafts.length > 1 ? AppColors.danger : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // QUESTION MAIN FIELDS (Section 10)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 750;
                  final textInput = AppTextField(
                    controller: q.textCtrl,
                    readOnly: hasResponses,
                    labelText: 'Nội dung câu hỏi (*)',
                    hintText: 'VD: Mức giá bạn sẵn sàng chi trả cho sản phẩm là bao nhiêu?',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Nội dung câu hỏi không được để trống!';
                      return null;
                    },
                  );

                  final typeDropdown = AppDropdown<SurveyQuestionType>(
                    value: q.type,
                    labelText: 'Loại câu hỏi',
                    items: SurveyQuestionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: hasResponses
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                q.type = val;
                                if (val == SurveyQuestionType.SINGLE_CHOICE && q.options.isEmpty) {
                                  q.options = [
                                    _OptionDraft(textCtrl: TextEditingController()),
                                    _OptionDraft(textCtrl: TextEditingController()),
                                  ];
                                }
                              });
                            }
                          },
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: textInput),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: typeDropdown),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      textInput,
                      const SizedBox(height: 10),
                      typeDropdown,
                    ],
                  );
                },
              ),

              // OPTIONS EDITOR / TEXT HINT (Section 11 & 12)
              const SizedBox(height: 14),

              if (q.type == SurveyQuestionType.SINGLE_CHOICE) ...[
                Text(
                  'Lựa chọn đáp án',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                ),
                const SizedBox(height: 8),

                ...q.options.asMap().entries.map((optEntry) {
                  final optIdx = optEntry.key;
                  final opt = optEntry.value;
                  return _buildOptionRow(q, optIdx, opt, isDark, borderColor, textPrimary, textSecondary);
                }),

                const SizedBox(height: 6),

                if (!hasResponses)
                  TextButton.icon(
                    onPressed: () => _addOption(q),
                    icon: const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                    label: const Text(
                      'Thêm đáp án',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
              ],

              if (q.type == SurveyQuestionType.TEXT) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    '[ Khách hàng sẽ điền ý kiến đóng góp dạng văn bản tự luận tại đây ]',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary.withOpacity(0.8)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Section 11: Option Row
  Widget _buildOptionRow(
    _QuestionDraft q,
    int optIdx,
    _OptionDraft opt,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      height: 38,
      child: Row(
        children: [
          Icon(Icons.radio_button_unchecked_rounded, size: 16, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextField(
              controller: opt.textCtrl,
              readOnly: hasResponses,
              hintText: 'Đáp án ${optIdx + 1}',
              validator: (val) {
                if (q.type == SurveyQuestionType.SINGLE_CHOICE && (val == null || val.trim().isEmpty)) {
                  return 'Đáp án không được để trống!';
                }
                return null;
              },
            ),
          ),
          if (!hasResponses) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.arrow_upward_rounded, size: 14, color: textSecondary),
              tooltip: 'Lên',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: optIdx > 0 ? () => _moveOption(q, optIdx, -1) : null,
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward_rounded, size: 14, color: textSecondary),
              tooltip: 'Xuống',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: optIdx < q.options.length - 1 ? () => _moveOption(q, optIdx, 1) : null,
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: q.options.length > 2 ? AppColors.danger : Colors.grey),
              tooltip: 'Xóa đáp án',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: q.options.length > 2 ? () => _removeOption(q, optIdx) : null,
            ),
          ],
        ],
      ),
    );
  }

  // Section 17: Sticky Context Action Bar
  Widget _buildBottomActionBar(bool isDark, Color cardBg, Color borderColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: textPrimary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Lưu thay đổi để cập nhật thông tin khảo sát' : 'Kiểm tra kỹ thông tin trước khi khởi tạo',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
          ),
          const Spacer(),
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.outline,
            onPressed: _isSubmitting ? null : widget.onCancel,
          ),
          const SizedBox(width: 10),
          AppButton(
            label: _isSubmitting ? 'Đang lưu...' : (isEditing ? 'Lưu thay đổi' : 'Tạo khảo sát'),
            icon: Icons.check_rounded,
            onPressed: _isSubmitting ? null : _submitForm,
          ),
        ],
      ),
    );
  }

  // Draft Mutators
  void _addQuestion() {
    setState(() {
      _questionDrafts.add(
        _QuestionDraft(
          textCtrl: TextEditingController(),
          type: SurveyQuestionType.SINGLE_CHOICE,
          isRequired: true,
          options: [
            _OptionDraft(textCtrl: TextEditingController()),
            _OptionDraft(textCtrl: TextEditingController()),
          ],
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionDrafts[index].dispose();
      _questionDrafts.removeAt(index);
    });
  }

  void _duplicateQuestion(int index) {
    final orig = _questionDrafts[index];
    setState(() {
      _questionDrafts.insert(
        index + 1,
        _QuestionDraft(
          textCtrl: TextEditingController(text: '${orig.textCtrl.text} (Bản sao)'),
          type: orig.type,
          isRequired: orig.isRequired,
          options: orig.options.map((o) => _OptionDraft(textCtrl: TextEditingController(text: o.textCtrl.text))).toList(),
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

  void _addOption(_QuestionDraft q) {
    setState(() {
      q.options.add(_OptionDraft(textCtrl: TextEditingController()));
    });
  }

  void _removeOption(_QuestionDraft q, int index) {
    setState(() {
      q.options[index].dispose();
      q.options.removeAt(index);
    });
  }

  void _moveOption(_QuestionDraft q, int index, int delta) {
    setState(() {
      final item = q.options.removeAt(index);
      q.options.insert(index + delta, item);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin bắt buộc!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_questionDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài khảo sát phải có ít nhất 1 câu hỏi!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    for (int i = 0; i < _questionDrafts.length; i++) {
      final q = _questionDrafts[i];
      if (q.type == SurveyQuestionType.SINGLE_CHOICE) {
        final validOpts = q.options.where((o) => o.textCtrl.text.trim().isNotEmpty).toList();
        if (validOpts.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Câu ${i + 1} (Trắc nghiệm) phải có ít nhất 2 đáp án!'), backgroundColor: AppColors.danger),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final questionDtos = _questionDrafts.asMap().entries.map((qEntry) {
      final qIdx = qEntry.key;
      final qDraft = qEntry.value;

      List<CreateSurveyOption>? optionDtos;
      if (qDraft.type == SurveyQuestionType.SINGLE_CHOICE) {
        optionDtos = qDraft.options.asMap().entries.map((oEntry) {
          final oIdx = oEntry.key;
          final oDraft = oEntry.value;
          return CreateSurveyOption(
            optionText: oDraft.textCtrl.text.trim(),
            orderNum: oIdx + 1,
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
        questions: hasResponses ? null : questionDtos,
      );
      res = await apiService.updateSurvey(widget.existingSurvey!.surveyId, req, token: token);
    } else {
      final req = CreateSurveyRequest(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        rewardVoucherId: _selectedRewardVoucherId,
        isActive: _isActive,
        questions: questionDtos,
      );
      res = await apiService.createSurvey(req, token: token);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res.success) {
        widget.onSuccess();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }
}

class _QuestionDraft {
  final int? questionId;
  final TextEditingController textCtrl;
  SurveyQuestionType type;
  bool isRequired;
  List<_OptionDraft> options;

  _QuestionDraft({
    this.questionId,
    required this.textCtrl,
    required this.type,
    required this.isRequired,
    required this.options,
  });

  void dispose() {
    textCtrl.dispose();
    for (var o in options) {
      o.dispose();
    }
  }
}

class _OptionDraft {
  final TextEditingController textCtrl;

  _OptionDraft({required this.textCtrl});

  void dispose() {
    textCtrl.dispose();
  }
}
