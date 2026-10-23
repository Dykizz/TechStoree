import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';

class _VariantItem {
  final Map<String, TextEditingController> attrControllers;
  final TextEditingController priceCtrl;
  final TextEditingController imageCtrl;
  bool isUploadingImage;
  bool isActive;

  _VariantItem({
    required List<String> attributeNames,
    Map<String, String>? initialAttributes,
    double? defaultPrice,
    String? initialImageUrl,
    this.isActive = true,
  })  : attrControllers = {
          for (var name in attributeNames)
            name: TextEditingController(text: initialAttributes?[name] ?? ''),
        },
        priceCtrl = TextEditingController(
          text: (defaultPrice != null && defaultPrice > 0)
              ? NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(defaultPrice).trim()
              : '',
        ),
        imageCtrl = TextEditingController(text: initialImageUrl ?? ''),
        isUploadingImage = false;

  void dispose() {
    for (var ctrl in attrControllers.values) {
      ctrl.dispose();
    }
    priceCtrl.dispose();
    imageCtrl.dispose();
  }

  String? get imageUrl => imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null;
  set imageUrl(String? url) => imageCtrl.text = url ?? '';

  Map<String, String> get attributesMap => {
        for (var e in attrControllers.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  double get price {
    final raw = priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }
}

class CreateProductDialog extends StatefulWidget {
  final List<Category> categories;
  final String? token;
  final VoidCallback onCreated;

  const CreateProductDialog({
    super.key,
    required this.categories,
    required this.token,
    required this.onCreated,
  });

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _newAttrInputCtrl = TextEditingController();

  late int _selectedCategoryId;
  bool _isSaving = false;

  // Danh sách thông số phân loại và danh sách biến thể
  final List<String> _attributeNames = ['Màu sắc', 'Dung lượng'];
  final List<_VariantItem> _variants = [];
  final List<String> _suggestedAttributes = ['Màu sắc', 'Dung lượng', 'Kích thước', 'RAM', 'Phiên bản'];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categories.isNotEmpty ? (int.tryParse(widget.categories.first.id) ?? 1) : 1;
    // Mặc định luôn có ít nhất 1 biến thể (Biến thể 1 để trống các trường)
    _variants.add(_VariantItem(
      attributeNames: _attributeNames,
      initialAttributes: {},
      defaultPrice: null,
      initialImageUrl: null,
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _newAttrInputCtrl.dispose();
    for (var v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  void _addAttributeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _attributeNames.contains(trimmed)) return;

    setState(() {
      _attributeNames.add(trimmed);
      for (var variant in _variants) {
        variant.attrControllers[trimmed] = TextEditingController();
      }
      _newAttrInputCtrl.clear();
    });
  }

  void _removeAttributeName(String name) {
    if (_attributeNames.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần giữ ít nhất 1 thông số thuộc tính!'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() {
      _attributeNames.remove(name);
      for (var variant in _variants) {
        variant.attrControllers[name]?.dispose();
        variant.attrControllers.remove(name);
      }
    });
  }

  void _addNewVariant({_VariantItem? copyFrom}) {
    setState(() {
      if (copyFrom != null) {
        // Chỉ khi người dùng bấm "Nhân bản (+)" thì mới sao chép giá trị từ biến thể đó
        _variants.add(_VariantItem(
          attributeNames: _attributeNames,
          initialAttributes: Map<String, String>.from(copyFrom.attributesMap),
          defaultPrice: copyFrom.price > 0 ? copyFrom.price : null,
          initialImageUrl: copyFrom.imageUrl,
          isActive: true,
        ));
      } else {
        // Khi bấm "(+) Thêm biến thể mới" -> Tạo biến thể mới hoàn toàn trống để người dùng nhập
        _variants.add(_VariantItem(
          attributeNames: _attributeNames,
          initialAttributes: {},
          defaultPrice: null,
          initialImageUrl: null,
          isActive: true,
        ));
      }
    });
  }

  void _removeVariant(int idx) {
    if (_variants.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần có ít nhất 1 biến thể cho sản phẩm!'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() {
      _variants[idx].dispose();
      _variants.removeAt(idx);
    });
  }


  Future<void> _uploadVariantImage(_VariantItem variant) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file != null) {
      setState(() => variant.isUploadingImage = true);
      final bytes = await file.readAsBytes();
      final url = await CloudinaryService.uploadImageBytes(
        bytes: bytes,
        fileName: file.name,
        backendBaseUrl: apiService.baseUrl,
        token: widget.token,
      );
      if (mounted) {
        setState(() {
          variant.isUploadingImage = false;
          if (url != null) {
            variant.imageCtrl.text = url;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo ít nhất 1 biến thể!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final variantAttrNames = List<String>.from(_attributeNames);
    final List<ProductVariant> finalVariants = [];
    final Set<String> signatures = {};

    for (int i = 0; i < _variants.length; i++) {
      final v = _variants[i];
      final attrs = v.attributesMap;

      // Kiểm tra xem đã điền đủ các thông số chưa
      for (var attrName in _attributeNames) {
        if (!attrs.containsKey(attrName) || attrs[attrName]!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biến thể số ${i + 1} chưa nhập thông số "$attrName"!'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      }

      // Kiểm tra trùng lặp tổ hợp thuộc tính
      final sig = _attributeNames.map((n) => '$n:${attrs[n]}').join('|');
      if (signatures.contains(sig)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biến thể số ${i + 1} có bộ thông số trùng lặp với biến thể khác! Vui lòng thay đổi giá trị.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      signatures.add(sig);

      if (v.price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biến thể số ${i + 1} chưa nhập giá bán hợp lệ!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      finalVariants.add(ProductVariant(
        price: v.price,
        stockQuantity: 0,
        imageUrl: (v.imageUrl != null && v.imageUrl!.trim().isNotEmpty) ? v.imageUrl!.trim() : null,
        attributes: attrs,
        isActive: v.isActive,
      ));
    }

    final catObj = widget.categories.where((c) => int.tryParse(c.id) == _selectedCategoryId);
    final catName = catObj.isNotEmpty ? catObj.first.name : (widget.categories.isNotEmpty ? widget.categories.first.name : 'Công nghệ');

    final prices = finalVariants.map((v) => v.price).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

    // Ảnh đại diện sản phẩm lấy từ biến thể đầu tiên có ảnh (hoặc ảnh placeholder)
    final firstVariantWithImg = finalVariants.where((v) => v.imageUrl != null && v.imageUrl!.isNotEmpty);
    final defaultProductImg = firstVariantWithImg.isNotEmpty
        ? firstVariantWithImg.first.imageUrl!
        : 'https://picsum.photos/200';

    final productToCreate = Product(
      id: '0',
      name: name,
      sku: 'TS-PROD-${DateTime.now().millisecondsSinceEpoch}',
      category: catName,
      categoryId: _selectedCategoryId,
      price: minPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      stock: 0,
      status: 'In Stock',
      imageUrl: defaultProductImg,
      description: _descCtrl.text.trim(),
      variantAttributes: variantAttrNames,
      variants: finalVariants,
    );

    setState(() => _isSaving = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final res = await apiService.createProduct(productToCreate, token: widget.token);

    if (mounted) {
      setState(() => _isSaving = false);
      if (res.success) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${res.message} (Đã khởi tạo ${finalVariants.length} biến thể thành công)'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bgSubtle = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = (screenWidth * 0.92).clamp(680.0, 980.0);
    final dialogHeight = (screenHeight * 0.92).clamp(520.0, 900.0);

    // Tính khoảng giá trực tiếp từ các biến thể
    final prices = _variants.map((v) => v.price).where((p) => p > 0).toList();
    final minP = prices.isNotEmpty ? prices.reduce(math.min) : 0;
    final maxP = prices.isNotEmpty ? prices.reduce(math.max) : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          color: surfaceColor,
        ),
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
                color: bgSubtle,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm sản phẩm & Thiết lập biến thể giá',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                        ),
                        Text(
                          'Tùy chỉnh thông số từng biến thể (Màu sắc, Dung lượng...) kèm mức giá riêng hiển thị trên web bán hàng',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE BODY ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== PHẦN 1: THÔNG TIN CHUNG SẢN PHẨM =====
                    Text('1. THÔNG TIN CHUNG SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: AppTextField(
                            controller: _nameCtrl,
                            labelText: 'Tên sản phẩm (*)',
                            hintText: 'VD: iPhone 16 Pro Max, MacBook Pro M4...',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: AppDropdown<int>(
                            labelText: 'Danh mục (*)',
                            value: _selectedCategoryId,
                            items: widget.categories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: int.tryParse(cat.id) ?? 1,
                                child: Text(cat.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategoryId = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descCtrl,
                      labelText: 'Mô tả chi tiết',
                      hintText: 'Nhập mô tả đặc điểm, cấu hình nổi bật...',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // ===== PHẦN 2: THÔNG SỐ VÀ BIẾN THỂ SẢN PHẨM =====
                    // --- BƯỚC 2.1: KHAI BÁO CÁC THÔNG SỐ SỬ DỤNG ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgSubtle,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Các thông số phân loại áp dụng cho sản phẩm này:',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: textPrimary),
                              ),
                            ],
                          ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ..._attributeNames.map((name) {
                                  return Chip(
                                    label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                                    onDeleted: () => _removeAttributeName(name),
                                  );
                                }),

                                // Input thêm thông số mới
                                SizedBox(
                                  width: 220,
                                  height: 36,
                                  child: TextField(
                                    controller: _newAttrInputCtrl,
                                    style: TextStyle(color: textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Thêm thông số (VD: RAM)...',
                                      hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                                        onPressed: () => _addAttributeName(_newAttrInputCtrl.text),
                                      ),
                                    ),
                                    onSubmitted: _addAttributeName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Quick Suggestion Chips
                            Row(
                              children: [
                                Text('Gợi ý nhanh:', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                                const SizedBox(width: 6),
                                Wrap(
                                  spacing: 4,
                                  children: _suggestedAttributes.where((s) => !_attributeNames.contains(s)).map((sug) {
                                    return InkWell(
                                      onTap: () => _addAttributeName(sug),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: surfaceColor,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Text('+ $sug', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- BƯỚC 2.2: DANH SÁCH TỪNG BIẾN THỂ (BIẾN THỂ 1, BIẾN THỂ 2...) ---
                      Row(
                        children: [
                          Text(
                            'DANH SÁCH BIẾN THỂ (${_variants.length} PHIÊN BẢN)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                          const Spacer(),
                          // Live Price preview on web
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_rounded, size: 14, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  minP > 0
                                      ? 'Giá hiển thị trên Web: ${currencyFormat.format(minP)} – ${currencyFormat.format(maxP)}'
                                      : 'Chưa nhập giá bán',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: minP > 0 ? AppColors.success : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // List of Variant Cards
                      ..._variants.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final variant = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Variant Card Top Bar
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Biến thể ${idx + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      variant.attributesMap.values.isNotEmpty
                                          ? variant.attributesMap.values.join(' • ')
                                          : 'Chưa nhập thông số',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Switch Active
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: variant.isActive,
                                      activeThumbColor: AppColors.success,
                                      onChanged: (val) => setState(() => variant.isActive = val),
                                    ),
                                  ),
                                  Text(variant.isActive ? 'Đang bán' : 'Ngừng', style: TextStyle(fontSize: 11, color: textSecondary)),
                                  const SizedBox(width: 8),

                                  // Duplicate button
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Nhân bản (+)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _addNewVariant(copyFrom: variant),
                                  ),
                                  if (_variants.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                      tooltip: 'Xóa biến thể này',
                                      onPressed: () => _removeVariant(idx),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Form row: Attribute inputs + Price
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Các ô thông số (Màu sắc, Dung lượng...)
                                  ..._attributeNames.map((attrName) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$attrName (*)',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              height: 36,
                                              child: TextField(
                                                controller: variant.attrControllers[attrName],
                                                style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  hintText: 'Nhập $attrName...',
                                                  hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onChanged: (_) => setState(() {}),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  // Giá bán riêng của biến thể này
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Giá bán (VNĐ) (*)',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 36,
                                          child: TextField(
                                            controller: variant.priceCtrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [CurrencyInputFormatter()],
                                            style: TextStyle(fontSize: 12.5, color: textPrimary, fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText: 'Nhập giá bán...',
                                              hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Dòng thiết lập ảnh riêng của biến thể: hỗ trợ cả Tải từ máy và Dán đường dẫn URL
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: bgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail preview
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: (variant.imageUrl != null && variant.imageUrl!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(5),
                                              child: Image.network(
                                                variant.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => const Center(
                                                  child: Icon(Icons.broken_image_outlined, color: AppColors.danger, size: 16),
                                                ),
                                              ),
                                            )
                                          : Icon(Icons.image_outlined, size: 18, color: textSecondary),
                                    ),
                                    const SizedBox(width: 8),

                                    // Nút tải từ máy
                                    OutlinedButton.icon(
                                      icon: variant.isUploadingImage
                                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.cloud_upload_outlined, size: 15),
                                      label: Text(
                                        variant.isUploadingImage ? 'Đang tải...' : 'Tải từ máy',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: borderColor),
                                      ),
                                      onPressed: variant.isUploadingImage ? null : () => _uploadVariantImage(variant),
                                    ),
                                    const SizedBox(width: 8),

                                    // Ô nhập đường dẫn URL ảnh riêng
                                    Expanded(
                                      child: SizedBox(
                                        height: 32,
                                        child: TextField(
                                          controller: variant.imageCtrl,
                                          style: TextStyle(fontSize: 11.5, color: textPrimary),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: 'Hoặc dán đường dẫn URL ảnh riêng cho biến thể này (https://...)...',
                                            hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                            prefixIcon: const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                                            suffixIcon: variant.imageCtrl.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.close_rounded, size: 14),
                                                    tooltip: 'Xóa ảnh biến thể',
                                                    onPressed: () {
                                                      variant.imageCtrl.clear();
                                                      setState(() {});
                                                    },
                                                  )
                                                : null,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // NÚT THÊM BIẾN THỂ TIẾP THEO (+)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: Text(
                          ' (+) Thêm biến thể mới (Biến thể ${_variants.length + 1})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                        ),
                        onPressed: () => _addNewVariant(),
                      ),
                    ],
                  ),
                ),
              ),

              // --- FOOTER ACTIONS ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                  color: bgSubtle,
                ),
                child: Row(
                  children: [
                    Text(
                      minP > 0
                          ? 'Sẽ tạo 1 sản phẩm chính kèm ${_variants.length} biến thể • Khoảng giá: ${currencyFormat.format(minP)} – ${currencyFormat.format(maxP)}'
                          : 'Sẽ tạo 1 sản phẩm chính kèm ${_variants.length} biến thể',
                      style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                    ),
                  const Spacer(),
                  AppButton(
                    label: 'Hủy bỏ',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: _isSaving ? 'Đang tạo...' : 'Lưu & Tạo sản phẩm',
                    icon: _isSaving ? null : Icons.check_circle_rounded,
                    variant: AppButtonVariant.primary,
                    onPressed: _isSaving ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
