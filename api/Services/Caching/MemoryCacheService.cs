using System.Collections.Concurrent;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Primitives;

namespace WebBanHang.Api.Services.Caching;

public class MemoryCacheService(
    IMemoryCache memoryCache, 
    IHttpContextAccessor? httpContextAccessor = null) : ICacheService
{
    private readonly ConcurrentDictionary<string, CancellationTokenSource> _prefixTokens = new();

    public async Task<T> GetOrCreateAsync<T>(
        string key, 
        Func<Task<T>> factory, 
        TimeSpan? absoluteExpiration = null, 
        TimeSpan? slidingExpiration = null, 
        string? prefix = null)
    {
        var httpContext = httpContextAccessor?.HttpContext;
        // Hỗ trợ kiểm thử tải: Client gửi Header 'X-Bypass-Cache: true' để ép truy vấn trực tiếp CSDL
        bool bypassCache = httpContext?.Request.Headers.ContainsKey("X-Bypass-Cache") == true;

        if (bypassCache)
        {
            // Bỏ comment dòng dưới nếu muốn giả lập độ trễ I/O CSDL (100ms) khi chạy benchmark tải:
            // await Task.Delay(100);
            return await factory();
        }

        var result = await memoryCache.GetOrCreateAsync(key, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = absoluteExpiration ?? TimeSpan.FromMinutes(5);
            entry.SlidingExpiration = slidingExpiration ?? TimeSpan.FromMinutes(2);

            if (!string.IsNullOrWhiteSpace(prefix))
            {
                var cts = _prefixTokens.GetOrAdd(prefix, _ => new CancellationTokenSource());
                entry.AddExpirationToken(new CancellationChangeToken(cts.Token));
            }

            // Bỏ comment dòng dưới nếu muốn giả lập độ trễ I/O CSDL (100ms) khi Cache Miss trong benchmark:
            // await Task.Delay(100);

            return await factory();
        });

        return result!;
    }

    public void Remove(string key) => memoryCache.Remove(key);

    public void RemoveByPrefix(string prefix)
    {
        if (_prefixTokens.TryRemove(prefix, out var cts))
        {
            cts.Cancel();
            cts.Dispose();
        }
    }
}
