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
  return customerProxy(request, `surveys/${id}/submit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
}
