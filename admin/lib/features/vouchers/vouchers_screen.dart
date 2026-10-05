import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/voucher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_badge.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedDiscountType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  late Future<List<Voucher>> _vouchersFuture;

  static double? _parseCleanDouble(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final cleaned = val.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  static int? _parseCleanInt(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final cleaned = val.replaceAll('.', '').replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ApiService>(context, listen: false).addListener(_onApiServiceChanged);
      }
    });
    _loadData();
  }

  void _onApiServiceChanged() {
    if (mounted) {
      setState(() {
        _loadData();
      });
    }
  }

  void _loadData() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _vouchersFuture = apiService.getVouchers(token: token);
  }

  @override
  void dispose() {
    try {
      Provider.of<ApiService>(context, listen: false).removeListener(_onApiServiceChanged);
    } catch (_) {}
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<Voucher>>(
      future: _vouchersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var vouchers = snapshot.data ?? [];

        // Apply Search & Filters
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          vouchers = vouchers.where((v) =>
            v.code.toLowerCase().contains(query) ||
            v.title.toLowerCase().contains(query) ||
            (v.description?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        if (_selectedDiscountType != 'Tất cả') {
          vouchers = vouchers.where((v) => v.discountType == _selectedDiscountType).toList();
        }

        if (_selectedStatus != 'Tất cả') {
          vouchers = vouchers.where((v) => v.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
        }

        final totalItems = vouchers.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();

        if (_currentPage > totalPages && totalPages > 0) {
          _currentPage = totalPages;
        }

        final startIndex = (totalItems == 0) ? 0 : (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;
        final paginatedVouchers = (startIndex < totalItems) ? vouchers.sublist(startIndex, endIndex) : <Voucher>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'Quản Lý Voucher Giảm Giá',
                subtitle: 'Tạo và quản lý các mã giảm giá bill áp dụng khi khách hàng thanh toán',
                action: AppButton(
                  label: 'Tạo Voucher Mới',
                  icon: Icons.add_rounded,
                  onPressed: () => _showVoucherFormDialog(context, null),
                ),
              ),

              // Filter Controls Bar
              FilterBar(
                searchField: AppSearchField<Voucher>(
                  controller: _searchCtrl,
                  hintText: 'Tìm theo mã voucher hoặc tiêu đề...',
                  items: vouchers,
                  searchFilter: (v, q) => v.code.toLowerCase().contains(q.toLowerCase()) ||
                      v.title.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (v) => '${v.code} - ${v.title}',
                  itemSubtitle: (v) => '${v.formattedDiscountValue(currencyFormat)} • Đã dùng: ${v.usedCount}${v.usageLimit != null ? "/${v.usageLimit}" : ""}',
                  onSelected: (v) {
                    setState(() {
                      _searchQuery = v.code;
                      _currentPage = 1;
                    });
                  },
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                  },
                  onCleared: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                ),
                filters: [
                  AppDropdown<String>(
                    value: _selectedDiscountType,
                    labelText: 'Loại giảm giá',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả loại')),
                      DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần trăm (%)')),
                      DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Tiền cố định (VNĐ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDiscountType = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  AppDropdown<String>(
                    value: _selectedStatus,
                    labelText: 'Trạng thái',
                    items: const [
                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Đang diễn ra (ACTIVE)')),
                      DropdownMenuItem(value: 'UPCOMING', child: Text('Sắp diễn ra (UPCOMING)')),
                      DropdownMenuItem(value: 'EXPIRED', child: Text('Đã hết hạn (EXPIRED)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStatus = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ],
              ),

              // Data Table Container
              Flexible(
                child: DataTableContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: paginatedVouchers.isEmpty
                            ? const EmptyState(
                                icon: Icons.confirmation_number_outlined,
                                title: 'Không tìm thấy voucher nào',
                                message: 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc trạng thái.',
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
                                    child: DataTable(
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 56,
                                      dataRowMaxHeight: 64,
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        DataColumn(label: Text('MÃ VOUCHER / TIÊU ĐỀ', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('GIẢM GIÁ', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('ĐIỀU KIỆN', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('THỜI GIAN HẠN DÙNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('LƯỢT SỬ DỤNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                        DataColumn(label: Text('HÀNH ĐỘNG', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                                      ],
                                      rows: paginatedVouchers.map((voucher) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            // Code & Title
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryLight,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                                        ),
                                                        child: Text(
                                                          voucher.code,
                                                          style: const TextStyle(
                                                            color: AppColors.primary,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!voucher.isPublic) ...[
                                                        const SizedBox(width: 6),
                                                        Tooltip(
                                                          message: 'Voucher ẩn / Quà tặng riêng',
                                                          child: Icon(Icons.lock_rounded, size: 14, color: textSecondary),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    voucher.title,
                                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Discount Info
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    voucher.formattedDiscountValue(currencyFormat),
                                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  Text(
                                                    voucher.isPercentage ? 'Giảm theo %' : 'Giảm số tiền trực tiếp',
                                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Terms & Conditions
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Đơn từ: ${currencyFormat.format(voucher.minOrderValue)}',
                                                    style: TextStyle(color: textPrimary, fontSize: 12),
                                                  ),
                                                  if (voucher.isPercentage && voucher.maxDiscountAmount != null)
                                                    Text(
                                                      'Tối đa: ${currencyFormat.format(voucher.maxDiscountAmount)}',
                                                      style: TextStyle(color: textSecondary, fontSize: 11),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Start & End Date
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('Từ: ${dateFormat.format(voucher.startDate)}', style: TextStyle(color: textPrimary, fontSize: 11)),
                                                  Text('Đến: ${dateFormat.format(voucher.endDate)}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                                ],
                                              ),
                                            ),

                                            // Usage Count
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Đã dùng: ${voucher.usedCount} / ${voucher.usageLimit ?? '∞'}',
                                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                                  ),
                                                  Text(
                                                    'Tối đa ${voucher.limitPerUser} lần/user',
                                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status Badge & Switch
                                            DataCell(
                                              Row(
                                                children: [
                                                  _buildStatusBadge(voucher.status, voucher.isActive),
                                                  const SizedBox(width: 8),
                                                  Switch(
                                                    value: voucher.isActive,
                                                    activeThumbColor: AppColors.primary,
                                                    onChanged: (val) async {
                                                      final res = await apiService.toggleVoucherActive(
                                                        voucher.voucherId,
                                                        token: authProvider.token,
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(res.message),
                                                            backgroundColor: res.success ? AppColors.success : AppColors.danger,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Actions
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, color: textSecondary, size: 18),
                                                    tooltip: 'Chỉnh sửa voucher',
                                                    onPressed: () => _showVoucherFormDialog(context, voucher),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                                    tooltip: 'Xóa voucher',
                                                    onPressed: () => _confirmDeleteVoucher(context, apiService, authProvider, voucher),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      // Pagination Controls
                      if (totalItems > 0)
                        AppPagination(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          totalItems: totalItems,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                          onItemsPerPageChanged: (items) {
                            setState(() {
                              _itemsPerPage = items;
                              _currentPage = 1;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isActive) {
    if (!isActive) {
      return const StatusBadge(label: 'TẠM NGƯNG', isWarning: true);
    }

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const StatusBadge(label: 'HOẠT ĐỘNG', isSuccess: true);
      case 'UPCOMING':
        return const StatusBadge(label: 'SẮP DIỄN RA', isInfo: true);
      case 'EXPIRED':
        return const StatusBadge(label: 'ĐÃ HẾT HẠN', isDanger: true);
      default:
        return StatusBadge(label: status);
    }
  }

  void _showVoucherFormDialog(BuildContext context, Voucher? voucher) {
    final isEdit = voucher != null;
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(text: voucher?.code ?? '');
    final titleCtrl = TextEditingController(text: voucher?.title ?? '');
    final descCtrl = TextEditingController(text: voucher?.description ?? '');
    final discountValCtrl = TextEditingController(text: voucher != null ? voucher.discountValue.toStringAsFixed(0) : '');
    final minOrderValCtrl = TextEditingController(text: voucher != null ? voucher.minOrderValue.toStringAsFixed(0) : '0');
    final maxDiscountValCtrl = TextEditingController(text: voucher?.maxDiscountAmount != null ? voucher!.maxDiscountAmount!.toStringAsFixed(0) : '');
    final usageLimitCtrl = TextEditingController(text: voucher?.usageLimit?.toString() ?? '');
    final limitPerUserCtrl = TextEditingController(text: voucher?.limitPerUser.toString() ?? '1');

    String discountType = voucher?.discountType ?? 'PERCENTAGE';
    DateTime startDate = voucher?.startDate ?? DateTime.now();
    DateTime endDate = voucher?.endDate ?? DateTime.now().add(const Duration(days: 14));
    bool isActive = voucher?.isActive ?? true;
    bool isPublic = voucher?.isPublic ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
            final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
            final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(isEdit ? Icons.edit_note_rounded : Icons.add_card_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Chỉnh Sửa Chiến Dịch Voucher' : 'Tạo Mới Voucher Giảm Giá', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 750,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                controller: codeCtrl,
                                readOnly: isEdit,
                                textCapitalization: TextCapitalization.characters,
                                labelText: 'Mã Voucher (VD: SALE100K)*',
                                hintText: 'Nhập mã không khoảng trắng',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Mã voucher không được để trống';
                                  if (val.trim().length < 3) return 'Mã voucher tối thiểu 3 ký tự';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: AppTextField(
                                controller: titleCtrl,
                                labelText: 'Tiêu Đề Hiển Thị*',
                                hintText: 'VD: Giảm 100K cho đơn 2 triệu',
                                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        AppTextField(
                          controller: descCtrl,
                          maxLines: 2,
                          labelText: 'Thể lệ / Mô tả chi tiết',
                          hintText: 'Nhập điều kiện áp dụng...',
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: AppDropdown<String>(
                                value: discountType,
                                labelText: 'Loại giảm giá*',
                                items: const [
                                  DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần Trăm (%)')),
                                  DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Số Tiền Cố Định (VNĐ)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      discountType = val;
                                      if (discountType == 'FIXED_AMOUNT') {
                                        maxDiscountValCtrl.clear();
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: discountValCtrl,
                                keyboardType: TextInputType.number,
                                labelText: discountType == 'PERCENTAGE' ? 'Mức giảm (%)*' : 'Mức giảm (VNĐ)*',
                                hintText: discountType == 'PERCENTAGE' ? 'VD: 10' : 'VD: 100000',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Nhập mức giảm';
                                  final numVal = _parseCleanDouble(val);
                                  if (numVal == null || numVal <= 0) return 'Mức giảm phải > 0';
                                  if (discountType == 'PERCENTAGE' && numVal > 100) return 'Tối đa 100%';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: minOrderValCtrl,
                                keyboardType: TextInputType.number,
                                labelText: 'Đơn tối thiểu (VNĐ)',
                                hintText: '0 = Không giới hạn',
                              ),
                            ),
                            if (discountType == 'PERCENTAGE') ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  controller: maxDiscountValCtrl,
                                  keyboardType: TextInputType.number,
                                  labelText: 'Giảm tối đa (VNĐ)',
                                  hintText: 'Để trống = không giới hạn',
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: usageLimitCtrl,
                                keyboardType: TextInputType.number,
                                labelText: 'Số lượt toàn sàn',
                                hintText: 'Để trống = Không giới hạn',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: limitPerUserCtrl,
                                keyboardType: TextInputType.number,
                                labelText: 'Giới hạn / 1 Khách hàng*',
                                hintText: 'Mặc định: 1',
                                validator: (val) {
                                  final numVal = int.tryParse(val ?? '1');
                                  if (numVal == null || numVal < 1) return 'Tối thiểu là 1';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (pickedDate != null) {
                                    if (!context.mounted) return;
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(startDate),
                                    );
                                    if (pickedTime != null) {
                                      setModalState(() {
                                        startDate = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Ngày Bắt Đầu*',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(dateFormat.format(startDate), style: TextStyle(color: textPrimary, fontSize: 13)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (pickedDate != null) {
                                    if (!context.mounted) return;
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(endDate),
                                    );
                                    if (pickedTime != null) {
                                      setModalState(() {
                                        endDate = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Ngày Kết Thúc*',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(dateFormat.format(endDate), style: TextStyle(color: textPrimary, fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('Kích hoạt ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                value: isActive,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => setModalState(() => isActive = val),
                              ),
                            ),
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('Công khai trên sàn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                value: isPublic,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => setModalState(() => isPublic = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                AppButton(
                  label: 'Hủy',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.pop(ctx),
                ),
                AppButton(
                  label: isEdit ? 'Lưu Cập Nhật' : 'Tạo Voucher',
                  variant: AppButtonVariant.primary,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    if (startDate.isAfter(endDate) || startDate.isAtSameMomentAs(endDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu.'), backgroundColor: AppColors.danger),
                      );
                      return;
                    }

                    final apiService = Provider.of<ApiService>(context, listen: false);
                    final token = Provider.of<AuthProvider>(context, listen: false).token;

                    final discountVal = _parseCleanDouble(discountValCtrl.text) ?? 0;
                    final minOrderVal = _parseCleanDouble(minOrderValCtrl.text) ?? 0;
                    final maxDiscountVal = discountType == 'PERCENTAGE'
                        ? _parseCleanDouble(maxDiscountValCtrl.text)
                        : null;
                    final usageLimit = _parseCleanInt(usageLimitCtrl.text);
                    final limitPerUser = _parseCleanInt(limitPerUserCtrl.text) ?? 1;

                    final newVoucher = Voucher(
                      voucherId: voucher?.voucherId ?? 0,
                      code: codeCtrl.text.trim().toUpperCase(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      discountType: discountType,
                      discountValue: discountVal,
                      minOrderValue: minOrderVal,
                      maxDiscountAmount: maxDiscountVal,
                      usageLimit: usageLimit,
                      limitPerUser: limitPerUser,
                      startDate: startDate,
                      endDate: endDate,
                      isActive: isActive,
                      isPublic: isPublic,
                      createdAt: voucher?.createdAt ?? DateTime.now(),
                    );

                    final res = isEdit
                        ? await apiService.updateVoucher(voucher.voucherId, newVoucher, token: token)
                        : await apiService.createVoucher(newVoucher, token: token);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVoucher(BuildContext context, ApiService apiService, AuthProvider authProvider, Voucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Bạn có chắc chắn muốn xóa voucher mã "${voucher.code}" (${voucher.title}) không?'),
        actions: [
          AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Xóa Voucher',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteVoucher(voucher.voucherId, token: authProvider.token);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: res.success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
