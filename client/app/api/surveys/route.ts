import { NextRequest } from "next/server";
import { customerProxy } from "../../../lib/customer-proxy";
export function GET(request: NextRequest) {
  return customerProxy(request, "surveys/my-surveys");
}
