namespace WebBanHang.Api.Common;

/// <summary>
/// Danh mục quyền hạn (Permissions) chuẩn hóa toàn hệ thống — nguồn sự thật duy nhất.
/// Quyền chỉ sinh ra từ alias <see cref="HasPermissionAttribute"/> trên endpoint; Quản trị viên
/// không thể tự thêm quyền, chỉ tạo vai trò và chọn quyền từ danh mục này.
/// </summary>
public static class AppPermissions
{
    public static class Categories
    {
        public const string View = "Categories.View";
        public const string Create = "Categories.Create";
        public const string Update = "Categories.Update";
        public const string Delete = "Categories.Delete";
    }

    public static class Products
    {
        public const string View = "Products.View";
        public const string Create = "Products.Create";
        public const string Update = "Products.Update";
        public const string Delete = "Products.Delete";
    }

    public static class Suppliers
    {
        public const string View = "Suppliers.View";
        public const string Create = "Suppliers.Create";
        public const string Update = "Suppliers.Update";
        public const string Delete = "Suppliers.Delete";
    }

    public static class PurchaseOrders
    {
        public const string View = "PurchaseOrders.View";
        public const string Create = "PurchaseOrders.Create";
        public const string Update = "PurchaseOrders.Update";
    }

    public static class Orders
    {
        public const string View = "Orders.View";
        public const string UpdateStatus = "Orders.UpdateStatus";
        public const string Cancel = "Orders.Cancel";
    }

    public static class Promotions
    {
        public const string View = "Promotions.View";
        public const string Create = "Promotions.Create";
        public const string Update = "Promotions.Update";
        public const string Delete = "Promotions.Delete";
    }

    public static class Vouchers
    {
        public const string View = "Vouchers.View";
        public const string Create = "Vouchers.Create";
        public const string Update = "Vouchers.Update";
        public const string Delete = "Vouchers.Delete";
        public const string Assign = "Vouchers.Assign";
    }

    public static class Surveys
    {
        public const string View = "Surveys.View";
        public const string Create = "Surveys.Create";
        public const string Update = "Surveys.Update";
        public const string Delete = "Surveys.Delete";
        public const string Assign = "Surveys.Assign";
    }

    public static class Users
    {
        public const string View = "Users.View";
        public const string Create = "Users.Create";
        public const string Update = "Users.Update";
        public const string Lock = "Users.Lock";
        public const string AssignRoles = "Users.AssignRoles";
    }

    public static class Roles
    {
        public const string View = "Roles.View";
        public const string Create = "Roles.Create";
        public const string Update = "Roles.Update";
        public const string Delete = "Roles.Delete";
    }

    // Tên phân hệ hiển thị cho Quản trị viên
    private const string MCategories = "Quản lý danh mục";
    private const string MProducts = "Quản lý sản phẩm";
    private const string MSuppliers = "Quản lý nhà cung cấp";
    private const string MPurchaseOrders = "Quản lý nhập hàng";
    private const string MOrders = "Quản lý đơn hàng";
    private const string MPromotions = "Quản lý khuyến mãi";
    private const string MVouchers = "Quản lý Voucher";
    private const string MSurveys = "Khảo sát & CRM";
    private const string MUsers = "Quản lý tài khoản";
    private const string MRoles = "Phân quyền hệ thống";

    // Quy ước Reserved: false -> bắt buộc có endpoint dùng alias, nếu không app từ chối khởi động.
    //                   true  -> chủ ý chưa gắn endpoint nào.
    public static readonly IReadOnlyList<PermissionMeta> Catalog =
    [
        new(Categories.View, MCategories, "Xem danh mục", "Xem danh sách và thông tin chi tiết danh mục sản phẩm", Reserved: true),
        new(Categories.Create, MCategories, "Thêm danh mục", "Tạo danh mục sản phẩm mới"),
        new(Categories.Update, MCategories, "Sửa danh mục", "Chỉnh sửa thông tin danh mục sản phẩm"),
        new(Categories.Delete, MCategories, "Xóa danh mục", "Xóa danh mục sản phẩm khỏi hệ thống"),
        new(Products.View, MProducts, "Xem sản phẩm", "Xem danh sách và chi tiết sản phẩm, biến thể", Reserved: true),
        new(Products.Create, MProducts, "Thêm sản phẩm", "Tạo mới sản phẩm và các biến thể"),
        new(Products.Update, MProducts, "Sửa sản phẩm", "Cập nhật thông tin, giá bán, tồn kho sản phẩm"),
        new(Products.Delete, MProducts, "Xóa sản phẩm", "Xóa hoặc vô hiệu hóa sản phẩm"),
        new(Suppliers.View, MSuppliers, "Xem nhà cung cấp", "Xem danh sách và chi tiết nhà cung cấp"),
        new(Suppliers.Create, MSuppliers, "Thêm nhà cung cấp", "Tạo thông tin nhà cung cấp mới"),
        new(Suppliers.Update, MSuppliers, "Sửa nhà cung cấp", "Cập nhật thông tin nhà cung cấp"),
        new(Suppliers.Delete, MSuppliers, "Xóa nhà cung cấp", "Xóa nhà cung cấp (xóa mềm)"),
        new(PurchaseOrders.View, MPurchaseOrders, "Xem đơn nhập hàng", "Xem danh sách phiếu nhập kho từ nhà cung cấp"),
        new(PurchaseOrders.Create, MPurchaseOrders, "Tạo đơn nhập hàng", "Lập phiếu nhập hàng mới và chi tiết sản phẩm nhập"),
        new(PurchaseOrders.Update, MPurchaseOrders, "Cập nhật đơn nhập hàng", "Cập nhật trạng thái phiếu nhập kho (Hoàn tất, hủy...)"),
        new(Orders.View, MOrders, "Xem đơn bán hàng", "Xem tất cả đơn hàng của khách hàng"),
        new(Orders.UpdateStatus, MOrders, "Cập nhật đơn hàng", "Chuyển trạng thái đơn hàng (Đã xác nhận, Đang giao, Đã giao...)"),
        new(Orders.Cancel, MOrders, "Hủy đơn hàng", "Hủy đơn hàng của khách hàng", Reserved: true),
        new(Promotions.View, MPromotions, "Xem khuyến mãi", "Xem danh sách chiến dịch khuyến mãi", Reserved: true),
        new(Promotions.Create, MPromotions, "Tạo khuyến mãi", "Tạo chương trình khuyến mãi mới"),
        new(Promotions.Update, MPromotions, "Sửa khuyến mãi", "Cập nhật chương trình khuyến mãi"),
        new(Promotions.Delete, MPromotions, "Xóa khuyến mãi", "Xóa chương trình khuyến mãi"),
        new(Vouchers.View, MVouchers, "Xem voucher", "Xem danh sách mã giảm giá / voucher"),
        new(Vouchers.Create, MVouchers, "Tạo voucher", "Tạo mã giảm giá mới"),
        new(Vouchers.Update, MVouchers, "Sửa voucher", "Cập nhật thông tin mã giảm giá"),
        new(Vouchers.Delete, MVouchers, "Xóa voucher", "Xóa mã giảm giá"),
        new(Vouchers.Assign, MVouchers, "Tặng voucher", "Phát voucher cho khách hàng", Reserved: true),
        new(Surveys.View, MSurveys, "Xem khảo sát", "Xem danh sách bảng khảo sát và kết quả trả lời"),
        new(Surveys.Create, MSurveys, "Tạo khảo sát", "Tạo chiến dịch khảo sát và câu hỏi"),
        new(Surveys.Update, MSurveys, "Sửa khảo sát", "Cập nhật thông tin và trạng thái khảo sát"),
        new(Surveys.Delete, MSurveys, "Xóa khảo sát", "Xóa chiến dịch khảo sát"),
        new(Surveys.Assign, MSurveys, "Giao khảo sát", "Gán khảo sát cho khách hàng mục tiêu"),
        new(Users.View, MUsers, "Xem người dùng", "Xem danh sách tài khoản khách hàng và nhân viên"),
        new(Users.Create, MUsers, "Tạo tài khoản", "Tạo tài khoản nhân viên mới"),
        new(Users.Update, MUsers, "Sửa người dùng", "Cập nhật thông tin tài khoản người dùng", Reserved: true),
        new(Users.Lock, MUsers, "Khóa / Mở khóa", "Khóa hoặc mở khóa tài khoản người dùng"),
        new(Users.AssignRoles, MUsers, "Gán vai trò", "Phân vai trò cho tài khoản"),
        new(Roles.View, MRoles, "Xem vai trò", "Xem danh sách vai trò và quyền hạn"),
        new(Roles.Create, MRoles, "Tạo vai trò", "Tạo vai trò mới và phân quyền"),
        new(Roles.Update, MRoles, "Sửa vai trò", "Chỉnh sửa tên vai trò và danh sách quyền"),
        new(Roles.Delete, MRoles, "Xóa vai trò", "Xóa vai trò tùy chỉnh")
    ];

    /// <summary>Tra cứu nhanh metadata quyền hạn theo mã (không phân biệt hoa thường).</summary>
    public static readonly IReadOnlyDictionary<string, PermissionMeta> ById =
        Catalog.ToDictionary(m => m.Id, StringComparer.OrdinalIgnoreCase);

    // Quyền mặc định cho vai trò hệ thống — chỉ áp cho vai trò chưa có quyền nào,
    // không bao giờ ghi đè cấu hình Quản trị viên đã thiết lập.
    public static readonly IReadOnlyDictionary<string, IReadOnlyList<string>> DefaultRolePermissions =
        new Dictionary<string, IReadOnlyList<string>>(StringComparer.OrdinalIgnoreCase)
        {
            ["WAREHOUSE_STAFF"] =
            [
                Categories.View, Categories.Create, Categories.Update,
                Products.View, Products.Create, Products.Update,
                Suppliers.View, Suppliers.Create, Suppliers.Update,
                PurchaseOrders.View, PurchaseOrders.Create, PurchaseOrders.Update
            ],
            ["SALES_STAFF"] =
            [
                Categories.View, Products.View,
                Orders.View, Orders.UpdateStatus, Orders.Cancel,
                Promotions.View, Promotions.Create, Promotions.Update, Promotions.Delete,
                Vouchers.View, Vouchers.Create, Vouchers.Update, Vouchers.Delete, Vouchers.Assign
            ],
            ["SURVEY_STAFF"] =
            [
                Surveys.View, Surveys.Create, Surveys.Update, Surveys.Delete, Surveys.Assign,
                Users.View
            ],
            ["USER"] = []
        };
}
