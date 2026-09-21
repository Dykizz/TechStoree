namespace WebBanHang.Api.Common;

public class PaginationParams
{
    private const int MaxPageSize = 100;
    private int _pageSize = 10;

    public int Page { get; set; } = 1;

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value > MaxPageSize ? MaxPageSize : (value < 1 ? 10 : value);
    }

    public string? Search { get; set; }
    public string? SortBy { get; set; }
    public bool IsAscending { get; set; } = true;
}
