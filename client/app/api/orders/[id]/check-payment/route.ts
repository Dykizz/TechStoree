import { NextRequest, NextResponse } from "next/server";
import { apiEndpoint } from "../../../../../lib/auth-server";

// Cache internal admin token
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
      data.message || "Không thể lấy quyền hệ thống để tra cứu thanh toán.",
    );
  }

  cachedAdminToken = {
    token: data.data.token,
    expiresAt: now + 25 * 60 * 1000,
  };

  return cachedAdminToken.token;
}

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    let adminToken = await getSystemAdminToken();

    let orderRes = await fetch(apiEndpoint(`Orders/${id}`), {
      method: "GET",
      headers: {
        Authorization: `Bearer ${adminToken}`,
      },
      cache: "no-store",
      signal: AbortSignal.timeout(6000),
    });

    if (orderRes.status === 401) {
      cachedAdminToken = null;
      adminToken = await getSystemAdminToken();
      orderRes = await fetch(apiEndpoint(`Orders/${id}`), {
        method: "GET",
        headers: {
          Authorization: `Bearer ${adminToken}`,
        },
        cache: "no-store",
        signal: AbortSignal.timeout(6000),
      });
    }

    if (!orderRes.ok) {
      return NextResponse.json({ success: false, isPaid: false }, { status: 200 });
    }

    const orderData = await orderRes.json().catch(() => ({}));
    const order = orderData?.data;
    const paymentStatus = order?.paymentStatus || order?.PaymentStatus;
    const isPaid = paymentStatus === "PAID";

    return NextResponse.json(
      {
        success: true,
        isPaid,
        paymentStatus,
        orderStatus: order?.orderStatus || order?.OrderStatus,
        totalAmount: order?.totalAmount,
      },
      {
        headers: {
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      },
    );
  } catch {
    return NextResponse.json(
      { success: false, isPaid: false },
      {
        status: 200,
        headers: {
          "Cache-Control": "no-store, no-cache, must-revalidate",
        },
      },
    );
  }
}
