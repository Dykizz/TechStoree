namespace WebBanHang.Api.Services.Caching;

public static class CacheDurations
{
    public static class Products
    {
        public static readonly TimeSpan ListAbsolute = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan ListSliding = TimeSpan.FromMinutes(2);

        public static readonly TimeSpan DetailAbsolute = TimeSpan.FromMinutes(15);
        public static readonly TimeSpan DetailSliding = TimeSpan.FromMinutes(5);
    }

    public static class Categories
    {
        public static readonly TimeSpan Absolute = TimeSpan.FromMinutes(30);
        public static readonly TimeSpan Sliding = TimeSpan.FromMinutes(10);
    }

    public static class Promotions
    {
        public static readonly TimeSpan Absolute = TimeSpan.FromMinutes(15);
        public static readonly TimeSpan Sliding = TimeSpan.FromMinutes(5);
    }

    public static class Vouchers
    {
        public static readonly TimeSpan AvailableAbsolute = TimeSpan.FromMinutes(10);
        public static readonly TimeSpan AvailableSliding = TimeSpan.FromMinutes(3);

        public static readonly TimeSpan DetailAbsolute = TimeSpan.FromMinutes(15);
        public static readonly TimeSpan DetailSliding = TimeSpan.FromMinutes(5);

        public static readonly TimeSpan ListAbsolute = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan ListSliding = TimeSpan.FromMinutes(2);
    }

    public static class Roles
    {
        public static readonly TimeSpan PermissionsAbsolute = TimeSpan.FromHours(1);
        public static readonly TimeSpan PermissionsSliding = TimeSpan.FromMinutes(20);

        public static readonly TimeSpan RolesAbsolute = TimeSpan.FromHours(1);
        public static readonly TimeSpan RolesSliding = TimeSpan.FromMinutes(20);

        public static readonly TimeSpan DetailAbsolute = TimeSpan.FromHours(1);
        public static readonly TimeSpan DetailSliding = TimeSpan.FromMinutes(20);
    }

    public static class Suppliers
    {
        public static readonly TimeSpan ListAbsolute = TimeSpan.FromMinutes(30);
        public static readonly TimeSpan ListSliding = TimeSpan.FromMinutes(10);

        public static readonly TimeSpan DetailAbsolute = TimeSpan.FromMinutes(30);
        public static readonly TimeSpan DetailSliding = TimeSpan.FromMinutes(10);
    }
}
