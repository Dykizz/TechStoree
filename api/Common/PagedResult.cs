namespace WebBanHang.Api.Common;

public class PaginationMeta
{
    /// <summary>
    /// Trang hiện tại (bắt đầu từ 1)
    /// </summary>
    /// <example>1</example>
    public int Page { get; set; }

    /// <summary>
    /// Số lượng bản ghi trên mỗi trang
    /// </summary>
    /// <example>10</example>
    public int PageSize { get; set; }

    /// <summary>
    /// Tổng số bản ghi thỏa mãn điều kiện lọc
    /// </summary>
    /// <example>1</example>
    public int TotalItems { get; set; }

    /// <summary>
    /// Tổng số trang
    /// </summary>
    /// <example>1</example>
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalItems / PageSize) : 0;

    /// <summary>
    /// Có trang trước hay không
    /// </summary>
    /// <example>false</example>
    public bool HasPreviousPage => Page > 1;

    /// <summary>
    /// Có trang kế tiếp hay không
    /// </summary>
    /// <example>false</example>
    public bool HasNextPage => Page < TotalPages;
}

public class PagedResult<T>
{
    /// <summary>
    /// Danh sách bản ghi trên trang hiện tại
    /// </summary>
    public List<T> Items { get; set; } = [];

    /// <summary>
    /// Thông tin phân trang
    /// </summary>
    public PaginationMeta Meta { get; set; } = new();

    public PagedResult() { }

    public PagedResult(List<T> items, int totalItems, int page, int pageSize)
    {
        Items = items;
        Meta = new PaginationMeta
        {
            Page = page,
            PageSize = pageSize,
            TotalItems = totalItems
        };
    }
}
