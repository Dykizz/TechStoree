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

## Banner trang chủ

Trang chủ dùng bốn ảnh showcase đã duyệt làm nền tràn ngang, không còn card
ảnh riêng bên phải. Chữ và ảnh nằm trong cùng một scene để chuyển cảnh không
chồng bóng sản phẩm; ảnh giữ tỷ lệ và dùng `contain` để không cắt thiết bị.
Banner chuyển mỗi 5 giây, chỉ chuyển sang ảnh đã tải/giải mã; không có nút
chuyển hoặc nút tạm dừng theo lựa chọn giao diện. Rê chuột không làm dừng banner.
Tự chạy tạm dừng khi focus ở banner hoặc tab bị ẩn,
và tắt khi người dùng bật giảm chuyển động. Trên điện thoại, ảnh nằm thấp hơn
phần chữ nhưng vẫn thuộc cùng nền banner.

Ba liên kết nhanh: **Khám phá** cuộn xuống `#explore`, **Minh bạch** mở
`/products` để xem giá/tồn kho, **Cá nhân** mở `/profile` với route guard hiện có.
Ảnh minh họa không thay thế dữ liệu sản phẩm thực tế hoặc ngụ ý hàng có sẵn.

## Chuông thông báo khách hàng

Khi đăng nhập, thanh đầu trang có chuông thông báo dùng chung cho trang chủ,
khảo sát, hồ sơ, giỏ hàng và đơn hàng. Chuông hiển thị số chưa đọc; bấm để mở
danh sách, lọc chưa đọc, đánh dấu đã đọc hoặc mở trang liên quan. Có thể đóng
bằng Escape, nút đóng, bấm ra ngoài hoặc chuyển focus ra ngoài bảng.

Thông báo được thêm sau khi API xác nhận nộp khảo sát, lưu hồ sơ thật, tạo đơn
hoặc hủy đơn thành công. Bản xem trước hồ sơ không tạo thông báo thành công.
Thanh toán chỉ được thông báo khi API trả trạng thái `PAID` và đúng chủ đơn;
tạo đơn COD hoặc hiển thị VietQR không được coi là đã thanh toán. Khi mở/tải lại
danh sách đơn hàng, UI kiểm tra trạng thái thanh toán và tránh lặp sự kiện đã
ghi nhận; không có cơ chế xác nhận chuyển khoản hoặc thông báo realtime mới.

Đây là lịch sử frontend trên **trình duyệt hiện tại**, tách riêng theo `userId`,
chưa phải hộp thư thông báo lưu trên backend hoặc đồng bộ giữa các thiết bị.
Giữ tối đa 50 thông báo và 500 ID sự kiện gần nhất để tránh lặp; không lưu câu
trả lời khảo sát, token, địa chỉ hay thông tin ngân hàng trong lịch sử này.
Nếu localStorage bị chặn/đầy, thông báo chỉ tồn tại trong bộ nhớ của lần mở web,
không làm hỏng thao tác đã thành công. Trạng thái đơn/thanh toán chính thức
vẫn lấy từ API, không lấy từ lịch sử thông báo.

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
- Đăng xuất xóa cookie phiên và cache giỏ/voucher cũ trên trình duyệt; nếu đang ở trang riêng tư thì quay về trang chủ bằng lần tải mới. API phân biệt đã rời phiên trình duyệt với việc backend xác nhận thu hồi phiên; lỗi mạng hoặc yêu cầu bị từ chối không được giả thành đăng xuất thành công.
- Giá và promotion của biến thể được lấy lại từ API preview; voucher hợp lệ do backend xác nhận.
- Chuyển khoản chỉ bật khi đã cấu hình đủ ba biến `NEXT_PUBLIC_BANK_*` trong `.env.example`. Mã QR không tự xác nhận đã thanh toán. Những biến này là thông tin nhận tiền công khai, không chứa API secret.
- API chưa tính phí giao hàng: UI ghi rõ “Chưa tính phí”, không tự tạo cam kết miễn phí vận chuyển.
- Checkout tách rõ thông tin nhận hàng, phương thức thanh toán và tóm tắt đơn; tên sản phẩm dài xuống dòng riêng khỏi giá. Khi gửi đơn, biểu mẫu khóa tạm thời và hiển thị trạng thái chờ; chặn gửi trùng ngay cả khi bấm liên tiếp trước lần render tiếp theo. Phiếu xác nhận chỉ hiển thị sau khi API tạo đơn thành công, dùng số tiền/trạng thái thật và có hiệu ứng nhẹ hỗ trợ chế độ giảm chuyển động. Chuyển khoản chưa xác nhận không được hiển thị là đã thanh toán.
- Khảo sát tại `/surveys`, biểu mẫu tại `/surveys/[id]`; backend kiểm tra phân quyền, bắt buộc trả lời, nộp một lần và thưởng voucher.
- Đánh giá sản phẩm chưa có API tương ứng; UI không hiển thị đánh giá mẫu như phản hồi khách hàng thật. Địa chỉ/hotline giả cũng không được dùng làm kênh liên hệ.

### Điều kiện trước khi merge main

Backend phải đọc được `GET /api/Products` và `GET /api/Products/{id}`; kiểm thử lại lọc sản phẩm, biến thể, khuyến mãi và mua lại trên dữ liệu thật. Khi chưa cấu hình Cloudinary, backend main hiện có thể lỗi ngay lúc khởi tạo dịch vụ. Nhánh frontend không tự sửa backend. Commit `07479c2` trên `son-client` là bản sửa backend riêng cần nhóm backend review; chưa được đưa vào bản tích hợp này.

Máy tích hợp đã cấu hình Cloudinary riêng và kiểm tra API sản phẩm thành công;
điều này không tự cấu hình cho máy của các thành viên khác. Mẫu cấu hình nằm
ở `.env.example` tại gốc repo (không phải `.env.example` của `client/`). Ba khóa
`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` chỉ dùng
cho backend; không đặt vào biến `NEXT_PUBLIC_*` và không commit `.env`.
Compose chung chưa truyền ba khóa này vào container. Trên máy tích hợp có
override local trong thư mục `.docker/` được Git bỏ qua, dùng để nạp riêng
cấu hình vào API, không thay đổi source backend hay database.
