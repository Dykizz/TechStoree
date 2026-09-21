# Hệ Thống Thông Tin Doanh Nghiệp - Web Bán Hàng

Hệ thống Backend RESTful API được xây dựng bằng **ASP.NET Core Web API (.NET 10)** kết hợp cơ sở dữ liệu **PostgreSQL 17** và giao diện quản lý **pgAdmin 4** chạy trên môi trường Docker.

---

## 🚀 Khởi chạy hệ thống bằng Docker

### 1. Khởi động toàn bộ (Database + Backend Web API + pgAdmin Web)
Chạy lệnh sau tại thư mục gốc của dự án (`d:\HTTTDN`):
```bash
docker compose up -d
```

Sau khi các container khởi động:
- **Web Quản trị CSDL (pgAdmin 4):** [http://localhost:5051](http://localhost:5051)
  - **Email đăng nhập:** `admin@admin.com`
  - **Mật khẩu:** `admin123`
  - **Cách kết nối tới PostgreSQL trong pgAdmin:**
    - Host name/address: `postgres` (hoặc `webbanhang_postgres`)
    - Port: `5432`
    - Maintenance database: `web_ban_hang`
    - Username: `postgres`
    - Password: `postgres123`
- **Swagger UI API:** [http://localhost:5000/swagger](http://localhost:5000/swagger)
- **Root API Endpoint:** [http://localhost:5000/](http://localhost:5000/)
- **PostgreSQL Database (Cổng máy host):** `5434` (dành cho DBeaver, Navicat, DataGrip)

---

### 2. Chỉ chạy Database & pgAdmin (Dành cho việc Code Backend trực tiếp trên máy)
Nếu bạn muốn code và debug .NET API trực tiếp trên Visual Studio / VS Code / Terminal:

1. Bật container PostgreSQL và pgAdmin:
   ```bash
   docker compose up -d postgres pgadmin
   ```
2. Chạy Backend trên máy host:
   ```bash
   cd api
   dotnet run
   ```
*(File `appsettings.Development.json` đã được cấu hình sẵn để kết nối tới `localhost:5434`)*.

---

### 3. Dừng hệ thống
```bash
docker compose down
```
*(Nếu muốn xóa cả volume dữ liệu để reset trắng CSDL: `docker compose down -v`)*.
