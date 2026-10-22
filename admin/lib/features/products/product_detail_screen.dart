import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/product.dart';
import '../../core/models/category.dart';
import '../../core/models/promotion.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_price_range.dart';
import '../../core/widgets/variant_attributes_view.dart';
import '../../core/widgets/promotion_badge.dart';
import '../../core/widgets/status_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int initialTabIndex; // 0: General, 1: Variants
  final VoidCallback onBack;
  final VoidCallback onProductUpdated;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.initialTabIndex = 0,
    required this.onBack,
    required this.onProductUpdated,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late TabController _tabController;
  late Product _currentProduct;

  // Form Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageUrlCtrl;
  late int _selectedCategoryId;
  late bool _isActive;

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  bool _isUploadingMainImage = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    _nameCtrl = TextEditingController(text: _currentProduct.name);
    _descCtrl = TextEditingController(text: _currentProduct.description);
    _imageUrlCtrl = TextEditingController(text: _currentProduct.imageUrl);
    _selectedCategoryId = _currentProduct.categoryId;
    _isActive = _currentProduct.isActive;

    _loadFullDetails();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFullDetails() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (_currentProduct.id.isNotEmpty && _currentProduct.id != '0') {
      final detailed = await apiService.getProductById(_currentProduct.id, token: token);
      if (detailed != null && mounted) {
        setState(() {
          _currentProduct = detailed;
          _nameCtrl.text = _currentProduct.name;
          _descCtrl.text = _currentProduct.description;
          _imageUrlCtrl.text = _currentProduct.imageUrl;
          _selectedCategoryId = _currentProduct.categoryId;
          _isActive = _currentProduct.isActive;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final cats = await apiService.getCategories(token: token);
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _saveProductGeneralInfo() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);

    String selectedCatName = _currentProduct.category;
    final matched = _categories.where((c) => int.tryParse(c.id) == _selectedCategoryId).toList();
    if (matched.isNotEmpty) {
      selectedCatName = matched.first.name;
    }

    final updatedProduct = Product(
      id: _currentProduct.id,
      name: _nameCtrl.text.trim(),
      sku: _currentProduct.sku,
      category: selectedCatName,
      categoryId: _selectedCategoryId,
      price: _currentProduct.price,
      minPrice: _currentProduct.minPrice,
      maxPrice: _currentProduct.maxPrice,
      totalStock: _currentProduct.totalStock,
      stock: _currentProduct.stock,
      status: _isActive ? _currentProduct.status : 'Ngừng bán',
      isActive: _isActive,
      imageUrl: _imageUrlCtrl.text.trim().isNotEmpty ? _imageUrlCtrl.text.trim() : _currentProduct.imageUrl,
      description: _descCtrl.text.trim(),
      promotion: _currentProduct.promotion,
      hasPromotion: _currentProduct.hasPromotion,
      createdAt: _currentProduct.createdAt,
      variantAttributes: _currentProduct.variantAttributes,
      variants: _currentProduct.variants,
    );

    final res = await apiService.updateProduct(updatedProduct, token: token);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.success : AppColors.danger,
        ),
      );
      if (res.success) {
        widget.onProductUpdated();
        _loadFullDetails();
      }
    }
  }

  void _showAddEditVariantDialog([ProductVariant? existingVariant]) async {
    final isEditing = existingVariant != null;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    // Tải danh sách chương trình khuyến mãi khả dụng (ACTIVE)
    List<Promotion> availablePromos = [];
    try {
      final allPromos = await apiService.getPromotions(token: token);
      availablePromos = allPromos.where((p) => p.isActive && p.status == 'ACTIVE').toList();
    } catch (e) {
      debugPrint('Error loading promotions: $e');
    }

    final int currentPromoId = (existingVariant != null && existingVariant.promotion != null && existingVariant.promotion!.hasPromotion)
        ? (existingVariant.promotion!.promotionId ?? 0)
        : 0;

    if (currentPromoId > 0 && !availablePromos.any((p) => p.promotionId == currentPromoId)) {
      try {
        final currentP = await apiService.getPromotionById(currentPromoId, token: token);
        if (currentP != null) {
          availablePromos.insert(0, currentP);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    int selectedPromoId = currentPromoId;
    final int originalPromoId = currentPromoId;

    final initialPriceText = isEditing
        ? NumberFormat('#,###', 'en_US').format(existingVariant.price.toInt())
        : '';
    final priceCtrl = TextEditingController(text: initialPriceText);
    final varImageCtrl = TextEditingController(text: isEditing ? (existingVariant.imageUrl ?? '') : '');
    bool varIsActive = isEditing ? existingVariant.isActive : true;

    // Danh sách tên thuộc tính áp dụng: Luôn lấy đủ tất cả thuộc tính bắt buộc của sản phẩm
    final Set<String> attrSet = {};
    if (_currentProduct.variantAttributes.isNotEmpty) {
      attrSet.addAll(_currentProduct.variantAttributes);
    }
    if (isEditing && existingVariant.attributes.isNotEmpty) {
      attrSet.addAll(existingVariant.attributes.keys);
    }
    if (attrSet.isEmpty && _currentProduct.variants.isNotEmpty) {
      for (var v in _currentProduct.variants) {
        attrSet.addAll(v.attributes.keys);
      }
    }
    if (attrSet.isEmpty) {
      attrSet.addAll(['Màu sắc', 'Dung lượng']);
    }
    final List<String> attributeNames = attrSet.toList();

    // Khởi tạo controllers cho từng thuộc tính
    Map<String, TextEditingController> attrControllers = {};
    for (var attrName in attributeNames) {
      final initialVal = (isEditing && existingVariant.attributes.containsKey(attrName))
          ? existingVariant.attributes[attrName]!
          : '';
      attrControllers[attrName] = TextEditingController(text: initialVal);
    }

    final newAttrInputCtrl = TextEditingController();
    bool isUploadingVarImg = false;
    final List<String> standardPresets = ['Màu sắc', 'Dung lượng', 'RAM', 'Ổ cứng SSD', 'Màn hình', 'Switch', 'Kết nối'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(dialogCtx).isDarkMode;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          final bgSubtle = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
          final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
          final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;

          // Chuỗi hiển thị trực tiếp giá trị thuộc tính
          final liveAttributes = attrControllers.values.map((c) => c.text.trim()).where((s) => s.isNotEmpty).join(' • ');
          final liveTitle = liveAttributes.isNotEmpty ? liveAttributes : 'Chưa nhập thông số';

          // Tìm promotion đang được chọn để tính giá live
          Promotion? selectedPromo;
          if (selectedPromoId > 0) {
            for (final p in availablePromos) {
              if (p.promotionId == selectedPromoId) {
                selectedPromo = p;
                break;
              }
            }
          }

          final rawPrice = priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
          final currentPrice = double.tryParse(rawPrice) ?? 0.0;
          double discountAmt = 0.0;
          double promoPrice = currentPrice;
          if (selectedPromo != null && currentPrice > 0) {
            if (selectedPromo.isPercentage) {
              discountAmt = (currentPrice * (selectedPromo.discountValue / 100)).roundToDouble();
            } else {
              discountAmt = selectedPromo.discountValue;
            }
            discountAmt = discountAmt.clamp(0.0, currentPrice);
            promoPrice = math.max(0.0, currentPrice - discountAmt);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Chỉnh sửa biến thể' : 'Thêm biến thể sản phẩm mới',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary),
                      ),
                      Text(
                        _currentProduct.name,
                        style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.normal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
            content: SizedBox(
              width: 660,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hướng dẫn chuẩn ERP Tồn kho
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isEditing
                                  ? 'Tồn kho hiện tại: ${existingVariant.stockQuantity} sản phẩm. Theo chuẩn ERP, số lượng tồn kho chỉ được cập nhật qua Đơn nhập hàng (PO) hoặc Hóa đơn bán hàng.'
                                  : 'Tồn kho ban đầu của biến thể là 0 theo chuẩn ERP. Để nhập kho số lượng thực tế, vui lòng tạo "Đơn nhập hàng" (PO) sau khi tạo biến thể.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isEditing && existingVariant.stockQuantity <= 10) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.pop(dialogCtx);
                                widget.onBack();
                                Provider.of<NavigationProvider>(context, listen: false).setIndex(6);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã chuyển sang "Phiếu nhập hàng". Hãy tạo đơn nhập bổ sung cho "${existingVariant.variantName}".'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_shopping_cart_rounded, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tạo PO ngay',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card Biến thể đồng bộ chuẩn thiết kế CreateProductDialog
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng Header Biến thể (Badge + Tên thông số trực tiếp + Switch Đang bán)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isEditing ? 'Biến thể' : 'Biến thể mới',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  liveTitle,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: varIsActive,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (val) => setDialogState(() => varIsActive = val),
                                ),
                              ),
                              Text(varIsActive ? 'Đang bán' : 'Ngừng', style: TextStyle(fontSize: 11, color: textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Khung quản lý thông số phân loại
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_list_bulleted_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Các thông số áp dụng cho biến thể:',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ...attributeNames.map((name) {
                                      return Chip(
                                        label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                        deleteIcon: const Icon(Icons.close_rounded, size: 13),
                                        onDeleted: attributeNames.length <= 1
                                            ? null
                                            : () {
                                                setDialogState(() {
                                                  attributeNames.remove(name);
                                                  attrControllers[name]?.dispose();
                                                  attrControllers.remove(name);
                                                });
                                              },
                                      );
                                    }),
                                    SizedBox(
                                      width: 170,
                                      height: 32,
                                      child: TextField(
                                        controller: newAttrInputCtrl,
                                        style: TextStyle(color: textPrimary, fontSize: 11),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Thêm thông số (RAM)...',
                                          hintStyle: TextStyle(fontSize: 10.5, color: textSecondary),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          suffixIcon: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 18),
                                            onPressed: () {
                                              final k = newAttrInputCtrl.text.trim();
                                              if (k.isNotEmpty && !attributeNames.contains(k)) {
                                                setDialogState(() {
                                                  attributeNames.add(k);
                                                  attrControllers[k] = TextEditingController();
                                                  newAttrInputCtrl.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        onSubmitted: (val) {
                                          final k = val.trim();
                                          if (k.isNotEmpty && !attributeNames.contains(k)) {
                                            setDialogState(() {
                                              attributeNames.add(k);
                                              attrControllers[k] = TextEditingController();
                                              newAttrInputCtrl.clear();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('Gợi ý nhanh:', style: TextStyle(fontSize: 10, color: textSecondary)),
                                    const SizedBox(width: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: standardPresets.where((s) => !attributeNames.contains(s)).map((sug) {
                                        return InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              if (!attributeNames.contains(sug)) {
                                                attributeNames.add(sug);
                                                attrControllers[sug] = TextEditingController();
                                              }
                                            });
                                          },
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
                          const SizedBox(height: 14),

                          // Hàng nhập thông số và Giá bán (Ngang hàng, không có chip gợi ý dưới ô input)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...attributeNames.map((attrName) {
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
                                            controller: attrControllers[attrName],
                                            style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText: 'Nhập $attrName...',
                                              hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (_) => setDialogState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // Giá bán (VNĐ) (*)
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
                                        controller: priceCtrl,
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
                                        onChanged: (_) => setDialogState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Dòng thiết lập ảnh riêng của biến thể (hỗ trợ cả Tải từ máy và Dán URL ảnh)
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
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: varImageCtrl.text.trim().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: Image.network(
                                            varImageCtrl.text.trim(),
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
                                  icon: isUploadingVarImg
                                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.cloud_upload_outlined, size: 15),
                                  label: Text(
                                    isUploadingVarImg ? 'Đang tải...' : 'Tải từ máy',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: borderColor),
                                  ),
                                  onPressed: isUploadingVarImg
                                      ? null
                                      : () async {
                                          final file = await FilePicker.pickFile(type: FileType.image);
                                          if (file != null) {
                                            setDialogState(() => isUploadingVarImg = true);
                                            final bytes = await file.readAsBytes();
                                            final url = await CloudinaryService.uploadImageBytes(
                                              bytes: bytes,
                                              fileName: file.name,
                                              backendBaseUrl: apiService.baseUrl,
                                              token: token,
                                            );
                                            setDialogState(() {
                                              isUploadingVarImg = false;
                                              if (url != null) varImageCtrl.text = url;
                                            });
                                          }
                                        },
                                ),
                                const SizedBox(width: 8),

                                // Dán đường dẫn URL ảnh
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: varImageCtrl,
                                      style: TextStyle(fontSize: 11.5, color: textPrimary),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        prefixIcon: const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                                        hintText: 'Hoặc dán đường dẫn URL ảnh riêng cho biến thể này (https://...)...',
                                        hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        suffixIcon: varImageCtrl.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.close_rounded, size: 14),
                                                tooltip: 'Xóa ảnh',
                                                onPressed: () => setDialogState(() => varImageCtrl.clear()),
                                              )
                                            : null,
                                      ),
                                      onChanged: (_) => setDialogState(() {}),
                                    ),
                                  ),
                                ),

                                // Nút dùng ảnh chính của sản phẩm nếu có
                                if (_currentProduct.imageUrl.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'Dùng ảnh chính sản phẩm',
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.copy_rounded, size: 13),
                                      label: const Text('Ảnh chính', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: borderColor),
                                      ),
                                      onPressed: () => setDialogState(() => varImageCtrl.text = _currentProduct.imageUrl),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Khung chọn chương trình khuyến mãi (Dropdown & Live Preview)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgSubtle,
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.discount_rounded, size: 15, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Chương trình khuyến mãi áp dụng',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: textPrimary),
                                    ),
                                    const Spacer(),
                                    if (selectedPromoId > 0)
                                      InkWell(
                                        onTap: () => setDialogState(() => selectedPromoId = 0),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.clear_rounded, size: 13, color: AppColors.danger),
                                            SizedBox(width: 3),
                                            Text(
                                              'Bỏ áp dụng',
                                              style: TextStyle(fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                AppDropdown<int>(
                                  value: selectedPromoId,
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: 0,
                                      child: Text(
                                        '-- Không áp dụng khuyến mãi --',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                                      ),
                                    ),
                                    ...availablePromos.map((p) {
                                      final isPercent = p.discountType == 'PERCENTAGE';
                                      final tag = isPercent ? '-${p.discountValue.toInt()}%' : '-${currencyFormat.format(p.discountValue)}';
                                      return DropdownMenuItem<int>(
                                        value: p.promotionId,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                p.name,
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedPromoId = val);
                                    }
                                  },
                                ),

                                if (selectedPromo != null && selectedPromoId > 0) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.success,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                selectedPromo.isPercentage
                                                    ? 'GIẢM ${selectedPromo.discountValue.toInt()}%'
                                                    : 'GIẢM -${currencyFormat.format(selectedPromo.discountValue)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                selectedPromo.name,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Text(
                                              'Đang áp dụng',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text('Giá gốc: ', style: TextStyle(fontSize: 11, color: textSecondary)),
                                            Text(
                                              currentPrice > 0 ? currencyFormat.format(currentPrice) : 'Chưa nhập giá',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                                decoration: currentPrice > 0 ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.success),
                                            Text('Giá sau khuyến mãi: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                                            Text(
                                              currentPrice > 0 ? currencyFormat.format(promoPrice) : '--',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            if (discountAmt > 0)
                                              Text(
                                                '(Tiết kiệm ${currencyFormat.format(discountAmt)})',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Biến thể này hiện sẽ bán theo giá gốc niêm yết, không qua chương trình khuyến mãi nào.',
                                    style: TextStyle(fontSize: 10.5, color: textSecondary, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              AppButton(
                label: 'Hủy bỏ',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(dialogCtx),
              ),
              AppButton(
                label: isEditing ? 'Lưu biến thể' : 'Tạo biến thể',
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  final rawPrice = priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                  final priceVal = double.tryParse(rawPrice) ?? 0;
                  if (priceVal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập giá bán hợp lệ cho biến thể!'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }

                  Map<String, String> finalAttrs = {};
                  for (var attr in attributeNames) {
                    final val = attrControllers[attr]?.text.trim() ?? '';
                    if (val.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập thông số "$attr"!'), backgroundColor: AppColors.danger),
                      );
                      return;
                    }
                    finalAttrs[attr] = val;
                  }

                  // Kiểm tra trùng lặp với biến thể khác
                  final currentSig = attributeNames.map((n) => '$n:${finalAttrs[n]}').join('|');
                  for (var v in _currentProduct.variants) {
                    if (isEditing && v.variantId == existingVariant.variantId) continue;
                    final otherSig = attributeNames.map((n) => '$n:${v.attributes[n] ?? ''}').join('|');
                    if (currentSig == otherSig) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bộ thông số này đã trùng với một biến thể khác của sản phẩm!'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                  }

                  final varName = finalAttrs.values.join(' - ');
                  final stockVal = isEditing ? existingVariant.stockQuantity : 0;

                  // Khởi tạo tóm tắt khuyến mãi nếu người dùng chọn chương trình khuyến mãi
                  VariantPromotionSummary? variantPromoSummary;
                  if (selectedPromo != null && selectedPromoId > 0) {
                    variantPromoSummary = VariantPromotionSummary(
                      hasPromotion: true,
                      promotionId: selectedPromo.promotionId,
                      promotionName: selectedPromo.name,
                      discountType: selectedPromo.discountType,
                      discountValue: selectedPromo.discountValue,
                      promotionalPrice: promoPrice,
                      discountAmount: discountAmt,
                    );
                  }

                  final newVariant = ProductVariant(
                    variantId: isEditing ? existingVariant.variantId : null,
                    productId: int.tryParse(_currentProduct.id),
                    productName: _currentProduct.name,
                    variantNameAttr: varName,
                    price: priceVal,
                    stockQuantity: stockVal,
                    imageUrl: varImageCtrl.text.trim().isNotEmpty ? varImageCtrl.text.trim() : null,
                    attributes: finalAttrs,
                    promotion: variantPromoSummary,
                    hasPromotion: variantPromoSummary != null,
                    isActive: varIsActive,
                  );

                  List<ProductVariant> updatedList = List.from(_currentProduct.variants);
                  if (isEditing) {
                    final idx = updatedList.indexWhere((v) => v.variantId == existingVariant.variantId);
                    if (idx >= 0) {
                      updatedList[idx] = newVariant;
                    } else {
                      updatedList.add(newVariant);
                    }
                  } else {
                    updatedList.add(newVariant);
                  }

                  // Chuẩn hóa toàn bộ danh sách biến thể:
                  // Đảm bảo các biến thể khác trong sản phẩm cũng không bị thiếu các thuộc tính bắt buộc
                  final List<ProductVariant> cleanedVariants = [];
                  for (var v in updatedList) {
                    Map<String, String> attrs = Map<String, String>.from(v.attributes);
                    for (var attr in attributeNames) {
                      if (!attrs.containsKey(attr) || attrs[attr]!.trim().isEmpty) {
                        attrs[attr] = 'Tiêu chuẩn';
                      }
                    }
                    cleanedVariants.add(ProductVariant(
                      variantId: v.variantId,
                      productId: v.productId,
                      productName: v.productName,
                      variantNameAttr: v.variantNameAttr,
                      price: v.price,
                      stockQuantity: v.stockQuantity,
                      imageUrl: v.imageUrl,
                      attributes: attrs,
                      promotion: v.promotion,
                      isActive: v.isActive,
                      createdAt: v.createdAt,
                    ));
                  }

                  // Tính lại dải giá sản phẩm
                  final allPrices = cleanedVariants.map((v) => v.price).toList();
                  final newMinPrice = allPrices.isNotEmpty ? allPrices.reduce(math.min) : 0.0;
                  final newMaxPrice = allPrices.isNotEmpty ? allPrices.reduce(math.max) : 0.0;

                  // Build updated product and save to backend
                  final productToSave = Product(
                    id: _currentProduct.id,
                    name: _currentProduct.name,
                    sku: _currentProduct.sku,
                    category: _currentProduct.category,
                    categoryId: _currentProduct.categoryId,
                    price: newMinPrice,
                    minPrice: newMinPrice,
                    maxPrice: newMaxPrice,
                    totalStock: _currentProduct.totalStock,
                    stock: _currentProduct.stock,
                    status: _currentProduct.status,
                    isActive: _currentProduct.isActive,
                    imageUrl: _currentProduct.imageUrl,
                    description: _currentProduct.description,
                    promotion: _currentProduct.promotion,
                    hasPromotion: _currentProduct.hasPromotion,
                    createdAt: _currentProduct.createdAt,
                    variantAttributes: attributeNames.isNotEmpty ? attributeNames : _currentProduct.variantAttributes,
                    variants: cleanedVariants,
                  );

                  Navigator.pop(dialogCtx);

                  setState(() => _isSaving = true);
                  final res = await apiService.updateProduct(productToSave, token: token);
                  if (res.success) {
                    // Đồng bộ variantId với danh sách biến thể tham gia khuyến mãi (nếu có thay đổi)
                    final promoChanged = selectedPromoId != originalPromoId;
                    if (promoChanged) {
                      int? resolvedVarId = isEditing ? existingVariant.variantId : null;
                      if (resolvedVarId == null || resolvedVarId <= 0) {
                        final freshProduct = await apiService.getProductById(_currentProduct.id, token: token);
                        if (freshProduct != null) {
                          for (var v in freshProduct.variants) {
                            final sig = attributeNames.map((n) => '$n:${v.attributes[n] ?? ''}').join('|');
                            if (sig == currentSig) {
                              resolvedVarId = v.variantId;
                              break;
                            }
                          }
                        }
                      }

                      if (resolvedVarId != null && resolvedVarId > 0) {
                        // 1. Gỡ khỏi khuyến mãi cũ nếu trước đó có áp dụng
                        if (originalPromoId > 0) {
                          try {
                            final oldPromo = await apiService.getPromotionById(originalPromoId, token: token);
                            if (oldPromo != null && oldPromo.variantIds.contains(resolvedVarId)) {
                              final updatedOldVarIds = List<int>.from(oldPromo.variantIds)..remove(resolvedVarId);
                              final updatedOldPromo = oldPromo.copyWith(variantIds: updatedOldVarIds);
                              await apiService.updatePromotion(originalPromoId, updatedOldPromo, token: token);
                            }
                          } catch (e) {
                            debugPrint('Lỗi gỡ biến thể khỏi khuyến mãi cũ: $e');
                          }
                        }

                        // 2. Thêm vào khuyến mãi mới nếu có chọn
                        if (selectedPromoId > 0) {
                          try {
                            final newPromo = await apiService.getPromotionById(selectedPromoId, token: token);
                            if (newPromo != null && !newPromo.variantIds.contains(resolvedVarId)) {
                              final updatedNewVarIds = Set<int>.from(newPromo.variantIds)..add(resolvedVarId);
                              final updatedNewPromo = newPromo.copyWith(variantIds: updatedNewVarIds.toList());
                              await apiService.updatePromotion(selectedPromoId, updatedNewPromo, token: token);
                            }
                          } catch (e) {
                            debugPrint('Lỗi thêm biến thể vào khuyến mãi mới: $e');
                          }
                        }
                      }
                    }
                  }

                  if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
                    );
                    if (res.success) {
                      widget.onProductUpdated();
                      _loadFullDetails();
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteVariant(ProductVariant variant) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa biến thể'),
        content: Text('Bạn có chắc chắn muốn xóa biến thể "${variant.variantName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa biến thể', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      List<ProductVariant> updatedList = List.from(_currentProduct.variants);
      updatedList.removeWhere((v) => v.variantId == variant.variantId);

      final productToSave = Product(
        id: _currentProduct.id,
        name: _currentProduct.name,
        sku: _currentProduct.sku,
        category: _currentProduct.category,
        categoryId: _currentProduct.categoryId,
        price: _currentProduct.price,
        status: _currentProduct.status,
        isActive: _currentProduct.isActive,
        imageUrl: _currentProduct.imageUrl,
        description: _currentProduct.description,
        promotion: _currentProduct.promotion,
        hasPromotion: _currentProduct.hasPromotion,
        createdAt: _currentProduct.createdAt,
        variantAttributes: _currentProduct.variantAttributes,
        variants: updatedList,
      );

      setState(() => _isSaving = true);
      final res = await apiService.updateProduct(productToSave, token: token);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: res.success ? AppColors.success : AppColors.danger),
        );
        if (res.success) {
          widget.onProductUpdated();
          _loadFullDetails();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb Header
            Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Sản phẩm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                Text('  /  ', style: TextStyle(color: textSecondary, fontSize: 13)),
                Text(
                  _currentProduct.name,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),

            // Top Header Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _currentProduct.name,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          StatusBadge(
                            label: _currentProduct.isActive ? 'Active' : 'Ngừng bán',
                            isSuccess: _currentProduct.isActive,
                            isDanger: !_currentProduct.isActive,
                          ),
                          if (_currentProduct.hasPromotion) ...[
                            const SizedBox(width: 8),
                            PromotionBadge(productPromotion: _currentProduct.promotion),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã SKU: ${_currentProduct.sku} • Danh mục: ${_currentProduct.category} • ID: #${_currentProduct.id}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                  icon: _isSaving ? null : Icons.save_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: _isSaving ? null : _saveProductGeneralInfo,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Thông tin chung'),
                  Tab(text: 'Biến thể'),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // Tab Views Container
            SizedBox(
              height: 720,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(surfaceColor, borderColor, textPrimary, textSecondary, isDark),
                  _buildVariantsTab(surfaceColor, borderColor, textPrimary, textSecondary, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: GENERAL ---
  Widget _buildGeneralTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Edit Form (Left 65%)
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin chung sản phẩm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary)),
                      const SizedBox(height: AppTokens.space16),

                      AppTextField(
                        controller: _nameCtrl,
                        labelText: 'Tên sản phẩm (*)',
                        hintText: 'Nhập tên dòng sản phẩm',
                      ),
                      const SizedBox(height: AppTokens.space16),

                      if (_isLoadingCategories)
                        const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      else
                        AppDropdown<int>(
                          value: _categories.any((c) => int.tryParse(c.id) == _selectedCategoryId)
                              ? _selectedCategoryId
                              : (int.tryParse(_categories.first.id) ?? 1),
                          items: _categories.map((cat) {
                            final catId = int.tryParse(cat.id) ?? 1;
                            return DropdownMenuItem<int>(
                              value: catId,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategoryId = val);
                            }
                          },
                        ),
                      const SizedBox(height: AppTokens.space16),

                      AppTextField(
                        controller: _descCtrl,
                        labelText: 'Mô tả sản phẩm',
                        maxLines: 4,
                        hintText: 'Nhập mô tả chi tiết thông số, đặc điểm sản phẩm...',
                      ),
                      const SizedBox(height: AppTokens.space16),

                      Text('Ảnh đại diện chính (Main Image)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                              border: Border.all(color: borderColor),
                            ),
                            child: _imageUrlCtrl.text.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm - 1),
                                    child: Image.network(
                                      _imageUrlCtrl.text.trim(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image_outlined, color: AppColors.danger, size: 26),
                                            SizedBox(height: 4),
                                            Text('Lỗi ảnh', style: TextStyle(fontSize: 10, color: AppColors.danger)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_outlined, color: textSecondary, size: 32),
                                        const SizedBox(height: 4),
                                        Text('Chưa có ảnh', style: TextStyle(fontSize: 10, color: textSecondary)),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  controller: _imageUrlCtrl,
                                  hintText: 'Dán URL ảnh hoặc tải lên từ máy...',
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),
                                AppButton(
                                  label: _isUploadingMainImage ? 'Đang tải ảnh...' : 'Tải ảnh từ máy tính',
                                  icon: _isUploadingMainImage ? null : Icons.cloud_upload_outlined,
                                  variant: AppButtonVariant.primary,
                                  onPressed: _isUploadingMainImage
                                      ? null
                                      : () async {
                                          final apiService = Provider.of<ApiService>(context, listen: false);
                                          final token = Provider.of<AuthProvider>(context, listen: false).token;
                                          final file = await FilePicker.pickFile(type: FileType.image);
                                          if (file != null) {
                                            setState(() => _isUploadingMainImage = true);
                                            final bytes = await file.readAsBytes();
                                            final url = await CloudinaryService.uploadImageBytes(
                                              bytes: bytes,
                                              fileName: file.name,
                                              backendBaseUrl: apiService.baseUrl,
                                              token: token,
                                            );
                                            setState(() {
                                              _isUploadingMainImage = false;
                                              if (url != null) _imageUrlCtrl.text = url;
                                            });
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space16),

                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                          Text(_isActive ? 'Trạng thái: Đang kinh doanh (Active)' : 'Trạng thái: Tạm ngừng kinh doanh', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space16),

              // Read-Only Backend Calculated Summary (Right 35%)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.space20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('Tổng quan tính toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Các chỉ số dưới đây được tự động tính toán dựa trên dữ liệu biến thể từ Backend API. Không sửa thủ công.', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const Divider(height: 24),

                      _buildReadOnlySummaryRow('Giá nhỏ nhất:', currencyFormat.format(_currentProduct.minPrice), textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Giá lớn nhất:', currencyFormat.format(_currentProduct.maxPrice), textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Tổng tồn kho:', '${_currentProduct.totalStock} sản phẩm', textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Số lượng biến thể:', '${_currentProduct.variants.length} biến thể', textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Ngày khởi tạo:', _currentProduct.createdAt != null ? dateFormat.format(_currentProduct.createdAt!) : 'N/A', textPrimary, textSecondary),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Khoảng giá hiển thị: ',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ),
                            ProductPriceRange(product: _currentProduct, compact: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySummaryRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }

  // --- TAB 2: VARIANTS ---
  Widget _buildVariantsTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      children: [
        // Variants Table Action Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách biến thể (${_currentProduct.variants.length})',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                ),
                Text('Quản lý thông số giá, số lượng tồn kho và thuộc tính động từng biến thể', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
            const Spacer(),
            AppButton(
              label: 'Thêm biến thể mới',
              icon: Icons.add_circle_outline_rounded,
              variant: AppButtonVariant.primary,
              onPressed: () => _showAddEditVariantDialog(),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),

        // Variants Table Container
        Expanded(
          child: DataTableContainer(
            child: _currentProduct.variants.isEmpty
                ? const EmptyState(
                    title: 'Sản phẩm chưa có biến thể nào',
                    message: 'Nhấn nút "Thêm biến thể mới" ở trên để tạo biến thể đầu tiên cho dòng sản phẩm này.',
                    icon: Icons.style_outlined,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: 14,
                              horizontalMargin: 12,
                              headingRowHeight: 40,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 56,
                              headingRowColor: WidgetStateProperty.all(
                                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              ),
                              columns: const [
                                DataColumn(label: Text('Tên biến thể', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Thuộc tính (Attributes)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Giá niêm yết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Giá khuyến mãi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Khuyến mãi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                              ],
                              rows: _currentProduct.variants.map((v) {
                                final hasVarPromo = v.promotion != null && v.promotion!.hasPromotion;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        v.variantName,
                                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5),
                                      ),
                                    ),
                                    DataCell(
                                      VariantAttributesView(attributes: v.attributes, isChipStyle: true),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(v.price),
                                        style: TextStyle(
                                          color: hasVarPromo ? textSecondary : textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          decoration: hasVarPromo ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      hasVarPromo
                                          ? Text(
                                              currencyFormat.format(v.promotion!.promotionalPrice),
                                              style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 12.5),
                                            )
                                          : Text('-', style: TextStyle(color: textSecondary, fontSize: 12)),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${v.stockQuantity}',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildVariantStockBadge(v.stockQuantity, isDark),
                                          if (v.stockQuantity <= 10) ...[
                                            const SizedBox(width: 8),
                                            Tooltip(
                                              message: 'Tạo phiếu nhập hàng (PO) cho biến thể này',
                                              child: InkWell(
                                                onTap: () {
                                                  widget.onBack();
                                                  Provider.of<NavigationProvider>(context, listen: false).setIndex(6);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Đã chuyển sang "Phiếu nhập hàng". Hãy tạo đơn nhập bổ sung cho "${v.variantName}".'),
                                                      backgroundColor: AppColors.primary,
                                                      duration: const Duration(seconds: 4),
                                                    ),
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(4),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.4)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.add_shopping_cart_rounded, size: 10, color: Color(0xFFEA580C)),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        '+ Nhập hàng',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFFEA580C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      PromotionBadge(variantPromotion: v.promotion, isVariant: true),
                                    ),
                                    DataCell(
                                      StatusBadge(
                                        label: v.isActive ? 'Active' : 'Khóa',
                                        isSuccess: v.isActive,
                                        isDanger: !v.isActive,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                            tooltip: 'Chỉnh sửa biến thể',
                                            onPressed: () => _showAddEditVariantDialog(v),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                            tooltip: 'Xóa biến thể',
                                            onPressed: () => _deleteVariant(v),
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
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantStockBadge(int stock, bool isDark) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;
    IconData icon;

    if (stock == 0) {
      label = 'Hết hàng';
      textColor = const Color(0xFFDC2626);
      bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFDC2626).withValues(alpha: 0.3);
      icon = Icons.cancel_rounded;
    } else if (stock <= 10) {
      label = 'Sắp hết';
      textColor = const Color(0xFFEA580C);
      bgColor = isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFEA580C).withValues(alpha: 0.3);
      icon = Icons.report_problem_rounded;
    } else if (stock <= 20) {
      label = 'Tồn kho thấp';
      textColor = isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309);
      bgColor = isDark ? const Color(0xFF422006) : const Color(0xFFFEFCE8);
      borderColor = const Color(0xFFEAB308).withValues(alpha: 0.3);
      icon = Icons.inventory_2_outlined;
    } else {
      label = 'Còn hàng';
      textColor = const Color(0xFF16A34A);
      bgColor = isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF16A34A).withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
