/**
 * Bộ chuẩn hóa văn bản tiếng Việt & công nghệ (Text Normalizer)
 * - Rút gọn khoảng trắng thừa
 * - Loại bỏ ký tự đặc biệt gây nhiễu (@, #, --, !, ?)
 * - Khử dấu tiếng Việt phục vụ so sánh không dấu
 * - Sửa lỗi gõ Telex phổ biến (chuôtj -> chuột, sam sung -> samsung)
 */

// Bảng ánh xạ khử dấu tiếng Việt sang ký tự Latin chuẩn
const VIETNAMESE_ACCENT_MAP: Record<string, string> = {
  a: "á|à|ả|ã|ạ|ă|ắ|ặ|ằ|ẳ|ẵ|â|ấ|ầ|ẩ|ẫ|ậ",
  d: "đ",
  e: "é|è|ẻ|ẽ|ẹ|ê|ế|ề|ể|ễ|ệ",
  i: "í|ì|ỉ|ĩ|ị",
  o: "ó|ò|ỏ|õ|ọ|ô|ố|ồ|ổ|ỗ|ộ|ơ|ớ|ờ|ở|ỡ|ợ",
  u: "ú|ù|ủ|ũ|ụ|ư|ứ|ừ|ử|ữ|ự",
  y: "ý|ỳ|ỷ|ỹ|ỵ",
};

/**
 * Chuẩn hóa chuỗi tìm kiếm cơ bản:
 * Xóa ký tự lạ, rút gọn khoảng trắng, đưa về chữ thường
 * Ví dụ: "   mAcBOok -- aiR  " -> "macbook air"
 *        "macbook@air" -> "macbook air"
 */
export function normalizeText(text: string): string {
  if (!text) return "";
  return text
    .toLowerCase()
    .replace(/[@#\-_!?:*()\/\\~^&+=|;,"'[\]{}<>]/g, " ") // Thay ký tự đặc biệt bằng khoảng trắng
    .replace(/\s+/g, " ") // Rút gọn nhiều khoảng trắng liên tiếp
    .trim();
}

/**
 * Khử hoàn toàn dấu tiếng Việt để so khớp không dấu
 * Ví dụ: "Bàn phím cơ" -> "ban phim co"
 */
export function removeVietnameseTones(text: string): string {
  let result = text.toLowerCase();
  for (const [nonAccent, accentPattern] of Object.entries(VIETNAMESE_ACCENT_MAP)) {
    result = result.replace(new RegExp(accentPattern, "g"), nonAccent);
  }
  return result;
}

/**
 * Xử lý các lỗi gõ Telex dính phím hoặc sai vị trí dấu phổ biến
 * Ví dụ: "chuôtj" -> "chuột", "ddieejn thoaij" -> "điện thoại"
 */
const TELEX_FAULTY_PATTERNS: Array<[RegExp, string]> = [
  [/chu[oô]tj/gi, "chuột"],
  [/ban\s*ph[ií]mj/gi, "bàn phím"],
  [/ddieejn\s*thoaij/gi, "điện thoại"],
  [/tai\s*nghe/gi, "tai nghe"],
  [/head\s*phone/gi, "headphone"],
  [/sam\s*sung/gi, "samsung"],
  [/lap\s*top/gi, "laptop"],
  [/mac\s*book/gi, "macbook"],
  [/air\s*pod[s]?/gi, "airpods"],
  [/logi\s*tech/gi, "logitech"],
];

export function fixVietnameseTelex(text: string): string {
  let normalized = text;
  for (const [regex, replacement] of TELEX_FAULTY_PATTERNS) {
    normalized = normalized.replace(regex, replacement);
  }
  return normalized;
}

/**
 * Tách chuỗi thành danh sách các từ đơn (Tokens) sạch
 */
export function tokenize(text: string): string[] {
  const clean = normalizeText(text);
  if (!clean) return [];
  return clean.split(" ").filter((t) => t.length > 0);
}
