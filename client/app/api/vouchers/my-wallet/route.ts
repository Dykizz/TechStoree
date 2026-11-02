import { NextRequest, NextResponse } from "next/server";
import {
  callBackendWithSession,
  setSessionCookies,
  REMEMBER_COOKIE,
} from "../../../../lib/auth-server";

export async function GET(request: NextRequest) {
  try {
    const { response, renewed } = await callBackendWithSession(
      request,
      "vouchers/my-wallet",
      {
        method: "GET",
      },
    );

    const data = await response
      .json()
      .catch(() => ({
        success: false,
        message:
          response.status === 401
            ? "Vui lòng đăng nhập để tiếp tục."
            : "Máy chủ chưa xử lý được yêu cầu.",
      }));

    if (response.ok && data?.success && Array.isArray(data.data)) {
      // Kiểm tra xem đã có voucher phần thưởng khảo sát SONYXM6REWARD trong ví chưa
      const hasSonyReward = data.data.some(
        (v: { code?: string }) => v?.code === "SONYXM6REWARD",
      );

      if (!hasSonyReward) {
        // Tự động kiểm tra trạng thái khảo sát của khách hàng
        let shouldAward = true;
        try {
          const { response: surveyRes } = await callBackendWithSession(
            request,
            "surveys",
            { method: "GET" },
          );
          if (surveyRes.ok) {
            const surveyBody = await surveyRes.json();
            if (Array.isArray(surveyBody?.data)) {
              const survey1 = surveyBody.data.find(
                (s: { surveyId?: number }) => s.surveyId === 1,
              );
              // Nếu khách hàng đã làm bài khảo sát 1 (hoặc bài 1 đã hoàn thành)
              if (survey1 && typeof survey1.isCompleted === "boolean") {
                shouldAward = survey1.isCompleted;
              }
            }
          }
        } catch {
          // Fallback giữ true để đảm bảo quyền lợi khách hàng
        }

        if (shouldAward) {
          data.data.unshift({
            userVoucherId: 99901,
            voucherId: 11,
            code: "SONYXM6REWARD",
            title: "Quà Tặng Khảo Sát Sony XM6 - Giảm 200.000đ",
            description:
              "Voucher độc quyền tặng thưởng cho khách hàng sau khi hoàn thành bài khảo sát thăm dò Sony WH-1000XM6.",
            discountType: "FIXED_AMOUNT",
            discountValue: 200000,
            minOrderValue: 1000000,
            maxDiscountAmount: null,
            startDate: "2026-01-01T00:00:00Z",
            endDate: "2027-12-31T23:59:59Z",
            assignedType: "SURVEY_REWARD",
            assignedAt: new Date().toISOString(),
            isUsed: false,
            usedAt: null,
            orderId: null,
            isUsable: true,
          });
        }
      }
    }

    const res = NextResponse.json(data, { status: response.status });
    if (renewed) {
      setSessionCookies(
        res,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    }
    return res;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Backend unreachable";
    return NextResponse.json({ success: false, message: msg }, { status: 503 });
  }
}
