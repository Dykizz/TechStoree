namespace WebBanHang.Api.DTOs.Users;

/// <summary>
/// Báo cáo phân tích nhân khẩu học khách hàng (Độ tuổi và Sở thích công nghệ)
/// </summary>
public class DemographicsReportDto
{
    /// <summary>
    /// Tổng số lượng khách hàng trong hệ thống (vai trò USER / CUSTOMER)
    /// </summary>
    /// <example>150</example>
    public int TotalCustomers { get; set; }

    /// <summary>
    /// Số lượng khách hàng đã cập nhật ngày sinh
    /// </summary>
    /// <example>120</example>
    public int CustomersWithBirthDate { get; set; }

    /// <summary>
    /// Số lượng khách hàng đã cập nhật sở thích công nghệ
    /// </summary>
    /// <example>135</example>
    public int CustomersWithInterest { get; set; }

    /// <summary>
    /// Thống kê phân bố theo các nhóm độ tuổi
    /// </summary>
    public List<AgeGroupReportDto> AgeGroups { get; set; } = new();

    /// <summary>
    /// Thống kê phân bố theo phân khúc sở thích công nghệ
    /// </summary>
    public List<InterestGroupReportDto> Interests { get; set; } = new();
}

public class AgeGroupReportDto
{
    /// <summary>
    /// Mã định danh nhóm độ tuổi: UNDER_18, AGE_18_TO_24, AGE_25_TO_35, OVER_35, UNKNOWN
    /// </summary>
    /// <example>AGE_18_TO_24</example>
    public string GroupKey { get; set; } = string.Empty;

    /// <summary>
    /// Tên hiển thị nhóm tuổi
    /// </summary>
    /// <example>18 - 24 tuổi</example>
    public string GroupName { get; set; } = string.Empty;

    /// <summary>
    /// Số lượng khách hàng thuộc nhóm tuổi này
    /// </summary>
    /// <example>60</example>
    public int Count { get; set; }

    /// <summary>
    /// Tỷ lệ phần trăm trên tổng số khách hàng (0 - 100%)
    /// </summary>
    /// <example>40.0</example>
    public double Percentage { get; set; }
}

public class InterestGroupReportDto
{
    /// <summary>
    /// Mã nhóm sở thích: GAMING, OFFICE_STUDY, AUDIO_STUDIO, SMARTHOME, OTHER, NOT_SET
    /// </summary>
    /// <example>GAMING</example>
    public string Key { get; set; } = string.Empty;

    /// <summary>
    /// Tên hiển thị sở thích
    /// </summary>
    /// <example>Gaming &amp; Đồ họa</example>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Số lượng khách hàng chọn sở thích này
    /// </summary>
    /// <example>55</example>
    public int Count { get; set; }

    /// <summary>
    /// Tỷ lệ phần trăm (0 - 100%)
    /// </summary>
    /// <example>36.7</example>
    public double Percentage { get; set; }
}

/// <summary>
/// Tùy chọn sở thích công nghệ cho Dropdown lựa chọn trên giao diện Web &amp; Desktop
/// </summary>
public class TechInterestOptionDto
{
    /// <example>GAMING</example>
    public string Key { get; set; } = string.Empty;

    /// <example>Gaming &amp; Đồ họa</example>
    public string DisplayName { get; set; } = string.Empty;

    /// <example>Laptop Gaming, Chuột/Bàn phím cơ, Màn hình tần số quét cao</example>
    public string Description { get; set; } = string.Empty;
}
