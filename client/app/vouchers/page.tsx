import type { Metadata } from "next";
import VouchersClient from "./vouchers-client";

export const metadata: Metadata = {
  title: "Mã giảm giá của tôi | TechStoree",
  description: "Quản lý và xem danh sách các mã ưu đãi, voucher quà tặng khảo sát của bạn tại TechStoree.",
};

export default function VouchersPage() {
  return <VouchersClient />;
}

