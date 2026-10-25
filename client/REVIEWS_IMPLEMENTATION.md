# Đánh giá sản phẩm — phần client của Ngô Đức Huy

Cập nhật: 25/10/2026. Nền source ban đầu: `43f715e`; trước khi công bố đã
đồng bộ `origin/main` tại `62c821dbbf21e7b29dcc0caf913bbcd935d65ffe`.
Một chỗ chồng sửa JSX trong dòng sản phẩm của trang đơn hàng đã được ghép
để giữ nguyên liên kết sản phẩm/thanh toán mới của main và thêm nút review.
Các phần lọc/sắp xếp đơn hàng, VietQR và vuốt ảnh/lightbox được giữ nguyên.

## Luồng đã triển khai

- Chi tiết sản phẩm: điểm trung bình, tổng lượt, phân bố đủ 9 mức từ 1 đến 5
  theo bước 0,5, bộ lọc sao/ảnh, phân trang, tên được che, phiên bản đã mua,
  thời gian, ảnh và phản hồi shop.
- Đơn hàng `DELIVERED`: nút đánh giá hoặc xem/sửa đánh giá theo lịch sử thật
  của tài khoản. Đơn chưa giao không có nút gửi đánh giá.
- `/reviews`: đăng nhập bắt buộc, hai tab Chờ đánh giá / Đã đánh giá,
  phân trang và liên kết trực tiếp tới sản phẩm trong đơn đã chọn.
- Biểu mẫu tạo/sửa: radio chọn nửa sao từ 1 đến 5, nhận xét tối đa 1.000 ký tự,
  tối đa 5 ảnh JPG/PNG/WebP, mỗi ảnh tối đa 5 MB. Giữ nội dung khi gửi lỗi,
  khóa thao tác đang gửi/tải ảnh, chặn gửi trùng. Dialog dùng focus/keyboard
  của trình duyệt và hỗ trợ giảm chuyển động.
- Nút sửa chỉ hiện trong 30 ngày tính từ `createdAt`; backend vẫn quyết định
  cuối cùng về quyền, thời hạn và tính hợp lệ của đơn hàng.
- Menu tài khoản có Đánh giá của tôi; đăng xuất trên `/reviews` tải lại trang
  chủ giống các trang riêng tư khác.

## Hợp đồng API thực tế

| Route trong Next.js | Backend ASP.NET hiện có |
| --- | --- |
| GET `/api/reviews/product/[id]` | GET `/api/Reviews/product/{id}` |
| GET `/api/reviews/product/[id]/summary` | Tổng hợp `meta.totalItems` từ 9 bộ lọc `rating`, mỗi request `pageSize=1` |
| GET `/api/reviews/pending` | GET `/api/Reviews/pending` |
| GET `/api/reviews/my-reviews` | GET `/api/Reviews/my-reviews` |
| POST `/api/reviews` | POST `/api/Reviews` |
| PUT `/api/reviews/[id]` | PUT `/api/Reviews/{id}` |
| POST `/api/reviews/upload-signature` | POST `/api/Media/signature` với folder `techstore/reviews` |

Ảnh hướng dẫn có nhắc `POST /api/media/upload`; source hiện chỉ cung cấp
`Media/signature`. Client lấy chữ ký qua cookie HttpOnly rồi gửi file trực tiếp
đến địa chỉ Cloudinary đã được ký. Không đặt API secret trong frontend.
Gỡ ảnh khỏi biểu mẫu chỉ bỏ URL khỏi đánh giá, không xóa asset trên Cloudinary.

Thống kê `Reviews/admin/statistics` cần quyền admin và tính cả đánh giá bị ẩn,
nên không phù hợp để dùng trong trang sản phẩm công khai. Bản client này lấy
chính xác số lượng ở từng mức sao của API công khai rồi tính trung bình; không
chỉ tính trên trang nhận xét đang hiển thị và không sử dụng tài khoản admin.
Nếu lượng truy cập lớn, backend nên bổ sung endpoint thống kê công khai riêng
để giảm 9 request đếm xuống một request.

`OrderItemDto` hiện chưa có `isReviewed`/`reviewId`. Component dành cho trang
đơn hàng đọc lịch sử đánh giá của chính tài khoản, đối chiếu `orderItemId`
qua các trang rồi quyết định nút. Nếu API lỗi, hiển thị liên kết quản lý đánh
giá, không khẳng định món hàng chưa được đánh giá.

DTO review gốc có email, điện thoại, tên đầy đủ và mã đơn. Route công khai
Next.js chỉ trả allowlist đã che tên, loại thông tin liên hệ và định danh đơn
trước khi dữ liệu tới trình duyệt. API backend gốc chưa thay đổi trong phạm vi này.

## Phạm vi source

Code chính nằm ở `components/reviews/`, `app/reviews/`, `app/api/reviews/`,
`lib/reviews.ts` và `lib/reviews-server.ts`. Bốn file có sẵn được nối thêm review:
trang chi tiết sản phẩm, trang đơn hàng, `Header.tsx` và `UserDropdown.tsx`.
Không sửa source ASP.NET, migration, schema, Flutter, cấu hình Docker chung,
logic thanh toán, giá hoặc giỏ hàng.

`package.json` có thêm duy nhất lệnh `test:reviews`; ba file trong `tests/`
chạy được với các dependency hiện có, không cài thêm package. Sau khi loại
các điểm nối review khỏi bốn file cũ, source khớp nguyên bản với main mới.

## Kiểm tra và môi trường local

- Build production và TypeScript: đạt.
- Lint riêng code review và các kiểm tra được đưa kèm: đạt.
- Lint toàn bộ client còn 16 lỗi / 3 cảnh báo ở main `62c821d` (nền ban đầu
  `43f715e` có 14 lỗi / 2 cảnh báo). Đã chạy lint trên nội dung
  nguyên bản của đúng các file lỗi tại `HEAD` để xác nhận toàn bộ số lỗi này
  tồn tại trong main tương ứng trước phần review; không tắt rule hoặc sửa
  các phần ngoài nhiệm vụ. Điểm nối ở trang chi tiết sản phẩm cũng có một
  lỗi effect gallery đã tồn tại trong main mới; phần review không thêm lỗi.
- `local-reviews-contract-check.cjs` ở thư mục cha: 12 kiểm tra bằng mock,
  gồm lọc thông tin cá nhân, rating, thời hạn, payload, lỗi API và origin.
- `local-reviews-composer-check.cjs`: 7 kiểm tra trạng thái biểu mẫu, gồm
  chặn bấm gửi liên tiếp, giữ bản nháp khi API lỗi, khóa khi đang gửi,
  từ chối ảnh không hợp lệ và chọn đủ 9 mức nửa sao.
- `local-reviews-api-check.mjs`: 16 kiểm tra qua frontend và backend thật
  trên môi trường riêng đã đạt: tạo/sửa, điều kiện đã giao, quyền sở hữu,
  gửi trùng, phân trang/bộ lọc/tổng quan, che thông tin cá nhân, phản hồi shop,
  ẩn/hiện và lấy chữ ký upload. Không tải asset thật lên Cloudinary.
- `local-reviews-expiry-fixture-check.mjs`: thêm 2 kiểm tra đạt, gồm backend
  từ chối sửa sau 30 ngày (khôi phục timestamp fixture sau kiểm tra) và chuẩn
  bị đồng thời sản phẩm chờ đánh giá / đánh giá đã gửi cho bản xem thử.
- Bộ API kiểm thử local dùng riêng frontend `http://localhost:3002` và
  backend `http://localhost:5002`, Docker project `techstoree-reviews-check`.
  Compose local trong `.docker/reviews-check.compose.yml` được Git bỏ qua.
  PostgreSQL của project này độc lập với `webbanhang_postgres` đang dùng trước đó.
- Không đưa khóa cấu hình, tài khoản thật hoặc artifact kiểm thử lên GitHub.
  Database kiểm thử có đơn/đánh giá ghi rõ KIỂM THỬ LOCAL và hai tài khoản
  tổng hợp; không phải phản hồi khách hàng thật.
- Tải một PNG kiểm thử thật lên Cloudinary đã đạt sau khi sửa cấu hình local.
  Người dùng đã báo kiểm tra ổn và yêu cầu push lên GitHub. Không có bằng chứng
  đo/duyệt riêng bố cục mobile mới nhất; không coi unit test là kiểm tra hình ảnh.

Chạy lại 24 kiểm tra không cần database hay khóa Cloudinary:

```bash
npm run test:reviews
```

Sau khi đồng bộ main mới đã chạy lại build, 24 kiểm tra trên và 16 kiểm tra API
thật với các tài khoản tổng hợp mới trong database riêng. Không sửa đánh giá
mà người dùng đang thử, không tải thêm ảnh thật chỉ để chạy lại bộ kiểm tra.

Lệnh chạy frontend kiểm thử trong PowerShell (tại `client/`):

```powershell
$env:API_BASE_URL = 'http://localhost:5002'
npm run dev -- --port 3002
```

API cũ ở cổng 5000 ban đầu không có route review; không dùng kết quả chạy bản
cũ để kết luận source review trên main bị thiếu. Khi chạy với database đang
sử dụng, cần sao lưu và xem các migration mới của main trước khi nâng backend.

## Kiểm tra upload thực tế ngày 25/10/2026

Yêu cầu lấy chữ ký thành công chưa chứng minh Cloudinary sẽ chấp nhận file.
Khi gửi một PNG kiểm thử rất nhỏ bằng chữ ký thật, Cloudinary trả HTTP 401:
`Invalid cloud_name Root`. Tại thời điểm đó, file `.env` local đặt Cloud name là `Root`.
Cần Cloud name đúng từ chủ tài khoản rồi nạp lại cấu hình container API local;
không đoán Cloud name hoặc đưa API secret vào frontend. Chưa có ảnh kiểm thử
nào được tải thành công trong lượt kiểm tra gặp lỗi cấu hình này.

Sau khi chủ tài khoản cung cấp Cloud name đúng ngày 25/10, đã cập nhật `.env`
được Git bỏ qua và chỉ tạo lại API của project `techstoree-reviews-check`.
Một ảnh PNG kiểm thử nhỏ đã tải thật lên Cloudinary thành công (HTTP 200,
`resource_type=image`, có `secure_url`). Ảnh thử không được đăng vào review.
Database/container PostgreSQL hiện có được giữ nguyên. Cần kiểm tra tiếp ảnh
người dùng chọn và bố cục trên trình duyệt để chốt trải nghiệm.

Luồng upload được tách vào `lib/review-upload.ts`, phân biệt lỗi cấu hình,
kết nối, định dạng và dung lượng thay vì dùng một thông báo chung. Nội dung và
các ảnh đã tải được giữ nguyên khi một ảnh tiếp theo lỗi. Ảnh sản phẩm trong
fixture cũng trả HTTP 404; component thumbnail dùng hình thay thế trung tính
khi ảnh lỗi, tránh hiện biểu tượng vỡ và chữ alt tràn khung.
