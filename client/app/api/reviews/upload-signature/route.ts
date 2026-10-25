import { NextRequest } from "next/server";
import { customerProxy } from "../../../../lib/customer-proxy";
import { sameOrigin } from "../../../../lib/auth-server";
import { reviewError } from "../../../../lib/reviews-server";

export function POST(request: NextRequest) {
  if (!sameOrigin(request)) return reviewError("Yêu cầu không hợp lệ.", 403);
  return customerProxy(request, "Media/signature", {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ folder: "techstore/reviews" }),
  });
}
