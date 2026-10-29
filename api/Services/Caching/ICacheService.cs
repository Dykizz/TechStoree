namespace WebBanHang.Api.Services.Caching;

public interface ICacheService
{
    Task<T> GetOrCreateAsync<T>(
        string key, 
        Func<Task<T>> factory, 
        TimeSpan? absoluteExpiration = null, 
        TimeSpan? slidingExpiration = null, 
        string? prefix = null);

    void Remove(string key);

    void RemoveByPrefix(string prefix);
}

