# Kết quả kiểm thử sao lưu và phục hồi thực tế

Ngày kiểm thử: 2026-11-07 (Asia/Bangkok).

- Nhánh mã nguồn: iamhoang05.
- Container PostgreSQL: webbanhang_postgres.
- CSDL nguồn: web_ban_hang.
- CSDL phục hồi riêng: techstoree_restore_test_20261107_005631.
- Archive: backups/backup_20261107_005631_f42cdc9e.dump.
- Dung lượng archive: 101241 bytes.
- Chạy backup.ps1 và restore.ps1 trên Docker/PostgreSQL thật: thành công.
- Tên bảng và số bản ghi: khớp toàn bộ 30 bảng (bao gồm bảng lịch sử migration nếu có).
- Chặn phục hồi vào CSDL chính: đạt.
- Từ chối ghi đè CSDL đã tồn tại: đạt.
- Không đổi kết nối ứng dụng; không xóa CSDL chính; giữ CSDL thử nghiệm để kiểm tra trong pgAdmin.

Đối chiếu dưới đây là số bản ghi tại thời điểm truy vấn sau phục hồi, không phải kiểm tra toàn bộ nội dung từng ô dữ liệu. Archive chứa dữ liệu riêng tư và đã được Git bỏ qua.

| Bảng | Số bản ghi nguồn và đích |
| --- | --- |
| public.Suppliers | 10 |
| public.__EFMigrationsHistory | 20 |
| public.admins | 1 |
| public.cart_items | 2 |
| public.carts | 5 |
| public.categories | 7 |
| public.customers | 6 |
| public.employees | 5 |
| public.invoices | 13 |
| public.order_items | 15 |
| public.orders | 13 |
| public.permissions | 55 |
| public.product_variants | 20 |
| public.products | 13 |
| public.promotion_variants | 22 |
| public.promotions | 8 |
| public.purchase_order_items | 4 |
| public.purchase_orders | 3 |
| public.reviews | 2 |
| public.role_permissions | 91 |
| public.roles | 5 |
| public.survey_answers | 11 |
| public.survey_assignments | 4 |
| public.survey_options | 28 |
| public.survey_questions | 10 |
| public.surveys | 3 |
| public.user_roles | 8 |
| public.user_vouchers | 3 |
| public.users | 8 |
| public.vouchers | 12 |
