/**
 * Thuật toán chịu lỗi chính tả (Typo Tolerance) & Sửa lỗi gõ sai
 * Sử dụng khoảng cách Damerau-Levenshtein Distance kết hợp từ điển từ vựng công nghệ
 */

import { fixVietnameseTelex, normalizeText } from "./text-normalizer";

// Bảng từ vựng chuẩn hóa của hệ thống TechStoree
export const TECH_VOCABULARY: string[] = [
  "iphone",
  "ipad",
  "macbook",
  "macbook air",
  "macbook pro",
  "apple",
  "airpods",
  "samsung",
  "galaxy",
  "asus",
  "zenbook",
  "acer",
  "nitro",
  "sony",
  "logitech",
  "dell",
  "lg",
  "xiaomi",
  "dreame",
  "fl esports",
  "laptop",
  "laptop gaming",
  "tai nghe",
  "tai nghe bluetooth",
  "tai nghe chong on",
  "chuột",
  "chuột không dây",
  "chuột công thái học",
  "bàn phím",
  "bàn phím cơ",
  "robot hút bụi",
  "màn hình",
  "màn hình đồ họa",
  "màn hình gaming",
  "củ sạc",
  "cáp sạc",
  "headphone",
  "keyboard",
  "mouse",
  "ultrasharp",
  "ultragear",
  "mx master",
];

// Danh mục ánh xạ nhanh các lỗi gõ sai cực kỳ phổ biến
const COMMON_TYPO_MAPPING: Record<string, string> = {
  iphon: "iphone",
  ipone: "iphone",
  ifone: "iphone",
  macbok: "macbook",
  macbbook: "macbook",
  "sam sung": "samsung",
  "sam sung galxy": "samsung galaxy",
  galxy: "galaxy",
  glaxy: "galaxy",
  "lap top": "laptop",
  "lap top gamin": "laptop gaming",
  gamin: "gaming",
  gaiming: "gaming",
  chuôtj: "chuột",
  chuotj: "chuột",
  banphim: "bàn phím",
  "ban phim": "bàn phím",
  tainghe: "tai nghe",
  soni: "sony",
  logitec: "logitech",
  assus: "asus",
  delle: "dell",
  delll: "dell",
  airpod: "airpods",
  aripods: "airpods",
  headphon: "headphone",
  keyboar: "keyboard",
};

/**
 * Tính khoảng cách Damerau-Levenshtein giữa 2 chuỗi
 * (Bao gồm chèn, xóa, thay thế và hoán vị 2 ký tự liền kề)
 */
export function damerauLevenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;

  const lenA = a.length;
  const lenB = b.length;
  const matrix: number[][] = Array.from({ length: lenA + 1 }, () =>
    new Array(lenB + 1).fill(0),
  );

  for (let i = 0; i <= lenA; i++) matrix[i][0] = i;
  for (let j = 0; j <= lenB; j++) matrix[0][j] = j;

  for (let i = 1; i <= lenA; i++) {
    for (let j = 1; j <= lenB; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1, // Xóa
        matrix[i][j - 1] + 1, // Chèn
        matrix[i - 1][j - 1] + cost, // Thay thế
      );

      // Hoán vị 2 ký tự liền kề (Transposition)
      if (
        i > 1 &&
        j > 1 &&
        a[i - 1] === b[j - 2] &&
        a[i - 2] === b[j - 1]
      ) {
        matrix[i][j] = Math.min(matrix[i][j], matrix[i - 2][j - 2] + 1);
      }
    }
  }

  return matrix[lenA][lenB];
}

/**
 * Kiểm tra và sửa lỗi chính tả cho câu truy vấn
 * @returns { original: string, corrected: string, hasTypo: boolean }
 */
export function correctTypo(rawQuery: string): {
  original: string;
  corrected: string;
  hasTypo: boolean;
} {
  const original = rawQuery.trim();
  if (!original) {
    return { original: "", corrected: "", hasTypo: false };
  }

  const clean = normalizeText(original);
  const telexFixed = fixVietnameseTelex(clean);
  let normalized = telexFixed;

  // 1. Kiểm tra bảng ánh xạ nhanh các cụm từ sai phổ biến
  if (COMMON_TYPO_MAPPING[clean] || COMMON_TYPO_MAPPING[normalized]) {
    const fixed = COMMON_TYPO_MAPPING[clean] || COMMON_TYPO_MAPPING[normalized];
    return {
      original,
      corrected: fixed,
      hasTypo: true,
    };
  }

  // 2. Tách thành các từ và sửa từng từ nếu có sai sót
  const words = normalized.split(" ").filter(Boolean);
  let anyWordFixed = normalized !== clean;
  const correctedWords: string[] = [];

  for (const word of words) {
    if (COMMON_TYPO_MAPPING[word]) {
      correctedWords.push(COMMON_TYPO_MAPPING[word]);
      anyWordFixed = true;
      continue;
    }

    // Nếu từ quá ngắn (< 3 ký tự) thì giữ nguyên
    if (word.length < 3) {
      correctedWords.push(word);
      continue;
    }

    // Tìm từ gần nhất trong từ điển
    let bestMatch = word;
    let minDistance = 999;

    for (const vocab of TECH_VOCABULARY) {
      // Chỉ so sánh với các từ đơn
      if (vocab.includes(" ")) continue;

      const dist = damerauLevenshtein(word, vocab);
      const maxAllowedDist = word.length <= 4 ? 1 : 2; // Từ ngắn chỉ cho sai 1 ký tự

      if (dist <= maxAllowedDist && dist < minDistance) {
        minDistance = dist;
        bestMatch = vocab;
      }
    }

    if (bestMatch !== word) {
      correctedWords.push(bestMatch);
      anyWordFixed = true;
    } else {
      correctedWords.push(word);
    }
  }

  const finalCorrected = correctedWords.join(" ");
  const hasTypo = anyWordFixed && finalCorrected.toLowerCase() !== clean.toLowerCase();

  return {
    original,
    corrected: hasTypo ? finalCorrected : original,
    hasTypo,
  };
}
