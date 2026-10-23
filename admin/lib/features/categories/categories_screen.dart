import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/category.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pagination.dart';
import '../../core/widgets/app_search_field.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/scrollable_table_wrapper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 8;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _categoriesFuture = apiService.getCategories(token: token);
  }

  @override
  void dispose() {
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

    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var categories = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          categories = categories.where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.code.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        final totalItems = categories.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();
        final safePage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
        final startIndex = (safePage - 1) * _itemsPerPage;
        final paginatedCategories = totalItems == 0
            ? <Category>[]
            : categories.skip(startIndex).take(_itemsPerPage).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Loại sản phẩm',
                subtitle: 'Quản lý cấu trúc loại sản phẩm và phân loại thiết bị điện tử',
                action: AppButton(
                  label: 'Thêm loại sản phẩm',
                  icon: Icons.add_rounded,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ),
              ),

              FilterBar(
                searchField: AppSearchField<Category>(
                  controller: _searchCtrl,
                  hintText: 'Tìm kiếm theo tên hoặc mã loại...',
                  items: snapshot.data ?? [],
                  searchFilter: (c, q) => c.name.toLowerCase().contains(q.toLowerCase()) ||
                      c.code.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (c) => c.name,
                  itemSubtitle: (c) => 'Mã loại: ${c.code}',
                  onSelected: (c) => setState(() => _searchQuery = c.name),
                  onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
                  onCleared: () => setState(() => _searchQuery = ''),
                ),
              ),

              Flexible(
                fit: FlexFit.loose,
                child: DataTableContainer(
                  child: categories.isEmpty
                      ? const EmptyState(
                          icon: Icons.category_outlined,
                          title: 'Không tìm thấy danh mục nào',
                          message: 'Hãy thử tìm kiếm với từ khóa khác hoặc tạo danh mục mới.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScrollableTableWrapper(
                              child: DataTable(
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 42,
                                      dataRowMaxHeight: 42,
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: [
                                        DataColumn(label: Text('Mã loại', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('Tên loại', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                      ],
                                      rows: paginatedCategories.map((cat) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(Text(cat.code, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                            DataCell(
                                              Text(cat.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, size: 15, color: textSecondary),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                    tooltip: 'Chỉnh sửa',
                                                    onPressed: () => _showFormDialog(context, apiService, authProvider.token, cat),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline_rounded,
                                                      size: 15,
                                                      color: cat.productCount > 0 ? textSecondary.withValues(alpha: 0.4) : AppColors.danger,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                    tooltip: cat.productCount > 0 ? 'Đang có ${cat.productCount} sản phẩm - Không thể xóa' : 'Xóa danh mục',
                                                    onPressed: () => _confirmDelete(context, apiService, authProvider.token, cat),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                            ),
                            if (totalItems > 0)
                              AppPagination(
                                currentPage: safePage,
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

  void _showFormDialog(BuildContext context, ApiService apiService, String? token, Category? existing) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: isEditing ? existing.name : '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: Text(
            isEditing ? 'Sửa loại sản phẩm: ${existing.name}' : 'Tạo loại sản phẩm mới',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, labelText: 'Tên loại sản phẩm (*)'),
              ],
            ),
          ),
          actions: [
            AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
            AppButton(
              label: isEditing ? 'Cập nhật' : 'Tạo mới',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final cat = Category(
                  id: isEditing ? existing.id : '0',
                  name: nameCtrl.text.trim(),
                  code: isEditing ? existing.code : 'CAT-${DateTime.now().millisecondsSinceEpoch}',
                  productCount: isEditing ? existing.productCount : 0,
                  description: '',
                  iconName: isEditing ? existing.iconName : 'folder',
                );

                final res = isEditing
                    ? await apiService.updateCategory(cat, token: token)
                    : await apiService.createCategory(cat, token: token);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() => _loadCategories());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res ? 'Thao tác thành công!' : 'Thao tác thất bại!'), backgroundColor: res ? AppColors.success : AppColors.danger),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ApiService apiService, String? token, Category cat) {
    if (cat.productCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Không thể xóa loại sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Loại sản phẩm "'),
                    TextSpan(
                      text: cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '" hiện đang có ${cat.productCount} sản phẩm trực thuộc.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không thể xóa loại sản phẩm khi vẫn còn sản phẩm. Vui lòng chuyển hoặc xóa các sản phẩm liên quan trước!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            AppButton(
              label: 'Đã hiểu',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Xác nhận xóa danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn xóa loại sản phẩm "${cat.name}" không?'),
        actions: [
          AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Xóa Danh Mục',
            variant: AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await apiService.deleteCategory(cat.id, token: token);
              if (context.mounted) {
                setState(() => _loadCategories());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message.isNotEmpty ? res.message : (res.success ? 'Xóa thành công!' : 'Xóa thất bại!')),
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
