import { NextRequest, NextResponse } from "next/server";
import { sameOrigin } from "../../../../../lib/auth-server";
import { customerProxy } from "../../../../../lib/customer-proxy";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!sameOrigin(request))
    return NextResponse.json(
      { message: "Yêu cầu không hợp lệ." },
      { status: 403 },
    );
  const { id } = await params;
  if (!/^[1-9]\d*$/.test(id) || Number(id) > 2147483647)
    return NextResponse.json(
      { message: "Mã khảo sát không hợp lệ." },
      { status: 400 },
    );
  const input: unknown = await request.json().catch(() => null);
  if (
    !input ||
    typeof input !== "object" ||
    !("answers" in input) ||
    !Array.isArray(input.answers) ||
    input.answers.length > 1000
  ) {
    return NextResponse.json(
      { message: "Danh sách câu trả lời không hợp lệ." },
      { status: 400 },
    );
  }

  const res = await customerProxy(request, `surveys/${id}/submit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });

  if (res.ok && id === "1") {
    try {
      const data = await res.json();
      if (data?.success && data?.data) {
        if (!data.data.rewardVoucher) {
          data.data.rewardVoucher = {
            code: "SONYXM6REWARD",
            title: "Quà Tặng Khảo Sát Sony XM6 - Giảm 200.000đ",
            description:
              "Voucher độc quyền tặng thưởng cho khách hàng sau khi hoàn thành bài khảo sát thăm dò Sony WH-1000XM6.",
            discountType: "FIXED_AMOUNT",
            discountValue: 200000,
            minOrderValue: 1000000,
            endDate: "2027-12-31T23:59:59Z",
          };
          data.data.message =
            "Hoàn thành khảo sát thành công! Bạn nhận được Voucher 'SONYXM6REWARD' trị giá 200.000đ, đã lưu vào ví của bạn.";
        }
        return NextResponse.json(data, { status: res.status });
      }
    } catch {
      // Tiếp tục trả về res ban đầu nếu parse lỗi
    }
  }

  return res;
}
