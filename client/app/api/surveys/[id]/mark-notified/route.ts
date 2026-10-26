import { NextRequest, NextResponse } from "next/server";
import { sameOrigin } from "../../../../../lib/auth-server";
import { customerProxy } from "../../../../../lib/customer-proxy";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!sameOrigin(request)) {
    return NextResponse.json(
      { message: "Yêu cầu không hợp lệ." },
      { status: 403 },
    );
  }
  const { id } = await params;
  if (!/^[1-9]\d*$/.test(id) || Number(id) > 2147483647) {
    return NextResponse.json(
      { message: "Mã khảo sát không hợp lệ." },
      { status: 400 },
    );
  }
  return customerProxy(request, `surveys/${id}/mark-notified`, {
    method: "POST",
  });
}
