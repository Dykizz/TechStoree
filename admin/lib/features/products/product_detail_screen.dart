import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/product.dart';
import '../../core/models/category.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
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

  void _showAddEditVariantDialog([ProductVariant? existingVariant]) {
    final isEditing = existingVariant != null;
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final nameCtrl = TextEditingController(text: isEditing ? (existingVariant.variantNameAttr ?? '') : '');
    final initialPriceText = isEditing
        ? NumberFormat('#,###', 'en_US').format(existingVariant.price.toInt())
        : '';
    final priceCtrl = TextEditingController(text: initialPriceText);
    final varImageCtrl = TextEditingController(text: isEditing ? (existingVariant.imageUrl ?? '') : '');
    bool varIsActive = isEditing ? existingVariant.isActive : true;

    // Attributes Map state
    Map<String, TextEditingController> attrControllers = {};
    if (isEditing && existingVariant.attributes.isNotEmpty) {
      existingVariant.attributes.forEach((k, v) {
        attrControllers[k] = TextEditingController(text: v);
      });
    } else if (_currentProduct.variantAttributes.isNotEmpty) {
      for (var attrName in _currentProduct.variantAttributes) {
        attrControllers[attrName] = TextEditingController();
      }
    }

    final newAttrKeyCtrl = TextEditingController();
    final newAttrValCtrl = TextEditingController();
    bool isUploadingVarImg = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Provider.of<ThemeProvider>(dialogCtx).isDarkMode;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
            title: Row(
              children: [
                Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: AppTokens.space8),
                Text(
                  isEditing ? 'Chỉnh sửa biến thể' : 'Thêm biến thể sản phẩm mới',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: nameCtrl,
                      labelText: 'Tên biến thể (Ví dụ: 16GB RAM / 512GB SSD - Xanh)',
                      hintText: 'Nhập tên gọi hiển thị của biến thể',
                    ),
                    const SizedBox(height: AppTokens.space12),

                    AppTextField(
                      controller: priceCtrl,
                      labelText: 'Giá bán (VNĐ) (*)',
                      hintText: 'VD: 10,000,000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                    const SizedBox(height: AppTokens.space16),

                    // Dynamic Attributes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thuộc tính biến thể (Attributes)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Container(
                      padding: const EdgeInsets.all(AppTokens.space12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                      ),
                      child: Column(
                        children: [
                          if (attrControllers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Chưa có thuộc tính nào được thêm.', style: TextStyle(color: textSecondary, fontSize: 11)),
                            ),

                          ...attrControllers.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      '${entry.key}:',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextField(
                                        controller: entry.value,
                                        style: TextStyle(color: textPrimary, fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Nhập giá trị (${entry.key})',
                                          hintStyle: TextStyle(color: textSecondary, fontSize: 11),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                                    tooltip: 'Xóa thuộc tính',
                                    onPressed: () {
                                      setDialogState(() {
                                        entry.value.dispose();
                                        attrControllers.remove(entry.key);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),

                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 34,
                                  child: TextField(
                                    controller: newAttrKeyCtrl,
                                    style: TextStyle(color: textPrimary, fontSize: 11),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Tên thuộc tính (RAM, Storage...)',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 34,
                                  child: TextField(
                                    controller: newAttrValCtrl,
                                    style: TextStyle(color: textPrimary, fontSize: 11),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Giá trị (16GB, 512GB...)',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: const Size(0, 34),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: () {
                                  final k = newAttrKeyCtrl.text.trim();
                                  final v = newAttrValCtrl.text.trim();
                                  if (k.isNotEmpty) {
                                    setDialogState(() {
                                      attrControllers[k] = TextEditingController(text: v);
                                      newAttrKeyCtrl.clear();
                                      newAttrValCtrl.clear();
                                    });
                                  }
                                },
                                child: const Text('+ Thêm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.space12),

                    // Variant Image Upload
                    Text('Ảnh biến thể (URL / Cloudinary)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (varImageCtrl.text.trim().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              varImageCtrl.text.trim(),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.black12,
                                child: const Icon(Icons.image_not_supported, size: 22),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.image, size: 24, color: Colors.grey),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTextField(
                            controller: varImageCtrl,
                            hintText: 'Nhập URL ảnh biến thể hoặc tải lên...',
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          icon: isUploadingVarImg ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file_rounded, size: 18),
                          tooltip: 'Tải ảnh biến thể từ máy tính',
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
                      ],
                    ),
                    const SizedBox(height: AppTokens.space12),

                    // Active Switch & Promotion summary
                    Row(
                      children: [
                        Switch(
                          value: varIsActive,
                          onChanged: (val) => setDialogState(() => varIsActive = val),
                        ),
                        Text(varIsActive ? 'Biến thể đang kinh doanh (Active)' : 'Ngừng kinh doanh biến thể', style: TextStyle(color: textPrimary, fontSize: 12)),
                      ],
                    ),

                    if (isEditing && existingVariant.promotion != null && existingVariant.promotion!.hasPromotion) ...[
                      const SizedBox(height: 8),
                      PromotionBadge(variantPromotion: existingVariant.promotion, isVariant: true),
                    ],
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
                  final stockVal = isEditing ? existingVariant.stockQuantity : 0;

                  Map<String, String> finalAttrs = {};
                  attrControllers.forEach((k, ctrl) {
                    if (ctrl.text.trim().isNotEmpty) {
                      finalAttrs[k] = ctrl.text.trim();
                    }
                  });

                  final newVariant = ProductVariant(
                    variantId: isEditing ? existingVariant.variantId : null,
                    productId: int.tryParse(_currentProduct.id),
                    productName: _currentProduct.name,
                    variantNameAttr: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                    price: priceVal,
                    stockQuantity: stockVal,
                    imageUrl: varImageCtrl.text.trim().isNotEmpty ? varImageCtrl.text.trim() : null,
                    attributes: finalAttrs,
                    promotion: isEditing ? existingVariant.promotion : null,
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

                  // Build updated product and save to backend
                  final productToSave = Product(
                    id: _currentProduct.id,
                    name: _currentProduct.name,
                    sku: _currentProduct.sku,
                    category: _currentProduct.category,
                    categoryId: _currentProduct.categoryId,
                    price: _currentProduct.price,
                    minPrice: _currentProduct.minPrice,
                    maxPrice: _currentProduct.maxPrice,
                    totalStock: _currentProduct.totalStock,
                    stock: _currentProduct.stock,
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

                  Navigator.pop(dialogCtx);

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
                          Text('Tổng quan tính toán (Calculated Summary)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Các chỉ số dưới đây được tự động tính toán dựa trên dữ liệu biến thể từ Backend API. Không sửa thủ công.', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const Divider(height: 24),

                      _buildReadOnlySummaryRow('Giá nhỏ nhất (minPrice):', currencyFormat.format(_currentProduct.minPrice), textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Giá lớn nhất (maxPrice):', currencyFormat.format(_currentProduct.maxPrice), textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Tổng tồn kho (totalStock):', '${_currentProduct.totalStock} sản phẩm', textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Số lượng biến thể:', '${_currentProduct.variants.length} biến thể', textPrimary, textSecondary),
                      _buildReadOnlySummaryRow('Ngày khởi tạo (createdAt):', _currentProduct.createdAt != null ? dateFormat.format(_currentProduct.createdAt!) : 'N/A', textPrimary, textSecondary),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFFDBEAFE)),
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
                  'Danh sách Biến thể (${_currentProduct.variants.length})',
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
                                DataColumn(label: Text('Ảnh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
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
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          v.imageUrl?.isNotEmpty == true ? v.imageUrl! : _currentProduct.imageUrl,
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(width: 38, height: 38, color: Colors.black12, child: const Icon(Icons.devices, size: 20)),
                                        ),
                                      ),
                                    ),
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
                                      Text(
                                        '${v.stockQuantity}',
                                        style: TextStyle(
                                          color: v.stockQuantity > 5 ? textPrimary : (v.stockQuantity > 0 ? AppColors.warning : AppColors.danger),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
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


}
