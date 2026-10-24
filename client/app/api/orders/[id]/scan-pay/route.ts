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
      data.message || "Không thể lấy quyền hệ thống để cập nhật thanh toán.",
    );
  }

  cachedAdminToken = {
    token: data.data.token,
    expiresAt: now + 25 * 60 * 1000,
  };

  return cachedAdminToken.token;
}

async function processOrderScanPayment(id: string) {
  let adminToken = await getSystemAdminToken();

  // 1. Fetch current order info from backend
  let orderRes = await fetch(apiEndpoint(`Orders/${id}`), {
    method: "GET",
    headers: {
      Authorization: `Bearer ${adminToken}`,
    },
    cache: "no-store",
    signal: AbortSignal.timeout(8000),
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
      signal: AbortSignal.timeout(8000),
    });
  }

  const orderData = await orderRes.json().catch(() => ({}));
  const order = orderData?.data;

  if (!order) {
    throw new Error(`Không tìm thấy đơn hàng #${id}`);
  }

  // 2. Update payment status to PAID via PATCH api/Orders/{id}/payment-status
  const currentPaymentStatus = order.paymentStatus || order.PaymentStatus;
  if (currentPaymentStatus !== "PAID") {
    let patchRes = await fetch(apiEndpoint(`Orders/${id}/payment-status`), {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        paymentStatus: "PAID",
        note: "Quét mã QR tự động nhận diện (Không cần chuyển tiền)",
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });

    if (patchRes.status === 401) {
      cachedAdminToken = null;
      adminToken = await getSystemAdminToken();
      patchRes = await fetch(apiEndpoint(`Orders/${id}/payment-status`), {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          paymentStatus: "PAID",
          note: "Quét mã QR tự động nhận diện (Không cần chuyển tiền)",
        }),
        cache: "no-store",
        signal: AbortSignal.timeout(8000),
      });
    }

    // 3. Confirm order if still PENDING
    const currentOrderStatus = order.orderStatus || order.OrderStatus;
    if (currentOrderStatus === "PENDING") {
      await fetch(apiEndpoint(`Orders/${id}/status`), {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          status: "CONFIRMED",
        }),
        cache: "no-store",
        signal: AbortSignal.timeout(8000),
      }).catch(() => {});
    }
  }

  return order;
}

// GET: Called when mobile phone camera or browser scans the QR
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const order = await processOrderScanPayment(id);

    const formattedPrice = new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(order.totalAmount || 0);

    const html = `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Quét mã thành công - TechStoree</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #090d16;
      color: #f8fafc;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #131b2e;
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 24px;
      padding: 32px 22px;
      max-width: 380px;
      width: 100%;
      text-align: center;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6);
      animation: popIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes popIn {
      from { transform: scale(0.9); opacity: 0; }
      to { transform: scale(1); opacity: 1; }
    }
    .check-icon {
      width: 76px;
      height: 76px;
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
      color: #ffffff;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 18px;
      box-shadow: 0 0 32px rgba(16, 185, 129, 0.5);
    }
    .check-icon svg {
      width: 42px;
      height: 42px;
      stroke-width: 3;
    }
    h1 {
      font-size: 21px;
      font-weight: 700;
      color: #ffffff;
      margin-bottom: 8px;
    }
    .subtext {
      color: #94a3b8;
      font-size: 13.5px;
      margin-bottom: 22px;
      line-height: 1.45;
    }
    .details {
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 16px;
      padding: 16px;
      margin-bottom: 22px;
      text-align: left;
    }
    .row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
      font-size: 13.5px;
      border-bottom: 1px dashed rgba(255, 255, 255, 0.08);
    }
    .row:last-child {
      border-bottom: none;
    }
    .label {
      color: #94a3b8;
    }
    .val {
      font-weight: 600;
      color: #ffffff;
    }
    .val-status {
      color: #34d399;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }
    .notice {
      background: rgba(37, 99, 235, 0.12);
      border: 1px solid rgba(37, 99, 235, 0.3);
      color: #93c5fd;
      padding: 12px 14px;
      border-radius: 14px;
      font-size: 12.5px;
      line-height: 1.45;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="check-icon">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
    </div>
    <h1>Quét mã thành công!</h1>
    <p class="subtext">Hệ thống đã nhận diện mã QR và tự động ghi nhận thanh toán cho đơn hàng.</p>
    
    <div class="details">
      <div class="row">
        <span class="label">Mã đơn hàng</span>
        <span class="val">${order.orderCode}</span>
      </div>
      <div class="row">
        <span class="label">Số tiền</span>
        <span class="val">${formattedPrice}</span>
      </div>
      <div class="row">
        <span class="label">Trạng thái</span>
        <span class="val val-status">● ĐÃ THANH TOÁN</span>
      </div>
    </div>

    <div class="notice">
      ⚡ <strong>Xong rồi!</strong> Màn hình máy tính của bạn đang tự động chuyển sang trạng thái hoàn tất thành công.
    </div>
  </div>
</body>
</html>`;

    return new NextResponse(html, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
      },
    });
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "Lỗi xử lý xác nhận quét mã.";
    return new NextResponse(
      `<html><body style="font-family:sans-serif;padding:30px;text-align:center;background:#0f172a;color:#fff;"><h2>${msg}</h2></body></html>`,
      { status: 500, headers: { "Content-Type": "text/html; charset=utf-8" } },
    );
  }
}

// POST: Direct simulation trigger from desktop browser
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const order = await processOrderScanPayment(id);
    return NextResponse.json({
      success: true,
      message: "Quét mã thành công! Đơn hàng đã chuyển sang trạng thái ĐÃ THANH TOÁN.",
      data: order,
    });
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "Lỗi xử lý mô phỏng quét mã.";
    return NextResponse.json({ success: false, message: msg }, { status: 500 });
  }
}
