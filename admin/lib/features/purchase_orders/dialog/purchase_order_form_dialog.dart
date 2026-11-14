import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/models/product.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';

/// Mô tả tùy chọn biến thể sản phẩm hiển thị trong danh sách gợi ý chọn hàng nhập kho.
class PurchaseOrderVariantOption {
  final int variantId;
  final int productId;
  final String productName;
  final String variantName;
  final String fullName;
  final double defaultPrice;
  final int stockQuantity;
  final String? imageUrl;
  final bool isActive;

  const PurchaseOrderVariantOption({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.fullName,
    required this.defaultPrice,
    required this.stockQuantity,
    this.imageUrl,
    this.isActive = true,
  });
}

class _POItemRowInput {
  final PurchaseOrderVariantOption selectedVariant;
  final TextEditingController importPriceCtrl;
  final TextEditingController quantityCtrl;

  _POItemRowInput({
    required this.selectedVariant,
    double importPrice = 0,
    int quantity = 1,
  })  : importPriceCtrl = TextEditingController(
          text: importPrice > 0
              ? NumberFormat('#,###', 'en_US').format(importPrice.toInt())
              : (selectedVariant.defaultPrice > 0
                  ? NumberFormat('#,###', 'en_US')
                      .format(selectedVariant.defaultPrice.toInt())
                  : ''),
        ),
        quantityCtrl =
            TextEditingController(text: quantity > 0 ? quantity.toString() : '1');

  double get importPrice {
    final clean =
        importPriceCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    return double.tryParse(clean) ?? 0;
  }

  /// Trả về `0` khi ô số lượng trống hoặc không hợp lệ để không âm thầm lưu thành `1`.
  int get quantity {
    final clean =
        quantityCtrl.text.replaceAll(',', '').replaceAll('.', '').trim();
    if (clean.isEmpty) return 0;
    return int.tryParse(clean) ?? 0;
  }

  double get totalPrice => importPrice * quantity;

  void dispose() {
    importPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}

/// Hộp thoại tạo mới hoặc chỉnh sửa phiếu nhập hàng cùng danh sách biến thể nhập kho.
class PurchaseOrderFormDialog extends StatefulWidget {
  final PurchaseOrder? existingPo;
  final List<Supplier> suppliers;
  final List<PurchaseOrderVariantOption> variantOptions;
  final ApiService apiService;
  final String? token;
  final VoidCallback onSaved;

  const PurchaseOrderFormDialog({
    super.key,
    required this.existingPo,
    required this.suppliers,
    required this.variantOptions,
    required this.apiService,
    required this.token,
    required this.onSaved,
  });

  /// Chuyển danh sách sản phẩm kèm biến thể sang danh sách tùy chọn phẳng cho form nhập hàng.
  static List<PurchaseOrderVariantOption> buildVariantOptions(
    List<Product> products,
  ) {
    final options = <PurchaseOrderVariantOption>[];
    for (final p in products) {
      if (p.variants.isEmpty) continue;
      for (final v in p.variants) {
        final vId = v.variantId ?? 0;
        if (vId <= 0) continue;
        final vName = v.variantName;
        options.add(
          PurchaseOrderVariantOption(
            variantId: vId,
            productId: int.tryParse(p.id) ?? 0,
            productName: p.name,
            variantName: vName,
            fullName: '${p.name} ($vName)',
            defaultPrice: v.price > 0 ? v.price : p.price,
            stockQuantity: v.stockQuantity,
            imageUrl:
                v.imageUrl?.isNotEmpty == true ? v.imageUrl : p.imageUrl,
            isActive: p.isActive && v.isActive,
          ),
        );
      }
    }
    return options;
  }

  @override
  State<PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState extends State<PurchaseOrderFormDialog> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static const int _maxItemQuantity = 100000;
  static const int _maxNoteLength = 1000;

  late int _selectedSupplierId;
  late bool _oldSupplierMissing;
  late String _selectedStatus;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;

  final List<_POItemRowInput> _itemRows = [];
  String _searchQuery = '';
  bool _showDropdown = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.existingPo != null;
    final po = widget.existingPo;

    if (isEditing &&
        widget.suppliers.any((s) => int.tryParse(s.id) == po!.supplierId)) {
      _selectedSupplierId = po!.supplierId;
      _oldSupplierMissing = false;
    } else {
      _selectedSupplierId = widget.suppliers.isNotEmpty
          ? (int.tryParse(widget.suppliers.first.id) ?? 0)
          : 0;
      _oldSupplierMissing = isEditing;
    }

    // Khi tạo mới hoặc sửa trên form: chỉ cho lưu DRAFT hoặc COMPLETE.
    final rawStatus = isEditing ? po!.status.toUpperCase() : 'DRAFT';
    _selectedStatus =
        (rawStatus == 'COMPLETE' || rawStatus == 'COMPLETED')
            ? 'COMPLETE'
            : 'DRAFT';

    _noteCtrl = TextEditingController(text: isEditing ? po!.note : '');
    _searchCtrl = TextEditingController();
    _searchFocusNode = FocusNode();

    // Khởi tạo mặt hàng: Nếu chỉnh sửa thì nạp items cũ, nếu tạo mới thì ban đầu để RỖNG
    if (isEditing && po!.items.isNotEmpty) {
      for (final item in po.items) {
        final opt = widget.variantOptions.firstWhere(
          (o) => o.variantId == item.variantId,
          orElse: () => PurchaseOrderVariantOption(
            variantId: item.variantId,
            productId: item.productId ?? 0,
            productName: item.productName,
            variantName: item.variantName,
            fullName: item.fullName,
            defaultPrice: item.importPrice,
            stockQuantity: 0,
          ),
        );
        _itemRows.add(
          _POItemRowInput(
            selectedVariant: opt,
            importPrice: item.importPrice,
            quantity: item.quantity,
          ),
        );
      }
    }

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
          _showDropdown = q.isNotEmpty;
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchCtrl.text.trim().isNotEmpty) {
        setState(() {
          _showDropdown = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    for (final r in _itemRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addVariantToPo(PurchaseOrderVariantOption variant) {
    final existingIdx = _itemRows
        .indexWhere((r) => r.selectedVariant.variantId == variant.variantId);
    if (existingIdx != -1 &&
        _itemRows[existingIdx].quantity >= _maxItemQuantity) {
      AppToast.warning(
        context,
        'Số lượng tối đa cho mỗi mặt hàng là 100,000.',
      );
      return;
    }
    setState(() {
      if (existingIdx != -1) {
        final row = _itemRows[existingIdx];
        final nextQty = (row.quantity + 1).clamp(1, _maxItemQuantity);
        row.quantityCtrl.text = nextQty.toString();
      } else {
        _itemRows.add(
          _POItemRowInput(
            selectedVariant: variant,
            importPrice: variant.defaultPrice,
            quantity: 1,
          ),
        );
      }
      _searchCtrl.clear();
      _searchQuery = '';
      _showDropdown = false;
    });
  }

  double get _totalCalc {
    double total = 0;
    for (final r in _itemRows) {
      total += r.totalPrice;
    }
    return total;
  }

  int get _totalQuantity {
    int qty = 0;
    for (final r in _itemRows) {
      qty += r.quantity;
    }
    return qty;
  }

  Future<void> _handleSave() async {
    if (_selectedSupplierId <= 0 || widget.suppliers.isEmpty) {
      AppToast.error(context, 'Vui lòng chọn nhà cung cấp hợp lệ.');
      return;
    }

    final noteText = _noteCtrl.text.trim();
    if (noteText.length > _maxNoteLength) {
      AppToast.error(
        context,
        'Ghi chú phiếu nhập không được vượt quá $_maxNoteLength ký tự.',
      );
      return;
    }

    if (_selectedStatus == 'COMPLETE') {
      final selectedSupplier = widget.suppliers
          .where((s) => int.tryParse(s.id) == _selectedSupplierId)
          .firstOrNull;
      if (selectedSupplier != null && !selectedSupplier.isActive) {
        AppToast.warning(
          context,
          'Nhà cung cấp "${selectedSupplier.name}" đã ngừng hợp tác. Vui lòng chọn nhà cung cấp đang hoạt động để hoàn thành phiếu.',
        );
        return;
      }
    }

    if (_itemRows.isEmpty) {
      AppToast.warning(
        context,
        'Vui lòng thêm ít nhất 1 mặt hàng vào phiếu nhập.',
      );
      return;
    }

    // Kiểm tra trùng lặp, trạng thái kinh doanh và tính hợp lệ của đơn giá & số lượng
    final seenVariantIds = <int>{};
    for (final r in _itemRows) {
      if (seenVariantIds.contains(r.selectedVariant.variantId)) {
        AppToast.warning(
          context,
          'Phát hiện biến thể "${r.selectedVariant.fullName}" bị chọn trùng lặp. Vui lòng gộp số lượng vào 1 dòng.',
        );
        return;
      }
      seenVariantIds.add(r.selectedVariant.variantId);

      if (!r.selectedVariant.isActive) {
        AppToast.warning(
          context,
          'Biến thể "${r.selectedVariant.fullName}" đã ngưng kinh doanh, vui lòng xóa khỏi phiếu trước khi lưu.',
        );
        return;
      }

      if (r.importPrice <= 0) {
        AppToast.error(
          context,
          'Đơn giá nhập của "${r.selectedVariant.fullName}" phải lớn hơn 0.',
        );
        return;
      }

      if (r.quantity <= 0) {
        AppToast.error(
          context,
          'Số lượng nhập của "${r.selectedVariant.fullName}" phải lớn hơn 0.',
        );
        return;
      }

      if (r.quantity > _maxItemQuantity) {
        AppToast.error(
          context,
          'Số lượng nhập của "${r.selectedVariant.fullName}" tối đa là 100,000.',
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final isEditing = widget.existingPo != null;
    final poItems = _itemRows
        .map(
          (r) => PurchaseOrderItem(
            variantId: r.selectedVariant.variantId,
            productId: r.selectedVariant.productId,
            productName: r.selectedVariant.productName,
            variantName: r.selectedVariant.variantName,
            importPrice: r.importPrice,
            quantity: r.quantity,
          ),
        )
        .toList();

    final po = PurchaseOrder(
      purchaseOrderId: isEditing ? widget.existingPo!.purchaseOrderId : 0,
      poCode: isEditing ? widget.existingPo!.poCode : '',
      supplierId: _selectedSupplierId,
      status: _selectedStatus,
      note: noteText,
      createdAt: isEditing ? widget.existingPo!.createdAt : DateTime.now(),
      totalCost: _totalCalc,
      totalItems: poItems.length,
      items: poItems,
    );

    final ApiResult result = isEditing
        ? await widget.apiService.updatePurchaseOrder(
            widget.existingPo!.purchaseOrderId,
            po,
            token: widget.token,
          )
        : await widget.apiService.createPurchaseOrder(
            po,
            token: widget.token,
          );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        Navigator.pop(context);
        widget.onSaved();
        AppToast.success(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Lưu phiếu nhập thành công!',
        );
      } else {
        AppToast.error(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Lưu phiếu nhập thất bại!',
        );
      }
    }
  }

  Widget _buildVariantThumbnail(String? imageUrl) {
    final placeholder = Container(
      width: 36,
      height: 36,
      color: Colors.black12,
      child: const Icon(Icons.devices, size: 16),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            )
          : placeholder,
    );
  }

  Widget _buildGeneralInfoSection(bool isEditing, Color textPrimary) {
    final hasSuppliers = widget.suppliers.isNotEmpty;
    final selectedSupplierValue = hasSuppliers
        ? (widget.suppliers.any((s) => int.tryParse(s.id) == _selectedSupplierId)
            ? _selectedSupplierId
            : (int.tryParse(widget.suppliers.first.id) ?? 1))
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhà cung cấp (*)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (!hasSuppliers)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'Chưa có nhà cung cấp khả dụng',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.danger,
                    ),
                  ),
                )
              else
                AppDropdown<int>(
                  value: selectedSupplierValue,
                  items: widget.suppliers.map((s) {
                    final sId = int.tryParse(s.id) ?? 1;
                    final label = !s.isActive ? '${s.name} [Ngừng HT]' : s.name;
                    return DropdownMenuItem<int>(
                      value: sId,
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSupplierId = val;
                        _oldSupplierMissing = false;
                      });
                    }
                  },
                ),
              if (_oldSupplierMissing) ...[
                const SizedBox(height: 4),
                const Text(
                  'Nhà cung cấp cũ của phiếu không còn tồn tại. Vui lòng chọn lại nhà cung cấp.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái (*)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              AppDropdown<String>(
                value: _selectedStatus == 'COMPLETE' ? 'COMPLETE' : 'DRAFT',
                items: isEditing
                    ? const [
                        DropdownMenuItem(
                          value: 'DRAFT',
                          child: Text(
                            'DRAFT (Bản nháp)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETE',
                          child: Text(
                            'COMPLETE (Nhập kho)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ]
                    : const [
                        // Khi tạo mới: CHỈ CÓ DRAFT hoặc COMPLETE
                        DropdownMenuItem(
                          value: 'DRAFT',
                          child: Text(
                            'DRAFT (Bản nháp - Lưu tạm)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETE',
                          child: Text(
                            'COMPLETE (Hoàn thành & Nhập kho ngay)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSearchSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required List<PurchaseOrderVariantOption> matchingVariants,
  }) {
    return TapRegion(
      onTapOutside: (_) {
        if (_showDropdown) {
          setState(() => _showDropdown = false);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tìm kiếm sản phẩm & biến thể để thêm vào phiếu nhập (*)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _searchCtrl,
          focusNode: _searchFocusNode,
          labelText: 'Tìm kiếm sản phẩm hoặc biến thể...',
          hintText:
              'Gõ tên sản phẩm, biến thể (ASUS, Sony, RAM, Màu...), mã ID...',
          prefixIcon: Icons.search_rounded,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchCtrl.clear();
                      _searchQuery = '';
                      _showDropdown = false;
                    });
                  },
                )
              : null,
        ),

        // Dropdown gợi ý biến thể sản phẩm
        if (_showDropdown && _searchQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            constraints: const BoxConstraints(maxHeight: 230),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: matchingVariants.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Không tìm thấy biến thể sản phẩm khớp với "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gợi ý sản phẩm & biến thể (${matchingVariants.length}):',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  setState(() => _showDropdown = false),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: matchingVariants.length,
                            separatorBuilder: (ctx, index) => Divider(
                              height: 1,
                              color: borderColor.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (ctx, idx) {
                              final item = matchingVariants[idx];
                              final existingRow = _itemRows
                                  .where(
                                    (r) =>
                                        r.selectedVariant.variantId ==
                                        item.variantId,
                                  )
                                  .firstOrNull;
                              final isAdded = existingRow != null;

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                leading: _buildVariantThumbnail(item.imageUrl),
                                title: Text(
                                  item.fullName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                subtitle: Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      'Giá niêm yết: ${_currencyFormat.format(item.defaultPrice)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '| Tồn kho hiện tại: ${item.stockQuantity}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isAdded
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Chip(
                                            label: Text(
                                              'Đã thêm (${existingRow.quantity})',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: AppColors.success
                                                .withValues(alpha: 0.12),
                                            side: BorderSide.none,
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            avatar: const Icon(
                                              Icons.check_circle_rounded,
                                              size: 13,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                            tooltip: 'Thêm +1 số lượng',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 26,
                                              minHeight: 26,
                                            ),
                                            onPressed: () =>
                                                _addVariantToPo(item),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 13,
                                        ),
                                        label: const Text(
                                          'Thêm vào phiếu',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        onPressed: () => _addVariantToPo(item),
                                      ),
                                onTap: () => _addVariantToPo(item),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
      ),
    );
  }

  Widget _buildItemRow({
    required int index,
    required _POItemRowInput row,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isInactive = !row.selectedVariant.isActive;
    final canIncrement = row.quantity < _maxItemQuantity;

    final indexText = Text(
      '#${index + 1}',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: textSecondary,
      ),
    );

    final thumbnail = _buildVariantThumbnail(row.selectedVariant.imageUrl);

    final variantInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                row.selectedVariant.fullName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isInactive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Ngưng KD',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Giá niêm yết: ${_currencyFormat.format(row.selectedVariant.defaultPrice)}',
          style: TextStyle(fontSize: 11, color: textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final stockBadge = Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tồn hiện tại',
            style: TextStyle(fontSize: 9.5, color: textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${row.selectedVariant.stockQuantity}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );

    final priceField = AppTextField(
      controller: row.importPriceCtrl,
      labelText: 'Đơn giá nhập (*)',
      hintText: 'VD: 15,000,000',
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      suffixIcon: Container(
        padding: const EdgeInsets.only(right: 8),
        alignment: Alignment.centerRight,
        width: 20,
        child: Text(
          '₫',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textSecondary,
          ),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );

    final qtyStepper = SizedBox(
      width: 110,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: row.quantity > 1
                ? () {
                    setState(() {
                      row.quantityCtrl.text = (row.quantity - 1).toString();
                    });
                  }
                : null,
          ),
          Expanded(
            child: AppTextField(
              controller: row.quantityCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              labelText: 'SL',
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              size: 18,
              color: canIncrement ? AppColors.primary : null,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: canIncrement
                ? () {
                    setState(() {
                      final nextQty = (row.quantity + 1).clamp(1, _maxItemQuantity);
                      row.quantityCtrl.text = nextQty.toString();
                    });
                  }
                : null,
          ),
        ],
      ),
    );

    final totalColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Thành tiền',
          style: TextStyle(fontSize: 9.5, color: textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          _currencyFormat.format(row.totalPrice),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        ),
      ],
    );

    final deleteButton = IconButton(
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.danger,
        size: 18,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: 'Xóa khỏi phiếu',
      onPressed: () {
        setState(() {
          row.dispose();
          _itemRows.removeAt(index);
        });
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInactive
              ? AppColors.danger.withValues(alpha: 0.45)
              : borderColor,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    indexText,
                    const SizedBox(width: 8),
                    thumbnail,
                    const SizedBox(width: 10),
                    Expanded(child: variantInfo),
                    const SizedBox(width: 8),
                    stockBadge,
                    const SizedBox(width: 4),
                    deleteButton,
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 3, child: priceField),
                    const SizedBox(width: 8),
                    qtyStepper,
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: totalColumn),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              indexText,
              const SizedBox(width: 8),
              thumbnail,
              const SizedBox(width: 10),
              Expanded(flex: 4, child: variantInfo),
              const SizedBox(width: 8),
              stockBadge,
              const SizedBox(width: 10),
              Expanded(flex: 3, child: priceField),
              const SizedBox(width: 10),
              qtyStepper,
              const SizedBox(width: 10),
              SizedBox(width: 110, child: totalColumn),
              const SizedBox(width: 6),
              deleteButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemRowsSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DANH SÁCH MẶT HÀNG NHẬP KHO (${_itemRows.length}):',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.primary,
              ),
            ),
            if (_itemRows.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    for (final r in _itemRows) {
                      r.dispose();
                    }
                    _itemRows.clear();
                  });
                },
                child: const Text(
                  'Bỏ tất cả mặt hàng',
                  style: TextStyle(fontSize: 11.5, color: AppColors.danger),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_itemRows.isEmpty)
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 30,
                    color: textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có mặt hàng nào trong phiếu nhập',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gõ từ khóa vào ô tìm kiếm ở trên để chọn và thêm sản phẩm vào phiếu nhập',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._itemRows.asMap().entries.map(
                (entry) => _buildItemRow(
                  index: entry.key,
                  row: entry.value,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final isEditing = widget.existingPo != null;

    final matchingVariants = _searchQuery.isEmpty
        ? <PurchaseOrderVariantOption>[]
        : widget.variantOptions.where((v) {
            if (!v.isActive) return false;
            final q = _searchQuery.toLowerCase();
            return v.productName.toLowerCase().contains(q) ||
                v.variantName.toLowerCase().contains(q) ||
                v.fullName.toLowerCase().contains(q) ||
                v.variantId.toString().contains(q);
          }).toList();

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.note_add_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'Sửa Phiếu Nhập Hàng (${widget.existingPo?.poCode})'
                        : 'Tạo Phiếu Nhập Hàng Mới',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
      content: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thông tin chung: Nhà cung cấp & Trạng thái
              _buildGeneralInfoSection(isEditing, textPrimary),
              const SizedBox(height: 12),

              // 2. Ghi chú
              AppTextField(
                controller: _noteCtrl,
                labelText:
                    'Ghi chú phiếu nhập (Số hóa đơn, đợt nhập, người phụ trách...)',
                hintText: 'Nhập thông tin chứng từ lô hàng...',
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 14),

              // 3. Tìm kiếm sản phẩm theo biến thể có dropdown gợi ý
              _buildVariantSearchSection(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
                matchingVariants: matchingVariants,
              ),
              const SizedBox(height: 12),

              // 4. Danh sách các mặt hàng nhập kho
              _buildItemRowsSection(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 10),

              // 5. Tổng kết chi phí & mặt hàng
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Tổng mặt hàng: ${_itemRows.length} biến thể | Tổng số lượng: $_totalQuantity sản phẩm',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'TỔNG TIỀN NHẬP: ${_currencyFormat.format(_totalCalc)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.primary,
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
          variant: AppButtonVariant.outline,
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        AppButton(
          label: isEditing ? 'Cập nhật phiếu nhập' : 'Tạo phiếu nhập hàng',
          variant: AppButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _handleSave,
        ),
      ],
    );
  }
}

