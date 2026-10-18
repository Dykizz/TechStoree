/**
 * Bảng từ điển từ đồng nghĩa & mở rộng ngữ nghĩa công nghệ (Synonyms Engine)
 * Giúp nhận diện từ địa phương ("cốc" = "ly" = "củ sạc")
 * và từ tương đương tiếng Anh / tiếng Việt ("tai nghe" = "headphone", "chuột" = "mouse")
 */

import { normalizeText } from "./text-normalizer";

// Danh mục các nhóm từ đồng nghĩa song phương
const SYNONYM_GROUPS: string[][] = [
  // Tai nghe & Âm thanh
  ["tai nghe", "headphone", "earphone", "airpods", "airpod", "headset", "am thanh"],
  // Chuột máy tính
  ["chuot", "chuột", "mouse", "chuot khong day", "chuột không dây", "cong thai hoc", "công thái học", "logitech", "mx master"],
  // Bàn phím
  ["ban phim", "bàn phím", "keyboard", "ban phim co", "bàn phím cơ", "fl esports", "fl-esports"],
  // Máy tính & Laptop
  ["may tinh", "máy tính", "laptop", "lap top", "macbook", "notebook", "zenbook", "nitro", "may tinh xach tay"],
  // Điện thoại
  ["dien thoai", "điện thoại", "dt", "đt", "smartphone", "iphone", "galaxy", "dien thoai thong minh"],
  // Củ sạc & Nguồn
  ["coc", "cốc", "ly", "cu sac", "củ sạc", "cuc sac", "cục sạc", "adapter", "sac nhanh", "sạc nhanh", "magsafe"],
  // Màn hình
  ["man hinh", "màn hình", "monitor", "screen", "display", "ultrasharp", "ultragear"],
  // Robot hút bụi & SmartHome
  ["robot", "hut bui", "hút bụi", "may hut bui", "máy hút bụi", "dreame", "xiaomi", "smarthome", "nha thong minh"],
];

// Mở rộng ngữ nghĩa theo ngữ cảnh (Contextual Semantics)
const CONTEXTUAL_RULES: Array<{
  triggerRegex: RegExp;
  expandedKeywords: string[];
}> = [
  {
    // Ngữ cảnh: "laptop do hoa", "laptop đồ họa", "may tinh do hoa"
    triggerRegex: /do\s*hoa|đồ\s*họa/i,
    expandedKeywords: ["laptop", "zenbook", "oled", "nitro", "ultrasharp", "rtx"],
  },
  {
    // Ngữ cảnh: "dien thoai nap gap", "điện thoại gập"
    triggerRegex: /nap\s*gap|nắp\s*gập|gap|gập/i,
    expandedKeywords: ["flip", "fold", "galaxy", "dien thoai"],
  },
  {
    // Ngữ cảnh: "qua sinh nhat", "quà cho nữ", "quà tặng"
    triggerRegex: /qua\s*sinh\s*nhat|quà|tang|tặng/i,
    expandedKeywords: ["airpods", "tai nghe", "sony", "robot", "dreame"],
  },
  {
    // Ngữ cảnh: "choi game", "gaming", "game thủ"
    triggerRegex: /gaming|choi\s*game|chơi\s*game|game/i,
    expandedKeywords: ["nitro", "ultragear", "ban phim co", "bàn phím", "chuot", "chuột", "144hz", "165hz"],
  },
];

/**
 * Lấy danh sách các từ đồng nghĩa bổ sung cho 1 từ/cụm từ
 */
export function expandSynonyms(query: string): string[] {
  const clean = normalizeText(query);
  const expansions = new Set<string>();
  expansions.add(clean);

  // 1. Quét qua các nhóm từ đồng nghĩa
  for (const group of SYNONYM_GROUPS) {
    const matched = group.some(
      (term) => clean.includes(term) || term.includes(clean),
    );
    if (matched) {
      for (const term of group) {
        expansions.add(term);
      }
    }
  }

  // 2. Quét qua các luật ngữ cảnh
  for (const rule of CONTEXTUAL_RULES) {
    if (rule.triggerRegex.test(clean)) {
      for (const kw of rule.expandedKeywords) {
        expansions.add(kw);
      }
    }
  }

  return Array.from(expansions);
}
