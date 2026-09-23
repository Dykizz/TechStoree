import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/supplier.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/api_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late Future<List<Supplier>> _suppliersFuture;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    _suppliersFuture = apiService.getSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final backgroundColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        var suppliers = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          suppliers = suppliers.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.contactName.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm nhà cung cấp theo tên, mã hoặc người liên hệ...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: backgroundColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showSupplierDialog(context, apiService),
                    icon: const Icon(Icons.add_business_rounded, size: 20),
                    label: const Text('Thêm Nhà Cung Cấp', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data Table
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        ),
                        dataRowMinHeight: 65,
                        dataRowMaxHeight: 65,
                        columns: const [
                          DataColumn(label: Text('Nhà cung cấp', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Mã NCC', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Người liên hệ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: suppliers.map((supplier) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.domain_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            supplier.name,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            supplier.description,
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    supplier.code,
                                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataCell(Text(supplier.contactName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                              DataCell(Text(supplier.phone, style: TextStyle(color: textSecondary, fontSize: 12))),
                              DataCell(Text(supplier.email, style: TextStyle(color: textSecondary, fontSize: 12))),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    supplier.address,
                                    style: TextStyle(color: textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                                      onPressed: () => _showSupplierDialog(context, apiService, supplier: supplier),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                      onPressed: () => _showDeleteSupplierConfirm(context, apiService, supplier),
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
            ],
          ),
        );
      },
    );
  }

  void _showSupplierDialog(BuildContext context, ApiService apiService, {Supplier? supplier}) {
    final isEditing = supplier != null;
    final nameCtrl = TextEditingController(text: isEditing ? supplier.name : '');
    final codeCtrl = TextEditingController(text: isEditing ? supplier.code : '');
    final contactCtrl = TextEditingController(text: isEditing ? supplier.contactName : '');
    final phoneCtrl = TextEditingController(text: isEditing ? supplier.phone : '');
    final emailCtrl = TextEditingController(text: isEditing ? supplier.email : '');
    final addressCtrl = TextEditingController(text: isEditing ? supplier.address : '');
    final descCtrl = TextEditingController(text: isEditing ? supplier.description : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Chỉnh Sửa Nhà Cung Cấp' : 'Thêm Nhà Cung Cấp Mới', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên Nhà cung cấp', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(labelText: 'Mã NCC (vd: SUP-AAPL)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: contactCtrl,
                        decoration: const InputDecoration(labelText: 'Người liên hệ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Địa chỉ trụ sở', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Ghi chú / Mô tả', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;

              final newSupplier = Supplier(
                id: isEditing ? supplier.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().toUpperCase(),
                contactName: contactCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );

              if (isEditing) {
                await apiService.updateSupplier(newSupplier);
              } else {
                await apiService.createSupplier(newSupplier);
              }

              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {
                  _loadSuppliers();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEditing ? 'Đã cập nhật nhà cung cấp!' : 'Đã thêm nhà cung cấp mới!')),
                );
              }
            },
            child: Text(isEditing ? 'Cập Nhật' : 'Lưu Nhà Cung Cấp', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSupplierConfirm(BuildContext context, ApiService apiService, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nhà cung cấp', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa nhà cung cấp "${supplier.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await apiService.deleteSupplier(supplier.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {
                  _loadSuppliers();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa nhà cung cấp thành công!')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
