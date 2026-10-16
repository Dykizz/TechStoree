/**
 * Bộ Điều Phối Tìm Kiếm Toàn Diện (Master Search Engine)
 * Tích hợp:
 * 1. Text Normalization (Chuẩn hóa ký tự lạ, khoảng trắng, telex)
 * 2. Typo Tolerance (Sửa lỗi gõ sai với Damerau-Levenshtein)
 * 3. Synonyms & Context Semantics (Từ đồng nghĩa tiếng Việt/Anh & ngữ cảnh)
 * 4. Okapi BM25 / TF-IDF Ranking (Chấm điểm mức độ liên quan)
 * 5. Instant Autocomplete Suggestions (Gợi ý từ khóa & Sản phẩm tức thì)
 */

import type { ProductBaseDto } from "../types/product";
import { BM25Scorer } from "./bm25-scorer";
import { expandSynonyms } from "./synonyms";
import { normalizeText, removeVietnameseTones, tokenize } from "./text-normalizer";
import { correctTypo, TECH_VOCABULARY } from "./typo-corrector";

export interface AutocompleteResult {
  keywordSuggestions: string[];
  products: ProductBaseDto[];
  correctedQuery?: string;
  hasTypo: boolean;
}

export interface SearchExecutionResult {
  rankedProducts: ProductBaseDto[];
  totalMatches: number;
  originalQuery: string;
  effectiveQuery: string;
  hasTypo: boolean;
}

/**
 * 1. Hàm gợi ý tìm kiếm tức thì cho Dropdown (Autocomplete)
 * Thực thi trong < 5ms
 */
export function getAutocompleteSuggestions(
  rawQuery: string,
  products: ProductBaseDto[],
  maxKeywords = 5,
  maxProducts = 4,
): AutocompleteResult {
  const clean = normalizeText(rawQuery);
  if (!clean) {
    return {
      keywordSuggestions: [],
      products: [],
      hasTypo: false,
    };
  }

  // 1. Kiểm tra sửa lỗi chính tả nếu có
  const typoCheck = correctTypo(clean);
  const effectiveQuery = typoCheck.hasTypo ? typoCheck.corrected : clean;
  const effectiveNoTone = removeVietnameseTones(effectiveQuery);

  // 2. Tìm các từ khóa gợi ý từ Tech Vocabulary và Danh mục Tên sản phẩm
  const matchedKeywords = new Set<string>();

  // A. So khớp trong bộ từ vựng chuẩn
  for (const vocab of TECH_VOCABULARY) {
    const vocabNoTone = removeVietnameseTones(vocab);
    if (vocab.includes(effectiveQuery) || vocabNoTone.includes(effectiveNoTone)) {
      matchedKeywords.add(vocab);
    }
  }

  // B. So khớp trong tên các sản phẩm thực tế
  for (const prod of products) {
    const nameClean = normalizeText(prod.productName);
    const nameNoTone = removeVietnameseTones(nameClean);
    if (nameClean.includes(effectiveQuery) || nameNoTone.includes(effectiveNoTone)) {
      // Cắt gọn cụm từ khóa cho ngắn gọn, dễ đọc
      const tokens = nameClean.split(" ");
      const matchIdx = tokens.findIndex((t) =>
        removeVietnameseTones(t).includes(effectiveNoTone),
      );
      if (matchIdx !== -1) {
        const snippet = tokens.slice(Math.max(0, matchIdx - 1), matchIdx + 3).join(" ");
        if (snippet.length > 3) matchedKeywords.add(snippet);
      }
    }
  }

  const keywordSuggestions = Array.from(matchedKeywords).slice(0, maxKeywords);

  // 3. Sử dụng BM25 Scorer để lấy 3-4 sản phẩm xem nhanh khớp nhất
  const scorer = new BM25Scorer(products);
  const queryTokens = tokenize(effectiveQuery);
  const synonyms = expandSynonyms(effectiveQuery);
  const scored = scorer.score(queryTokens, synonyms);

  const topProducts = scored.slice(0, maxProducts).map((s) => s.product);

  return {
    keywordSuggestions,
    products: topProducts,
    correctedQuery: typoCheck.hasTypo ? typoCheck.corrected : undefined,
    hasTypo: typoCheck.hasTypo,
  };
}

/**
 * 2. Hàm thực thi tìm kiếm xếp hạng chính thức cho trang sản phẩm
 */
export function executeSearch(
  rawQuery: string,
  products: ProductBaseDto[],
): SearchExecutionResult {
  const clean = normalizeText(rawQuery);
  if (!clean) {
    return {
      rankedProducts: products,
      totalMatches: products.length,
      originalQuery: "",
      effectiveQuery: "",
      hasTypo: false,
    };
  }

  // 1. Kiểm tra và nhận diện lỗi chính tả
  const typoCheck = correctTypo(clean);
  const effectiveQuery = typoCheck.hasTypo ? typoCheck.corrected : clean;

  // 2. Mở rộng từ đồng nghĩa & ngữ cảnh
  const synonyms = expandSynonyms(effectiveQuery);
  const queryTokens = tokenize(effectiveQuery);

  // 3. Chấm điểm Okapi BM25 / TF-IDF
  const scorer = new BM25Scorer(products);
  const scoredResults = scorer.score(queryTokens, synonyms);

  // 4. Nếu kết quả theo effectiveQuery có sản phẩm -> dùng kết quả đó
  // Nếu vẫn = 0 và đã từng sửa chính tả, thử tìm lại bằng query gốc
  let finalProducts = scoredResults.map((s) => s.product);
  let effectiveApplied = effectiveQuery;
  let hasTypo = typoCheck.hasTypo;

  if (finalProducts.length === 0 && typoCheck.hasTypo) {
    const rawTokens = tokenize(clean);
    const rawScored = scorer.score(rawTokens, expandSynonyms(clean));
    if (rawScored.length > 0) {
      finalProducts = rawScored.map((s) => s.product);
      effectiveApplied = clean;
      hasTypo = false;
    }
  }

  return {
    rankedProducts: finalProducts,
    totalMatches: finalProducts.length,
    originalQuery: rawQuery,
    effectiveQuery: effectiveApplied,
    hasTypo: hasTypo && finalProducts.length > 0,
  };
}
