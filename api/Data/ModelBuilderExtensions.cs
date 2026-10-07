using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Data;

public static class ModelBuilderExtensions
{
    private class DummyDataWrapper
    {
        public List<Supplier>? Suppliers { get; set; }
        public List<Category>? Categories { get; set; }
        public List<Product>? Products { get; set; }
        public List<ProductVariant>? ProductVariants { get; set; }
        public List<Survey>? Surveys { get; set; }
        public List<SurveyQuestion>? SurveyQuestions { get; set; }
        public List<SurveyOption>? SurveyOptions { get; set; }
    }

    /// <summary>
    /// Nạp dữ liệu mẫu khởi tạo từ file Data/dummy_data.json giúp AppDbContext gọn gàng và dễ mở rộng.
    /// </summary>
    public static void SeedDummyData(this ModelBuilder modelBuilder)
    {
        var candidatePaths = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Data", "dummy_data.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Data", "dummy_data.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "api", "Data", "dummy_data.json"),
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "Data", "dummy_data.json")
        };

        string? jsonPath = candidatePaths.FirstOrDefault(File.Exists);
        if (jsonPath == null)
        {
            return;
        }

        try
        {
            var json = File.ReadAllText(jsonPath);
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            options.Converters.Add(new JsonStringEnumConverter());

            var data = JsonSerializer.Deserialize<DummyDataWrapper>(json, options);
            if (data == null) return;

            if (data.Suppliers != null && data.Suppliers.Count > 0)
            {
                modelBuilder.Entity<Supplier>().HasData(data.Suppliers.Where(s => s.SupplierId <= 3));
            }

            if (data.Categories != null && data.Categories.Count > 0)
            {
                modelBuilder.Entity<Category>().HasData(data.Categories.Where(c => c.CategoryId <= 4));
            }

            if (data.Products != null && data.Products.Count > 0)
            {
                modelBuilder.Entity<Product>().HasData(data.Products.Where(p => p.ProductId <= 5));
            }

            if (data.ProductVariants != null && data.ProductVariants.Count > 0)
            {
                modelBuilder.Entity<ProductVariant>().HasData(data.ProductVariants.Where(v => v.VariantId <= 7));
            }

            if (data.Surveys != null && data.Surveys.Count > 0)
            {
                modelBuilder.Entity<Survey>().HasData(data.Surveys.Where(s => s.SurveyId <= 1));
            }

            if (data.SurveyQuestions != null && data.SurveyQuestions.Count > 0)
            {
                modelBuilder.Entity<SurveyQuestion>().HasData(data.SurveyQuestions.Where(q => q.SurveyId <= 1));
            }

            if (data.SurveyOptions != null && data.SurveyOptions.Count > 0)
            {
                modelBuilder.Entity<SurveyOption>().HasData(data.SurveyOptions.Where(o => o.OptionId <= 3));
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SeedDummyData] Cảnh báo: Không thể nạp dummy_data.json: {ex.Message}");
        }
    }
}
