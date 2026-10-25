import { reviewRequest, safeReviewImage } from "./reviews";

type UploadSignature = {
  uploadUrl: string;
  signature: string;
  timestamp: number;
  apiKey: string;
  folder?: string;
  publicId?: string;
};

export function reviewUploadError(status: number, message: unknown) {
  const detail = typeof message === "string" ? message.toLowerCase() : "";
  // Map provider errors to useful messages without exposing signing data or keys.
  if (/cloud.?name|api.?key|signature|unauthorized|authentication/.test(detail) || status === 401 || status === 403) {
    return "Dịch vụ tải ảnh chưa được cấu hình đúng. Bạn có thể gửi đánh giá không kèm ảnh hoặc thử lại sau.";
  }
  if (/too large|file size|maximum.*size/.test(detail) || status === 413) {
    return "Ảnh quá lớn để tải lên. Vui lòng chọn ảnh nhỏ hơn 5 MB.";
  }
  if (/invalid image|image file|unsupported|format/.test(detail)) {
    return "Không đọc được ảnh này. Vui lòng chọn một ảnh JPG, PNG hoặc WebP khác.";
  }
  if (status === 429 || /quota|rate limit/.test(detail)) {
    return "Dịch vụ tải ảnh đang bận. Vui lòng thử lại sau ít phút; nhận xét của bạn vẫn được giữ.";
  }
  return "Chưa tải được ảnh lên. Bạn có thể thử lại; ảnh đã tải trước đó vẫn được giữ.";
}

export async function uploadReviewImage(file: File, signal: AbortSignal) {
  const signed = await reviewRequest<UploadSignature>("/api/reviews/upload-signature", {
    method: "POST", signal,
  });
  const endpoint = new URL(signed.uploadUrl);
  if (
    endpoint.protocol !== "https:" || endpoint.hostname !== "api.cloudinary.com" ||
    endpoint.username || endpoint.password || endpoint.search || endpoint.hash ||
    !/^\/v1_1\/[^/]+\/(auto|image)\/upload$/.test(endpoint.pathname) ||
    !signed.apiKey || !signed.signature || !Number.isSafeInteger(signed.timestamp)
  ) throw new Error("Dịch vụ tải ảnh chưa sẵn sàng. Vui lòng thử lại sau.");

  const form = new FormData();
  form.set("file", file);
  form.set("signature", signed.signature);
  form.set("timestamp", String(signed.timestamp));
  form.set("api_key", signed.apiKey);
  if (signed.folder) form.set("folder", signed.folder);
  if (signed.publicId) form.set("public_id", signed.publicId);

  let response: Response;
  try {
    response = await fetch(endpoint, { method: "POST", body: form, signal });
  } catch (error) {
    if (signal.aborted) throw error;
    throw new Error("Không thể gửi ảnh. Kiểm tra kết nối mạng rồi thử lại; nội dung đánh giá vẫn được giữ.");
  }
  const uploaded = await response.json().catch(() => null);
  if (!response.ok) throw new Error(reviewUploadError(response.status, uploaded?.error?.message));
  if (uploaded?.resource_type !== "image" || typeof uploaded?.secure_url !== "string" || !safeReviewImage(uploaded.secure_url)) {
    throw new Error("Dịch vụ chưa trả về ảnh hợp lệ. Vui lòng thử lại với ảnh JPG, PNG hoặc WebP.");
  }
  return uploaded.secure_url as string;
}
