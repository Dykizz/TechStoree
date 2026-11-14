import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/models/purchase_order.dart';
import '../../core/models/supplier.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/data_table_container.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/master_detail_quick_view_layout.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/smooth_loading_wrapper.dart';
import 'dialog/purchase_order_detail_dialog.dart';
import 'dialog/purchase_order_form_dialog.dart';
import 'widgets/purchase_order_data_table.dart';
import 'widgets/purchase_order_filter_bar.dart';
import 'widgets/purchase_order_quick_view_panel.dart';

/// Màn hình chính quản lý phiếu nhập hàng: bộ lọc, bảng dữ liệu, panel xem nhanh và các thao tác tạo/sửa/duyệt phiếu.
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'Tất cả';
  int _selectedSupplierId = 0;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  PurchaseOrder? _selectedPo;
  bool _isLoadingPoItems = false;
  String? _quickViewError;
  int _quickViewRequestId = 0;
  bool _isActionBusy = false;
  final Map<int, List<PurchaseOrderItem>> _poItemsCache = {};

  late Future<PurchaseOrderPagedResult> _ordersFuture;
  late Future<List<Supplier>> _suppliersFuture;
  Object? _ordersError;
  int _ordersRequestId = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadData();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        (_selectedPo != null || _isLoadingPoItems || _quickViewError != null) &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      _closeQuickView();
      return true;
    }
    return false;
  }

  void _clearQuickViewState() {
    _quickViewRequestId++;
    _selectedPo = null;
    _isLoadingPoItems = false;
    _quickViewError = null;
  }

  void _loadData({bool reloadSuppliers = true}) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final reqId = ++_ordersRequestId;
    _ordersError = null;
    _ordersFuture = _fetchOrders(
      reqId,
      apiService.getPurchaseOrdersPaged(
        page: _currentPage,
        pageSize: _itemsPerPage,
        status: _selectedStatus,
        supplierId: _selectedSupplierId,
        search: _searchQuery,
        token: token,
        throwOnError: true,
      ),
    )..ignore();
    if (reloadSuppliers) {
      _suppliersFuture = apiService.getSuppliers(token: token);
    }
    _clearQuickViewState();
  }

  Future<PurchaseOrderPagedResult> _fetchOrders(
    int reqId,
    Future<PurchaseOrderPagedResult> request,
  ) async {
    try {
      final result = await request;
      if (mounted && _ordersRequestId == reqId) {
        if (result.items.isEmpty &&
            result.totalPages > 0 &&
            _currentPage > result.totalPages) {
          // Trang hiện tại vừa rỗng do xóa/duyệt phần tử cuối -> tự động lùi về trang cuối hợp lệ.
          setState(() {
            _currentPage = result.totalPages;
            _loadData(reloadSuppliers: false);
          });
          return result;
        }
        if (_ordersError != null) {
          setState(() => _ordersError = null);
        }
      }
      return result;
    } catch (e) {
      if (mounted && _ordersRequestId == reqId) {
        setState(() => _ordersError = e);
      }
      rethrow;
    }
  }

  String _extractFriendlyError(Object? error) {
    if (error == null) return 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
    var msg = error.toString().trim();
    const prefix = 'Exception:';
    if (msg.startsWith(prefix)) {
      msg = msg.substring(prefix.length).trim();
    }
    return msg.isNotEmpty
        ? msg
        : 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
  }

  Future<void> _fetchQuickViewItems(
    PurchaseOrder po,
    ApiService apiService,
    String? token,
  ) async {
    final reqId = ++_quickViewRequestId;
    setState(() {
      _isLoadingPoItems = true;
      _quickViewError = null;
    });

    try {
      final fullPo = await apiService.getPurchaseOrderById(
        po.purchaseOrderId,
        token: token,
      );
      if (!mounted || reqId != _quickViewRequestId) return;

      if (fullPo == null) {
        setState(() {
          _isLoadingPoItems = false;
          _quickViewError = 'Không thể tải chi tiết mặt hàng. Vui lòng thử lại.';
        });
        return;
      }

      setState(() {
        _poItemsCache[po.purchaseOrderId] = fullPo.items;
        _selectedPo = fullPo;
        _isLoadingPoItems = false;
        _quickViewError = null;
      });
    } catch (_) {
      if (!mounted || reqId != _quickViewRequestId) return;
      setState(() {
        _isLoadingPoItems = false;
        _quickViewError = 'Lỗi kết nối khi tải chi tiết mặt hàng.';
      });
    }
  }

  Future<void> _toggleQuickView(
    PurchaseOrder po,
    ApiService apiService,
    String? token,
  ) async {
    if (_selectedPo?.purchaseOrderId == po.purchaseOrderId) {
      _closeQuickView();
      return;
    }

    if (_poItemsCache.containsKey(po.purchaseOrderId)) {
      _quickViewRequestId++;
      setState(() {
        _selectedPo = po;
        _isLoadingPoItems = false;
        _quickViewError = null;
      });
      return;
    }

    setState(() {
      _selectedPo = po;
      _quickViewError = null;
    });
    await _fetchQuickViewItems(po, apiService, token);
  }

  void _closeQuickView() {
    if (_selectedPo != null || _isLoadingPoItems || _quickViewError != null) {
      setState(_clearQuickViewState);
    }
  }

  void _confirmStatusChange(
    BuildContext context,
    ApiService apiService,
    String? token,
    PurchaseOrder po,
    String targetStatus,
  ) {
    if (_isActionBusy) return;

    final isCompleting = targetStatus == 'COMPLETE';
    final dialogTitle = isCompleting
        ? 'Xác nhận Hoàn thành (COMPLETE)'
        : 'Xác nhận xóa phiếu nháp';
    final message = isCompleting
        ? 'Chốt phiếu nhập "${po.poCode}"? Sau khi hoàn thành, số lượng tồn kho của các biến thể sẽ được cộng vào hệ thống.'
        : 'Bạn có chắc muốn xóa vĩnh viễn phiếu nháp "${po.poCode}"? Thao tác này không thể hoàn tác và tồn kho giữ nguyên.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        title: Row(
          children: [
            Icon(
              isCompleting
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: isCompleting ? AppColors.success : AppColors.danger,
              size: 20,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                dialogTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          AppButton(
            label: 'Hủy bỏ',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: isCompleting ? 'Hoàn thành' : 'Xóa phiếu nháp',
            variant:
                isCompleting ? AppButtonVariant.primary : AppButtonVariant.danger,
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeStatusChange(apiService, token, po, targetStatus);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _executeStatusChange(
    ApiService apiService,
    String? token,
    PurchaseOrder po,
    String targetStatus,
  ) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);

    try {
      final isDeletingDraft =
          targetStatus == 'DELETE' ||
          targetStatus == 'CANCLE' ||
          targetStatus == 'CANCEL';
      late final ApiResult res;

      if (isDeletingDraft) {
        res = await apiService.deletePurchaseOrder(
          po.purchaseOrderId,
          token: token,
        );
      } else {
        // Danh sách PO từ GET /purchase-orders không trả items nên cần lấy từ cache hoặc chi tiết trước khi PUT.
        var itemsToSubmit = po.items.isNotEmpty
            ? po.items
            : (_poItemsCache[po.purchaseOrderId] ?? const <PurchaseOrderItem>[]);
        var sourcePo = po;

        if (itemsToSubmit.isEmpty) {
          final fullPo = await apiService.getPurchaseOrderById(
            po.purchaseOrderId,
            token: token,
          );
          if (!mounted) return;
          if (fullPo != null) {
            sourcePo = fullPo;
            itemsToSubmit = fullPo.items;
            _poItemsCache[po.purchaseOrderId] = fullPo.items;
          }
        }

        if (itemsToSubmit.isEmpty) {
          if (mounted) {
            AppToast.error(
              context,
              'Không thể tải danh sách mặt hàng của phiếu "${po.poCode}". Vui lòng thử lại.',
            );
          }
          return;
        }

        final updatedPo = PurchaseOrder(
          purchaseOrderId: sourcePo.purchaseOrderId,
          poCode: sourcePo.poCode,
          supplierId: sourcePo.supplierId,
          supplierName: sourcePo.supplierName,
          createdByUserId: sourcePo.createdByUserId,
          createdByName: sourcePo.createdByName,
          status: targetStatus,
          note: sourcePo.note,
          createdAt: sourcePo.createdAt,
          totalCost: sourcePo.totalCost,
          totalItems: itemsToSubmit.length,
          items: itemsToSubmit,
        );
        res = await apiService.updatePurchaseOrder(
          sourcePo.purchaseOrderId,
          updatedPo,
          token: token,
        );
      }

      if (!mounted) return;
      if (res.success) {
        _poItemsCache.remove(po.purchaseOrderId);
        setState(() => _loadData());
        AppToast.success(
          context,
          res.message.isNotEmpty ? res.message : 'Thao tác thành công!',
        );
      } else {
        AppToast.error(
          context,
          res.message.isNotEmpty ? res.message : 'Thao tác thất bại!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, _extractFriendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  Future<void> _openDetailDialog(
    BuildContext context,
    ApiService apiService,
    AuthProvider authProvider,
    int poId,
  ) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);

    try {
      final token = authProvider.token;
      final po = await apiService.getPurchaseOrderById(poId, token: token);
      if (!mounted) return;
      if (po == null) {
        AppToast.error(this.context, 'Không thể tải chi tiết phiếu nhập.');
        return;
      }

      final canUpdate = po.isDraft && authProvider.can('PurchaseOrders.Update');
      showDialog(
        context: this.context,
        builder: (_) => PurchaseOrderDetailDialog(
          purchaseOrder: po,
          onCancel: canUpdate
              ? () => _confirmStatusChange(
                    this.context,
                    apiService,
                    token,
                    po,
                    'DELETE',
                  )
              : null,
          onComplete: canUpdate
              ? () => _confirmStatusChange(
                    this.context,
                    apiService,
                    token,
                    po,
                    'COMPLETE',
                  )
              : null,
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(this.context, _extractFriendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  Future<void> _openCreateOrEditDialog(
    BuildContext context,
    ApiService apiService,
    String? token, {
    required List<Supplier> suppliers,
    int? existingPoId,
  }) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);

    try {
      final isEditing = existingPoId != null && existingPoId > 0;
      final productsFuture = apiService.getProductsWithVariants(token: token);
      final poFuture = isEditing
          ? apiService.getPurchaseOrderById(existingPoId, token: token)
          : Future<PurchaseOrder?>.value(null);
      final suppliersFuture = suppliers.isEmpty
          ? apiService.getSuppliers(token: token)
          : Future<List<Supplier>>.value(suppliers);

      final products = await productsFuture;
      final existingPo = await poFuture;
      final effectiveSuppliers = await suppliersFuture;

      if (!mounted) return;

      if (isEditing && existingPo == null) {
        AppToast.error(
          this.context,
          'Không thể tải thông tin phiếu nhập để chỉnh sửa.',
        );
        return;
      }

      final availableSuppliers = isEditing
          ? effectiveSuppliers
              .where(
                (s) =>
                    s.isActive || int.tryParse(s.id) == existingPo?.supplierId,
              )
              .toList()
          : effectiveSuppliers.where((s) => s.isActive).toList();
      if (availableSuppliers.isEmpty) {
        AppToast.warning(
          this.context,
          'Không có Nhà cung cấp nào đang hợp tác để lập phiếu nhập hàng.',
        );
        return;
      }

      final variantOptions =
          PurchaseOrderFormDialog.buildVariantOptions(products);
      if (variantOptions.isEmpty) {
        AppToast.warning(
          this.context,
          'Chưa có danh sách biến thể sản phẩm hợp lệ trong hệ thống.',
        );
        return;
      }

      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (_) => PurchaseOrderFormDialog(
          existingPo: existingPo,
          suppliers: availableSuppliers,
          variantOptions: variantOptions,
          apiService: apiService,
          token: token,
          onSaved: () {
            if (existingPoId != null) {
              _poItemsCache.remove(existingPoId);
            }
            setState(() => _loadData());
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(this.context, _extractFriendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final canUpdate = authProvider.can('PurchaseOrders.Update');

    return CachedFutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, supplierSnap) {
        final suppliers = supplierSnap.data ?? [];

        return CachedFutureBuilder<PurchaseOrderPagedResult>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasData = snapshot.hasData;
            final pagedResult = snapshot.data;
            final paginatedOrders = pagedResult?.items ?? const <PurchaseOrder>[];
            final totalItems = pagedResult?.totalCount ?? 0;
            final totalPages = pagedResult?.totalPages ?? 0;
            final safePage =
                totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
            final activeError = snapshot.error ?? _ordersError;
            final hasError = !isLoading && activeError != null;

            final Widget leftContent;
            if (hasError && (!hasData || paginatedOrders.isEmpty)) {
              leftContent = DataTableContainer(
                child: EmptyState(
                  title: 'Không thể tải danh sách phiếu nhập hàng',
                  message: _extractFriendlyError(activeError),
                  icon: Icons.error_outline_rounded,
                  action: AppButton(
                    label: 'Thử lại',
                    icon: Icons.refresh_rounded,
                    onPressed: () => setState(() => _loadData()),
                  ),
                ),
              );
            } else if (paginatedOrders.isEmpty) {
              leftContent = const DataTableContainer(
                child: EmptyState(
                  title: 'Chưa có phiếu nhập hàng nào',
                  message: 'Không tìm thấy phiếu nhập khớp với bộ lọc.',
                  icon: Icons.inventory_2_outlined,
                ),
              );
            } else {
              leftContent = PurchaseOrderDataTable(
                paginatedOrders: paginatedOrders,
                selectedPoId: _selectedPo?.purchaseOrderId,
                totalItems: totalItems,
                safePage: safePage,
                totalPages: totalPages,
                itemsPerPage: _itemsPerPage,
                canUpdate: canUpdate,
                errorMessage: hasError ? _extractFriendlyError(activeError) : null,
                onRetry: () => setState(() => _loadData(reloadSuppliers: false)),
                onRowTap: (po) => _toggleQuickView(
                  po,
                  apiService,
                  authProvider.token,
                ),
                onEdit: (po) => _openCreateOrEditDialog(
                  context,
                  apiService,
                  authProvider.token,
                  suppliers: suppliers,
                  existingPoId: po.purchaseOrderId,
                ),
                onComplete: (po) => _confirmStatusChange(
                  context,
                  apiService,
                  authProvider.token,
                  po,
                  'COMPLETE',
                ),
                onCancel: (po) => _confirmStatusChange(
                  context,
                  apiService,
                  authProvider.token,
                  po,
                  'DELETE',
                ),
                onViewDetail: (po) => _openDetailDialog(
                  context,
                  apiService,
                  authProvider,
                  po.purchaseOrderId,
                ),
                onPageChanged: (page) => setState(() {
                  _currentPage = page;
                  _loadData(reloadSuppliers: false);
                }),
                onItemsPerPageChanged: (size) => setState(() {
                  _itemsPerPage = size;
                  _currentPage = 1;
                  _loadData(reloadSuppliers: false);
                }),
              );
            }

            final Widget rightPanel;
            if (_selectedPo != null) {
              final selectedPo = _selectedPo!;
              final currentItems =
                  _poItemsCache[selectedPo.purchaseOrderId] ?? selectedPo.items;
              rightPanel = PurchaseOrderQuickViewPanel(
                key: ValueKey('po_panel_${selectedPo.purchaseOrderId}'),
                purchaseOrder: selectedPo,
                items: currentItems,
                isLoadingItems: _isLoadingPoItems,
                itemsError: _quickViewError,
                onRetryItems: () => _fetchQuickViewItems(
                  selectedPo,
                  apiService,
                  authProvider.token,
                ),
                onClose: _closeQuickView,
                onViewFullDetail: () => _openDetailDialog(
                  context,
                  apiService,
                  authProvider,
                  selectedPo.purchaseOrderId,
                ),
                onEdit: (selectedPo.isDraft && canUpdate)
                    ? () => _openCreateOrEditDialog(
                          context,
                          apiService,
                          authProvider.token,
                          suppliers: suppliers,
                          existingPoId: selectedPo.purchaseOrderId,
                        )
                    : null,
              );
            } else {
              rightPanel = const PurchaseOrderQuickViewPlaceholder(
                key: ValueKey('po_quick_view_placeholder'),
              );
            }

            return MasterDetailQuickViewLayout(
              padding: const EdgeInsets.all(AppTokens.space16),
              initialHeaderHeight: 145.0,
              hasSelection: _selectedPo != null,
              headerSection: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PageHeader(
                    title: 'Quản lý phiếu nhập hàng',
                    subtitle:
                        'Theo dõi đợt nhập hàng từ nhà cung cấp theo từng biến thể sản phẩm',
                    action: authProvider.can('PurchaseOrders.Create')
                        ? AppButton(
                            label: 'Tạo phiếu nhập hàng mới',
                            icon: Icons.add_rounded,
                            variant: AppButtonVariant.primary,
                            onPressed: _isActionBusy
                                ? null
                                : () => _openCreateOrEditDialog(
                                      context,
                                      apiService,
                                      authProvider.token,
                                      suppliers: suppliers,
                                    ),
                          )
                        : null,
                  ),
                  PurchaseOrderFilterBar(
                    searchController: _searchCtrl,
                    searchItems: paginatedOrders,
                    suppliers: suppliers,
                    selectedSupplierId: _selectedSupplierId,
                    selectedStatus: _selectedStatus,
                    onSearchSelected: (po) {
                      _searchCtrl.value = TextEditingValue(
                        text: po.poCode,
                        selection: TextSelection.collapsed(
                          offset: po.poCode.length,
                        ),
                      );
                      setState(() {
                        _searchQuery = po.poCode;
                        _currentPage = 1;
                        _loadData(reloadSuppliers: false);
                      });
                    },
                    onSearchSubmitted: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                      _loadData(reloadSuppliers: false);
                    }),
                    onSearchCleared: () => setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                      _loadData(reloadSuppliers: false);
                    }),
                    onSupplierChanged: (val) => setState(() {
                      _selectedSupplierId = val ?? 0;
                      _currentPage = 1;
                      _loadData(reloadSuppliers: false);
                    }),
                    onStatusChanged: (val) => setState(() {
                      _selectedStatus = val ?? 'Tất cả';
                      _currentPage = 1;
                      _loadData(reloadSuppliers: false);
                    }),
                  ),
                ],
              ),
              bodyWrapper: (child) => SmoothLoadingWrapper(
                isLoading: isLoading || _isActionBusy,
                hasData: hasData,
                blockInteraction: _isActionBusy,
                initialMinHeight: 420,
                child: child,
              ),
              leftTable: leftContent,
              rightPanel: rightPanel,
            );
          },
        );
      },
    );
  }
}
