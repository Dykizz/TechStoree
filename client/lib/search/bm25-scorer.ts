/**
 * Thuật toán xếp hạng mức độ liên quan Okapi BM25 / TF-IDF (Relevance Scoring Engine)
 * - Term Frequency (TF): Tần suất xuất hiện từ khóa trong sản phẩm
 * - Inverse Document Frequency (IDF): Mức độ quý hiếm của từ khóa trong kho hàng
 * - Field Boosting: Trọng số ưu tiên (Tên sản phẩm x5.0 > Danh mục x2.5 > Khuyến mãi x1.5 > Mô tả x1.0)
 */

import type { ProductBaseDto } from "../types/product";
import { normalizeText, removeVietnameseTones, tokenize } from "./text-normalizer";

const K1 = 1.2;
const B = 0.75;

interface DocumentIndex {
  product: ProductBaseDto;
  titleTokens: string[];
  categoryTokens: string[];
  descTokens: string[];
  allTokens: string[];
  docLength: number;
  rawTitleClean: string;
  rawTitleNoTone: string;
}

export class BM25Scorer {
  private docs: DocumentIndex[] = [];
  private avgDocLength = 0;
  private idfMap = new Map<string, number>();

  constructor(products: ProductBaseDto[]) {
    this.buildIndex(products);
  }

  /**
   * Xây dựng chỉ mục tính toán trước các token và IDF cho toàn bộ danh mục sản phẩm
   */
  private buildIndex(products: ProductBaseDto[]) {
    const totalDocs = products.length;
    let totalLength = 0;
    const docFrequency = new Map<string, number>();

    this.docs = products.map((product) => {
      const titleTokens = tokenize(product.productName);
      const categoryTokens = tokenize(product.categoryName);
      const promoTokens = product.promotion?.promotionName
        ? tokenize(product.promotion.promotionName)
        : [];

      const allTokens = [...titleTokens, ...categoryTokens, ...promoTokens];
      const docLength = allTokens.length;
      totalLength += docLength;

      // Đếm số lượng document chứa token
      const uniqueTokens = new Set(allTokens);
      for (const token of uniqueTokens) {
        docFrequency.set(token, (docFrequency.get(token) || 0) + 1);
        const noTone = removeVietnameseTones(token);
        if (noTone !== token) {
          docFrequency.set(noTone, (docFrequency.get(noTone) || 0) + 1);
        }
      }

      return {
        product,
        titleTokens,
        categoryTokens,
        descTokens: promoTokens,
        allTokens,
        docLength,
        rawTitleClean: normalizeText(product.productName),
        rawTitleNoTone: removeVietnameseTones(normalizeText(product.productName)),
      };
    });

    this.avgDocLength = totalDocs > 0 ? totalLength / totalDocs : 1;

    // Tính toán IDF cho từng token theo công thức chuẩn Okapi BM25:
    // IDF(q) = ln( 1 + (N - n(q) + 0.5) / (n(q) + 0.5) )
    for (const [token, n] of docFrequency.entries()) {
      const idf = Math.log(1 + (totalDocs - n + 0.5) / (n + 0.5));
      this.idfMap.set(token, Math.max(idf, 0.1));
    }
  }

  /**
   * Chấm điểm và xếp hạng danh sách sản phẩm theo câu truy vấn
   */
  public score(
    queryTokens: string[],
    expandedSynonyms: string[] = [],
  ): Array<{ product: ProductBaseDto; score: number }> {
    if (queryTokens.length === 0 || this.docs.length === 0) {
      return this.docs.map((d) => ({ product: d.product, score: 0 }));
    }

    const fullQueryString = queryTokens.join(" ");
    const fullQueryNoTone = removeVietnameseTones(fullQueryString);

    const scoredResults: Array<{ product: ProductBaseDto; score: number }> = [];

    for (const doc of this.docs) {
      let score = 0;

      // 1. Exact Match & Prefix Match Bonus (Ưu tiên số 1 cho trùng khớp chính xác)
      if (doc.rawTitleClean === fullQueryString || doc.rawTitleNoTone === fullQueryNoTone) {
        score += 35.0; // Khớp chính xác 100% tên
      } else if (
        doc.rawTitleClean.includes(fullQueryString) ||
        doc.rawTitleNoTone.includes(fullQueryNoTone)
      ) {
        score += 20.0; // Chứa nguyên cụm từ khóa liên tiếp
      }

      // 2. Tính điểm BM25 cho từng token trong query
      let matchedTokenCount = 0;
      for (const token of queryTokens) {
        const tokenNoTone = removeVietnameseTones(token);
        const idf = this.idfMap.get(token) || this.idfMap.get(tokenNoTone) || 0.5;

        // Đếm tần suất TF theo từng trường có gán trọng số
        const tfTitle = doc.titleTokens.filter(
          (t) => t === token || removeVietnameseTones(t) === tokenNoTone,
        ).length;
        const tfCategory = doc.categoryTokens.filter(
          (t) => t === token || removeVietnameseTones(t) === tokenNoTone,
        ).length;
        const tfDesc = doc.descTokens.filter(
          (t) => t === token || removeVietnameseTones(t) === tokenNoTone,
        ).length;

        // Tổng TF kết hợp Field Boosting
        const weightedTf = tfTitle * 5.0 + tfCategory * 2.5 + tfDesc * 1.0;

        if (weightedTf > 0) {
          matchedTokenCount++;
          // Công thức BM25 Term Score
          const numerator = weightedTf * (K1 + 1);
          const denominator =
            weightedTf + K1 * (1 - B + B * (doc.docLength / (this.avgDocLength || 1)));
          score += idf * (numerator / denominator);
        }
      }

      // Thưởng điểm nếu chứa TẤT CẢ các từ trong query
      if (matchedTokenCount === queryTokens.length && queryTokens.length > 1) {
        score += 15.0;
      }

      // 3. Tính điểm bổ sung từ Từ đồng nghĩa (Synonyms Expansion)
      if (expandedSynonyms.length > 0) {
        for (const syn of expandedSynonyms) {
          if (
            doc.rawTitleClean.includes(syn) ||
            doc.rawTitleNoTone.includes(removeVietnameseTones(syn))
          ) {
            score += 4.5;
          }
        }
      }

      if (score > 0) {
        scoredResults.push({ product: doc.product, score });
      }
    }

    // Sắp xếp điểm BM25 từ cao nhất xuống thấp nhất
    return scoredResults.sort((a, b) => b.score - a.score);
  }
}
