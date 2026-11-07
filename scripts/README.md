# Sao lưu và phục hồi CSDL TechStoree

Đây là phương án sao lưu thủ công bằng PowerShell và PostgreSQL trong Docker, không phải chức năng trong giao diện/API. Yêu cầu PowerShell 5.1 trở lên, Docker Desktop đang chạy và dịch vụ PostgreSQL đã khởi động (`docker compose up -d postgres`). Chạy các lệnh dưới đây tại thư mục gốc TechStoree.

## Sao lưu

```powershell
.\scripts\backup.ps1
```

Script dùng `pg_dump -F c -b -f` tạo archive trong container, kiểm tra danh mục bằng `pg_restore --list`, rồi sao chép về `backups/backup_<ngày giờ>_<mã>.dump`. Chỉ công bố tên file cuối khi sao chép thành công; file tạm trong container được dọn sau thao tác. Kiểm tra danh mục chưa thay thế cho kiểm thử phục hồi thực tế.

Tên container mặc định là `webbanhang_postgres`; tên CSDL và tài khoản được đọc từ `POSTGRES_DB` và `POSTGRES_USER` trong container. Có thể chỉ định `-Container`, `-Database`, `-Username`, `-OutputDirectory` nếu cần. Không ghi mật khẩu vào lệnh hay script.

## Phục hồi kiểm thử

Thay đường dẫn ví dụ bằng file vừa sao lưu:

```powershell
.\scripts\restore.ps1 -BackupFile .\backups\backup_20261107_003000_12345678.dump -TargetDatabase techstoree_restore_test
```

Script kiểm tra danh mục archive, tạo CSDL mới và phục hồi bằng `pg_restore --exit-on-error --single-transaction`. Script chặn CSDL chính theo cấu hình container, `web_ban_hang` và các CSDL hệ thống; từ chối ghi đè mọi CSDL đã tồn tại. Nếu phục hồi thất bại, CSDL thử nghiệm được giữ lại để kiểm tra. Chỉ dùng archive từ nguồn tin cậy.

Không cần dừng backend khi phục hồi vào CSDL riêng. Script không đổi kết nối ứng dụng, không xóa CSDL chính và không tự đưa CSDL thử nghiệm vào vận hành. Đây là bước xác minh khả năng phục hồi; khi có sự cố thật cần kế hoạch riêng để dừng ghi dữ liệu, kiểm chứng và chuyển kết nối ứng dụng sang CSDL đã phục hồi.

## Minh chứng đưa vào báo cáo

1. Chụp kết quả sao lưu thành công và file `.dump` có dung lượng khác 0.
2. Chạy phục hồi vào CSDL thử nghiệm mới và chụp kết quả thành công.
3. Trong pgAdmin, Refresh danh sách Databases rồi kiểm tra các bảng của CSDL thử nghiệm. So sánh số bản ghi của các bảng nghiệp vụ với nguồn tại thời điểm sao lưu; nên tạm dừng thao tác ghi trong buổi kiểm thử để dễ đối chiếu.
4. Ghi lại ngày kiểm thử, tên file, tên CSDL đích và kết quả thực tế. Không ghi đã kiểm thử thành công khi chưa thực hiện.

Archive chỉ chứa CSDL PostgreSQL, không chứa file ảnh lưu trên Cloudinary hoặc cấu hình môi trường. `backups/`, `*.dump`, `*.backup` được bỏ qua bởi Git; không thêm cưỡng bức các file chứa dữ liệu riêng tư. Bộ script không tự xóa bản sao lưu cũ và không đăng ký lịch Windows Task Scheduler.

## Nội dung dùng trong báo cáo

Hệ thống áp dụng phương án sao lưu logic CSDL PostgreSQL bằng công cụ `pg_dump` ở định dạng custom archive. Quản trị viên chạy `scripts/backup.ps1` để tạo và lưu bản sao lưu trong thư mục `backups/`. Để kiểm chứng khả năng phục hồi, quản trị viên chạy `scripts/restore.ps1` với file archive và tên CSDL thử nghiệm mới. Quá trình này sử dụng `pg_restore`, không ghi đè CSDL chính. Sau khi phục hồi, quản trị viên kiểm tra cấu trúc bảng và số lượng bản ghi trong pgAdmin. Kết quả kiểm thử được ghi nhận kèm minh chứng thực tế.
