# TechStoree Customer Web

Ứng dụng Next.js dùng chung cho phần web khách hàng của nhóm, sử dụng TypeScript,
App Router, ESLint và npm. Trang đăng nhập được dựng theo hướng editorial từ
thiết kế Figma và kết nối với API xác thực của dự án qua Next.js Route Handlers.

## Chạy trên máy

Yêu cầu Node.js 20.9 trở lên và npm. Từ thư mục `client/`:

```bash
npm ci
npm run dev
```

Mở <http://localhost:3000>. Backend và Swagger của dự án được mô tả trong
[`../README.md`](../README.md); khi backend chạy theo Docker Compose, Swagger ở
<http://localhost:5000/swagger>.

Mặc định Next.js gọi backend tại `http://localhost:5000`. Nếu backend chạy ở
địa chỉ khác, tạo `.env.local` dựa trên `.env.example` và sửa `API_BASE_URL`.
Không đưa `.env.local` vào Git. Form đăng nhập dùng `POST /api/Auth/login`,
kiểm tra phiên qua `GET /api/Auth/me`, làm mới phiên qua
`POST /api/Auth/refresh-token` và đăng xuất qua `POST /api/Auth/logout`.
Access/refresh token được giữ trong cookie HttpOnly của ứng dụng Next.js, không
lưu ở `localStorage`.

## Kiểm tra

```bash
npm run lint
npm run build
```

`package-lock.json` được lưu trong Git để mọi thành viên cài cùng phiên bản
thư viện. Không commit `node_modules/`, `.next/` hoặc file `.env.local`.

## Phân công

- Huy: xác thực, hồ sơ và khảo sát khách hàng.
- Sơn: danh mục, sản phẩm, giỏ hàng và đặt hàng.

Hiện đã có màn hình đăng nhập responsive và luồng đăng nhập/đăng xuất. Màn đăng
ký, hồ sơ, khảo sát chưa được triển khai. Backend cũng chưa có API đặt lại mật
khẩu; nút tương ứng chỉ hiển thị thông báo, không gửi yêu cầu giả. Ảnh laptop
trên màn đăng nhập là tài nguyên được tạo riêng cho dự án, không lấy từ Figma.
Font tiêu đề Noto Serif Display có bộ ký tự tiếng Việt và được đóng gói trong
ứng dụng để hiển thị nhất quán trên các máy.
