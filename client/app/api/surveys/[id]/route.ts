import { NextRequest, NextResponse } from "next/server";
import { customerProxy } from "../../../../lib/customer-proxy";
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  if (!/^[1-9]\d*$/.test(id) || Number(id) > 2147483647) {
    return NextResponse.json(
      { message: "Mã khảo sát không hợp lệ." },
      { status: 400 },
    );
  }
  return customerProxy(request, `surveys/${id}/take`);
}
