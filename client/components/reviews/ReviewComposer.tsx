"use client";

import Image from "next/image";
import { useEffect, useId, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import { MAX_REVIEW_IMAGE_BYTES, MAX_REVIEW_IMAGES, canEditReview, reviewRequest, type MyReview, type PendingReviewItem } from "../../lib/reviews";
import { uploadReviewImage } from "../../lib/review-upload";
import { RatingPicker } from "./StarRating";
import ReviewThumbnail from "./ReviewThumbnail";
import styles from "./reviews.module.css";

export default function ReviewComposer({ item, review, onClose, onSaved }: { item?: PendingReviewItem; review?: MyReview; onClose: () => void; onSaved: (review: MyReview) => void }) {
  const dialog = useRef<HTMLDialogElement>(null);
  const saving = useRef(false);
  const transfer = useRef<AbortController | null>(null);
  const titleId = useId();
  const [rating, setRating] = useState(review?.rating ?? 5);
  const [comment, setComment] = useState(review?.comment ?? "");
  const [images, setImages] = useState<string[]>(review?.imageUrls ?? []);
  const [busy, setBusy] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");
  const locked = busy || uploading;
  const name = review?.productName || item?.productName;
  const image = review?.productImageUrl || item?.imageUrl;

  useEffect(() => {
    const element = dialog.current;
    const overflow = document.body.style.overflow;
    element?.showModal();
    document.body.style.overflow = "hidden";
    return () => { transfer.current?.abort(); element?.close(); document.body.style.overflow = overflow; };
  }, []);

  async function upload(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files || []);
    event.target.value = "";
    if (!files.length || saving.current) return;
    if (files.length + images.length > MAX_REVIEW_IMAGES) { setError(`Bạn có thể đính kèm tối đa ${MAX_REVIEW_IMAGES} ảnh.`); return; }
    if (files.some((file) => !["image/jpeg", "image/png", "image/webp"].includes(file.type) || file.size > MAX_REVIEW_IMAGE_BYTES || !file.size)) { setError("Chọn ảnh JPG, PNG hoặc WebP, tối đa 5 MB mỗi ảnh."); return; }
    saving.current = true;
    setUploading(true); setError("");
    const controller = new AbortController(); transfer.current = controller;
    try {
      for (const file of files) {
        const imageUrl = await uploadReviewImage(file, controller.signal);
        if (!controller.signal.aborted) setImages((current) => [...current, imageUrl]);
      }
    } catch (e) {
      if (!controller.signal.aborted) setError(e instanceof Error ? e.message : "Chưa tải được ảnh. Vui lòng thử lại.");
    } finally {
      saving.current = false;
      if (!controller.signal.aborted) setUploading(false);
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (saving.current || locked) return;
    if (review && !canEditReview(review)) { setError("Đánh giá đã quá thời hạn chỉnh sửa 30 ngày."); return; }
    saving.current = true; setBusy(true); setError("");
    const controller = new AbortController(); transfer.current = controller;
    try {
      const result = await reviewRequest<MyReview>(review ? `/api/reviews/${review.reviewId}` : "/api/reviews", {
        method: review ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, signal: controller.signal,
        body: JSON.stringify({ rating, comment: comment.trim(), imageUrls: images, ...(!review ? { orderItemId: item?.orderItemId } : {}) }),
      });
      if (!controller.signal.aborted) onSaved(result);
    } catch (e) {
      if (!controller.signal.aborted) setError(e instanceof Error ? e.message : "Chưa gửi được đánh giá. Nội dung của bạn vẫn được giữ.");
    } finally {
      saving.current = false;
      if (!controller.signal.aborted) setBusy(false);
    }
  }

  return (
    <dialog ref={dialog} className={styles.dialog} aria-labelledby={titleId} onCancel={(event) => { event.preventDefault(); if (!locked) onClose(); }}>
      <div className={styles.dialogHeader}><div><p className={styles.eyebrow}>CHIA SẺ TRẢI NGHIỆM</p><h2 id={titleId}>{review ? "Chỉnh sửa đánh giá" : "Đánh giá sản phẩm"}</h2></div><button type="button" className={styles.closeButton} aria-label="Đóng biểu mẫu đánh giá" disabled={locked} onClick={onClose}>×</button></div>
      <form onSubmit={submit} aria-busy={locked}>
        <div className={styles.dialogBody}>
          <div className={styles.composerProduct}><ReviewThumbnail src={image} name={name || "Sản phẩm đã mua"} /><div><strong>{name}</strong><p>{review?.variantName || item?.variantName}</p><span>Đơn {review?.orderCode || item?.orderCode}</span></div></div>
          <RatingPicker value={rating} onChange={setRating} disabled={locked} />
          <div className={styles.commentField}><label htmlFor={`${titleId}-comment`}>Chia sẻ cảm nhận của bạn</label><textarea id={`${titleId}-comment`} autoFocus maxLength={1000} rows={5} value={comment} disabled={locked} onChange={(event) => setComment(event.target.value)} placeholder="Điều bạn thích, chất lượng và trải nghiệm sử dụng thực tế…" /><span className={styles.hint}>{comment.length} / 1.000 ký tự · Không bắt buộc</span></div>
          <fieldset className={styles.uploadField} disabled={locked}>
            <legend>Ảnh trải nghiệm thực tế</legend>
            <div className={styles.uploadedImages}>{images.map((url, index) => <div key={`${url}-${index}`}><Image src={url} alt={`Ảnh đính kèm ${index + 1}`} width={76} height={76} unoptimized /><button type="button" aria-label={`Bỏ ảnh đính kèm ${index + 1}`} onClick={() => setImages((current) => current.filter((_, currentIndex) => index !== currentIndex))}>×</button></div>)}</div>
            {images.length < MAX_REVIEW_IMAGES && <label className={styles.uploadButton}>＋ Thêm ảnh<input type="file" accept="image/jpeg,image/png,image/webp" multiple onChange={(event) => void upload(event)} /></label>}
            <p className={styles.hint}>Tối đa 5 ảnh JPG, PNG hoặc WebP, mỗi ảnh tối đa 5 MB.</p>
          </fieldset>
          {uploading && <p className={styles.hint} role="status">Đang tải ảnh… Vui lòng giữ biểu mẫu mở.</p>}
          {error && <p className={styles.error} role="alert">{error}</p>}
        </div>
        <div className={styles.dialogFooter}><button type="button" className={styles.secondaryButton} disabled={locked} onClick={onClose}>Hủy</button><button className={styles.primaryButton} disabled={locked}>{busy ? "Đang lưu…" : uploading ? "Đang tải ảnh…" : review ? "Lưu thay đổi" : "Gửi đánh giá"}</button></div>
      </form>
    </dialog>
  );
}
