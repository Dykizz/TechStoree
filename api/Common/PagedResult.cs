namespace WebBanHang.Api.Common;

public class PaginationMeta
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalItems { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalItems / PageSize) : 0;
    public bool HasPreviousPage => Page > 1;
    public bool HasNextPage => Page < TotalPages;
}

public class PagedResult<T>
{
    public List<T> Items { get; set; } = [];
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
