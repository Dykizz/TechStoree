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
import '../../core/widgets/status_badge.dart';

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
            c.description.toLowerCase().contains(_searchQuery.toLowerCase())
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
                title: 'Danh Mục Sản Phẩm',
                subtitle: 'Quản lý cấu trúc danh mục và phân loại thiết bị điện tử',
                action: AppButton(
                  label: 'Tạo Danh Mục Mới',
                  icon: Icons.add_rounded,
                  onPressed: () => _showFormDialog(context, apiService, authProvider.token, null),
                ),
              ),

              FilterBar(
                searchField: AppSearchField<Category>(
                  controller: _searchCtrl,
                  hintText: 'Tìm kiếm tên danh mục hoặc mô tả...',
                  items: snapshot.data ?? [],
                  searchFilter: (c, q) => c.name.toLowerCase().contains(q.toLowerCase()) ||
                      c.description.toLowerCase().contains(q.toLowerCase()) ||
                      c.code.toLowerCase().contains(q.toLowerCase()),
                  itemLabel: (c) => c.name,
                  itemSubtitle: (c) => 'Mã: ${c.code} • ${c.description}',
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
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
                                        DataColumn(label: Text('MÃ DANH MỤC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TÊN DANH MỤC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('MÔ TẢ', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('SỐ LƯỢNG SP', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                        DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.w700, color: textSecondary, fontSize: 11))),
                                      ],
                                      rows: paginatedCategories.map((cat) {
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                            if (states.contains(WidgetState.hovered)) {
                                              return isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9);
                                            }
                                            return null;
                                          }),
                                          cells: [
                                            DataCell(Text(cat.code, style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.folder_open_rounded, size: 15, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(cat.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                cat.description.isNotEmpty ? cat.description : '—',
                                                style: TextStyle(color: textSecondary, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DataCell(
                                              Text('${cat.productCount} sản phẩm', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
                                            ),
                                            DataCell(
                                              const StatusBadge(
                                                label: 'HOẠT ĐỘNG',
                                                isSuccess: true,
                                              ),
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
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                    tooltip: 'Xóa danh mục',
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
                                );
                              },
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
    final descCtrl = TextEditingController(text: isEditing ? existing.description : '');

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
            isEditing ? 'Sửa Danh Mục: ${existing.name}' : 'Tạo Danh Mục Mới',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, labelText: 'Tên danh mục (*)'),
                const SizedBox(height: 10),
                AppTextField(controller: descCtrl, maxLines: 3, labelText: 'Mô tả danh mục'),
              ],
            ),
          ),
          actions: [
            AppButton(label: 'Hủy', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
            AppButton(
              label: isEditing ? 'Cập Nhật' : 'Tạo Mới',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final cat = Category(
                  id: isEditing ? existing.id : '0',
                  name: nameCtrl.text.trim(),
                  code: isEditing ? existing.code : 'CAT-${DateTime.now().millisecondsSinceEpoch}',
                  productCount: isEditing ? existing.productCount : 0,
                  description: descCtrl.text.trim(),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Xác nhận xóa danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        content: Text('Bạn có chắc muốn xóa danh mục "${cat.name}" không?'),
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
                  SnackBar(content: Text(res ? 'Xóa thành công!' : 'Xóa thất bại!'), backgroundColor: res ? AppColors.success : AppColors.danger),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
