import { NextRequest } from "next/server";
import { saveReview } from "../../../lib/reviews-server";

export function POST(request: NextRequest) {
  return saveReview(request);
}
