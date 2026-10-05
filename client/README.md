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

Trang chủ ở <http://localhost:3000>; đăng nhập ở `/login` (không còn ở `/`). Backend và Swagger của dự án được mô tả trong
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

Hiện đã có màn hình đăng nhập responsive, luồng đăng nhập/đăng xuất và màn đăng
ký dùng `POST /api/Auth/register`. Đăng ký thành công chưa tự đăng nhập; người
dùng chuyển sang màn đăng nhập. Trang `/profile` kiểm tra phiên trước khi hiển
thị dữ liệu cá nhân, lấy hồ sơ từ `GET /api/Auth/me` và lưu thay đổi qua
`PUT /api/Users/profile`. Tên đăng nhập và email chỉ xem, chưa có API sửa.
Route Handler hồ sơ cũng kiểm tra token ở backend, kể cả khi được gọi trực tiếp.
Nếu API ngừng hoạt động, trang hiện lỗi và nút thử lại thay vì coi phiên đã hết
hạn. Khảo sát dùng API thật: danh sách được giao, tải câu hỏi và nộp câu trả lời.
Không tự đánh dấu hoàn thành hay tạo voucher khi API chưa xác nhận.
Khi chạy `npm run dev`, có thể mở `/profile?preview=1` để xem giao diện với dữ
liệu mẫu mà không cần đăng nhập hay backend. Chỉnh sửa trong bản xem trước chỉ
thay đổi thông tin hồ sơ trên màn hình, không lưu hồ sơ tới API; nhóm sở thích vẫn đọc từ API; chế độ này không khả dụng ở bản build
production. `/profile` bình thường vẫn yêu cầu phiên đăng nhập.
Backend cũng chưa có API đặt lại mật
khẩu; nút tương ứng chỉ hiển thị thông báo, không gửi yêu cầu giả.
Font Inter Variable hỗ trợ tiếng Việt và được đóng gói trong ứng dụng để hiển
thị nhất quán trên các máy. Typography lấy cảm hứng từ cách trình bày tối giản
của Apple Store, không sử dụng font SF Pro của Apple.

## Showcase ở trang xác thực

Phần giới thiệu bên trái của trang đăng nhập và đăng ký dùng chung một carousel
4 slide, tự chuyển sau 5 giây. Nền, nội dung và ảnh chuyển cùng nhịp; người dùng
có thể chọn slide hoặc dùng nút trước/sau. Carousel tạm dừng khi rê chuột, đặt
focus vào vùng này hoặc chuyển sang thẻ khác, và không tự chạy nếu hệ điều hành
bật chế độ giảm chuyển động. Ảnh sản phẩm được đặt làm lớp nền phía dưới phần
chữ, hiển thị trọn ảnh và không nhúng giá hoặc nút mua. Trên màn hình nhỏ,
showcase được thu gọn phía trên biểu mẫu.

Bốn ảnh `public/images/showcase-*.png` lấy từ ảnh người dùng cung cấp; ba ảnh
iPhone 18 Pro, AirPods Pro 3 và Galaxy Z Fold8 đã được AI làm sạch chữ/nút
quảng cáo, vì vậy có thể khác ảnh sản phẩm chính thức ở chi tiết nhỏ. Riêng
chữ “PRO” phía sau iPhone 18 Pro được giữ theo yêu cầu. Những hình này chỉ dùng
cho bản mẫu nội bộ; tên mẫu không có nghĩa TechStoree đang bán sản phẩm đó.
Trước khi phát hành công khai, nhóm cần xác nhận quyền sử dụng ảnh và nhãn hiệu.

## Bản tích hợp khách hàng

- Hồ sơ mặc định chỉ xem; chọn **Chỉnh sửa** để mở các trường, **Hủy** khôi phục bản đã lưu, **Lưu thay đổi** chỉ khóa lại sau khi API thành công.
- Danh mục, giá, giỏ hàng và đơn hàng đọc từ backend; không fallback sang sản phẩm/đơn hàng/voucher mẫu khi API lỗi.
- Giỏ hàng cần đăng nhập. Cookie refresh có đường dẫn `/` để các route giỏ hàng/đơn hàng cũng làm mới phiên được; request đồng thời dùng chung một lần refresh.
- Giá và promotion của biến thể được lấy lại từ API preview; voucher hợp lệ do backend xác nhận.
- Chuyển khoản chỉ bật khi đã cấu hình đủ ba biến `NEXT_PUBLIC_BANK_*` trong `.env.example`. Mã QR không tự xác nhận đã thanh toán. Những biến này là thông tin nhận tiền công khai, không chứa API secret.
- API chưa tính phí giao hàng: UI ghi rõ “Chưa tính phí”, không tự tạo cam kết miễn phí vận chuyển.
- Khảo sát tại `/surveys`, biểu mẫu tại `/surveys/[id]`; backend kiểm tra phân quyền, bắt buộc trả lời, nộp một lần và thưởng voucher.
- Đánh giá sản phẩm chưa có API tương ứng; UI không hiển thị đánh giá mẫu như phản hồi khách hàng thật. Địa chỉ/hotline giả cũng không được dùng làm kênh liên hệ.

### Điều kiện trước khi merge main

Backend phải đọc được `GET /api/Products` và `GET /api/Products/{id}`; kiểm thử lại lọc sản phẩm, biến thể, khuyến mãi và mua lại trên dữ liệu thật. Khi chưa cấu hình Cloudinary, backend main hiện có thể lỗi ngay lúc khởi tạo dịch vụ. Nhánh frontend không tự sửa backend. Commit `07479c2` trên `son-client` là bản sửa backend riêng cần nhóm backend review; chưa được đưa vào bản tích hợp này.
