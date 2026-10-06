import { NextResponse } from "next/server";
import { backendApiRequest } from "../../../lib/auth-server";
export async function GET() {
  try {
    const { response, body } = await backendApiRequest<
      { key: string; displayName: string }[]
    >("Users/tech-interests", {});
    return NextResponse.json(body?.data ?? [], { status: response.status });
  } catch {
    return NextResponse.json(
      { message: "Không thể tải nhóm sở thích." },
      { status: 503 },
    );
  }
}
