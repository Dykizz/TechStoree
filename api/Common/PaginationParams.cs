namespace WebBanHang.Api.Common;

public class PaginationParams
{
    private const int MaxPageSize = 100;
    private int _pageSize = 10;

    /// <summary>
    /// Số thứ tự trang cần lấy (bắt đầu từ 1)
    /// </summary>
    /// <example>1</example>
    public int Page { get; set; } = 1;

    /// <summary>
    /// Số lượng bản ghi trên một trang (mặc định 10, tối đa 100)
    /// </summary>
    /// <example>10</example>
    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value > MaxPageSize ? MaxPageSize : (value < 1 ? 10 : value);
    }

    /// <summary>
    /// Từ khóa tìm kiếm (theo mã, tên, ghi chú, v.v.)
    /// </summary>
    /// <example>ASUS</example>
    public string? Search { get; set; }

    /// <summary>
    /// Tiêu chí sắp xếp kết quả (ví dụ: createdAt, totalCost, poCode)
    /// </summary>
    /// <example>createdAt</example>
    public string? SortBy { get; set; }

    /// <summary>
    /// Thứ tự sắp xếp: true là tăng dần (A-Z, cũ đến mới), false là giảm dần (mới nhất trước)
    /// </summary>
    /// <example>false</example>
    public bool IsAscending { get; set; } = true;
}
