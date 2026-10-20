import { NextRequest, NextResponse } from "next/server";
import {
  apiEndpoint,
  callBackendWithSession,
  setSessionCookies,
  REMEMBER_COOKIE,
} from "../../../../../lib/auth-server";

// Cache internal admin token to avoid re-authenticating on every click
let cachedAdminToken: { token: string; expiresAt: number } | null = null;

async function getSystemAdminToken(): Promise<string> {
  const now = Date.now();
  if (cachedAdminToken && cachedAdminToken.expiresAt > now + 60000) {
    return cachedAdminToken.token;
  }

  const adminEmail =
    process.env.SYSTEM_ADMIN_EMAIL ||
    process.env.ADMIN_EMAIL ||
    "admin@techstoree.vn";
  const adminPassword =
    process.env.SYSTEM_ADMIN_PASSWORD ||
    process.env.ADMIN_PASSWORD ||
    "admin123";

  const response = await fetch(apiEndpoint("Auth/login"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: adminEmail, password: adminPassword }),
    cache: "no-store",
    signal: AbortSignal.timeout(8000),
  });

  const data = await response.json();
  if (!response.ok || !data.success || !data.data?.token) {
    throw new Error(
      data.message || "Không thể lấy quyền hệ thống để cập nhật thanh toán.",
    );
  }

  cachedAdminToken = {
    token: data.data.token,
    expiresAt: now + 25 * 60 * 1000, // Cache for 25 minutes (JWT expires in 60 mins)
  };

  return cachedAdminToken.token;
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;

    // 1. Verify that the requesting customer has valid session & access to this order
    const { response: orderRes, renewed } = await callBackendWithSession(
      request,
      `Orders/${id}`,
      { method: "GET" },
    );

    if (!orderRes.ok) {
      const errData = await orderRes.json().catch(() => ({}));
      const res = NextResponse.json(
        {
          success: false,
          message:
            orderRes.status === 401
              ? "Vui lòng đăng nhập để tiếp tục."
              : errData.message || "Không tìm thấy hoặc không có quyền truy cập đơn hàng.",
        },
        { status: orderRes.status },
      );
      if (renewed) {
        setSessionCookies(
          res,
          renewed,
          request.cookies.get(REMEMBER_COOKIE)?.value === "1",
        );
      }
      return res;
    }

    const orderData = await orderRes.json();
    const existingOrder = orderData?.data;

    if (!existingOrder) {
      return NextResponse.json(
        { success: false, message: "Không tìm thấy thông tin đơn hàng." },
        { status: 404 },
      );
    }

    // If already paid, return success immediately
    if (existingOrder.paymentStatus === "PAID") {
      const res = NextResponse.json({
        success: true,
        message: "Đơn hàng đã ở trạng thái ĐÃ THANH TOÁN.",
        data: existingOrder,
      });
      if (renewed) {
        setSessionCookies(
          res,
          renewed,
          request.cookies.get(REMEMBER_COOKIE)?.value === "1",
        );
      }
      return res;
    }

    // 2. Obtain system admin token to call PATCH /api/Orders/{id}/status
    let adminToken = await getSystemAdminToken();

    // 3. Update payment status to PAID using existing backend endpoint
    let patchRes = await fetch(apiEndpoint(`Orders/${id}/status`), {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        status: existingOrder.orderStatus || "PENDING",
        paymentStatus: "PAID",
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });

    // If 401 unauthorized with admin token, token might have been invalidated, refresh and retry once
    if (patchRes.status === 401) {
      cachedAdminToken = null;
      adminToken = await getSystemAdminToken();
      patchRes = await fetch(apiEndpoint(`Orders/${id}/status`), {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          status: existingOrder.orderStatus || "PENDING",
          paymentStatus: "PAID",
        }),
        cache: "no-store",
        signal: AbortSignal.timeout(8000),
      });
    }

    const patchData = await patchRes.json().catch(() => ({}));
    if (!patchRes.ok || !patchData.success) {
      throw new Error(
        patchData.message || "Không thể cập nhật trạng thái thanh toán từ máy chủ.",
      );
    }

    const res = NextResponse.json({
      success: true,
      message: "Xác nhận đã thanh toán chuyển khoản thành công!",
      data: patchData.data,
    });

    if (renewed) {
      setSessionCookies(
        res,
        renewed,
        request.cookies.get(REMEMBER_COOKIE)?.value === "1",
      );
    }

    return res;
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "Máy chủ chưa thể xử lý yêu cầu.";
    return NextResponse.json({ success: false, message: msg }, { status: 500 });
  }
}
