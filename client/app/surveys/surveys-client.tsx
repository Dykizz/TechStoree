"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent } from "react";
import { useProtectedSession } from "../../lib/use-protected-session";
import { publishNotification } from "../../lib/customer-notifications";
import type {
  CustomerSurvey,
  SurveyForm,
  SurveyResult,
} from "../../lib/surveys-api";
import styles from "./surveys.module.css";

export default function SurveysClient({ surveyId }: { surveyId?: string }) {
  const session = useProtectedSession();
  const router = useRouter();
  const [list, setList] = useState<CustomerSurvey[]>([]);
  const [form, setForm] = useState<SurveyForm | null>(null);
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [filter, setFilter] = useState("all");
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<SurveyResult | null>(null);

  useEffect(() => {
    if (session.status !== "ready") return;
    const controller = new AbortController();
    async function load() {
      setLoaded(false);
      setError("");
      try {
        const response = await fetch(
          surveyId
            ? `/api/surveys/${encodeURIComponent(surveyId)}`
            : "/api/surveys",
          { cache: "no-store", signal: controller.signal },
        );
        const body = await response.json();
        if (response.status === 401) {
          router.replace(
            `/login?next=${encodeURIComponent(surveyId ? "/surveys/" + surveyId : "/surveys")}`,
          );
          return;
        }
        if (!response.ok || !body.success || !body.data)
          throw new Error(body.message || "Không thể tải khảo sát.");
        if (!controller.signal.aborted) {
          if (surveyId) {
            if (!Array.isArray(body.data.questions))
              throw new Error("Biểu mẫu khảo sát không hợp lệ.");
            setForm(body.data);
          } else {
            if (!Array.isArray(body.data))
              throw new Error("Danh sách khảo sát không hợp lệ.");
            setList(body.data);
          }
          setLoaded(true);
        }
      } catch (e) {
        if (!controller.signal.aborted)
          setError(
            e instanceof Error ? e.message : "Không thể kết nối đến máy chủ.",
          );
      }
    }
    void load();
    return () => controller.abort();
  }, [session.status, surveyId, attempt, router]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form || submitting || result) return;
    const missing = form.questions.find(
      (q) => q.isRequired && !answers[q.questionId]?.trim(),
    );
    if (missing) {
      setError(`Vui lòng trả lời: ${missing.questionText}`);
      return;
    }
    setSubmitting(true);
    setError("");
    try {
      const response = await fetch(`/api/surveys/${form.surveyId}/submit`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          answers: form.questions
            .filter((q) => answers[q.questionId]?.trim())
            .map((q) => ({
              questionId: q.questionId,
              ...(q.questionType === "SINGLE_CHOICE"
                ? { selectedOptionId: Number(answers[q.questionId]) }
                : { textAnswer: answers[q.questionId].trim() }),
            })),
        }),
      });
      const body = await response.json();
      if (response.status === 401) {
        router.replace(
          `/login?next=${encodeURIComponent("/surveys/" + form.surveyId)}`,
        );
        return;
      }
      if (!response.ok || !body.success || !body.data?.success)
        throw new Error(
          body.message ||
            "Chưa nộp được khảo sát. Câu trả lời của bạn vẫn được giữ lại.",
        );
      setResult(body.data);
      if (session.status === "ready") {
        publishNotification(session.user.userId, {
          id: `survey:${form.surveyId}`,
          kind: "survey",
          title: "Đã hoàn thành khảo sát",
          message: `Câu trả lời của bạn đã được ghi nhận.${body.data.rewardVoucher ? " Phần thưởng đã được hệ thống cấp; xem tại khảo sát." : ""}`,
          href: "/surveys",
        });
      }
    } catch (e) {
      setError(
        e instanceof Error
          ? e.message
          : "Không thể nộp khảo sát. Vui lòng thử lại.",
      );
    } finally {
      setSubmitting(false);
    }
  }
  const visible = list.filter(
    (item) => filter === "all" || item.isCompleted === (filter === "completed"),
  );
  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <Link href={surveyId ? "/surveys" : "/profile"} className={styles.back}>
          ← {surveyId ? "Khảo sát của tôi" : "Hồ sơ cá nhân"}
        </Link>
        <p className={styles.eyebrow}>TÀI KHOẢN TECHSTOREE</p>
        <h1>
          {surveyId
            ? form?.title || "Thực hiện khảo sát"
            : "Ý kiến của bạn. Trải nghiệm tốt hơn."}
        </h1>
        <p className={styles.description}>
          {surveyId
            ? form?.description
            : "Các khảo sát được giao riêng cho tài khoản của bạn. Phần thưởng, nếu có, được xác nhận bởi hệ thống sau khi nộp."}
        </p>
        {session.status === "error" ? (
          <div className={styles.error} role="alert">
            {session.message}
            <button onClick={session.retry}>Thử lại</button>
          </div>
        ) : session.status === "checking" || (!loaded && !error) ? (
          <p role="status">Đang tải khảo sát…</p>
        ) : null}
        {error && (
          <div className={styles.error} role="alert">
            {error}
            {!form && (
              <button onClick={() => setAttempt((v) => v + 1)}>Thử lại</button>
            )}
          </div>
        )}
        {result ? (
          <section className={styles.card} role="status">
            <p className={styles.eyebrow}>ĐÃ HOÀN THÀNH</p>
            <h2>Cảm ơn bạn đã chia sẻ.</h2>
            <p>{result.message}</p>
            {result.rewardVoucher && (
              <div className={styles.reward}>
                <strong>{result.rewardVoucher.title}</strong>
                <p>
                  Mã ưu đãi: <code>{result.rewardVoucher.code}</code>
                </p>
                <p>
                  Điều kiện sử dụng được kiểm tra khi áp dụng mã tại giỏ hàng.
                </p>
              </div>
            )}
            <Link className={styles.primary} href="/surveys">
              Về danh sách khảo sát
            </Link>
          </section>
        ) : surveyId && form ? (
          <form onSubmit={(event) => void submit(event)}>
            {form.rewardVoucherTitle && (
              <p className={styles.reward}>
                Phần thưởng dự kiến: {form.rewardVoucherTitle}
              </p>
            )}
            {form.questions.length === 0 ? (
              <p>Khảo sát chưa có câu hỏi. Vui lòng quay lại sau.</p>
            ) : (
              <>
                <div className={styles.questions}>
                  {[...form.questions]
                    .sort((a, b) => a.orderNum - b.orderNum)
                    .map((q, index) => (
                      <fieldset
                        className={styles.card}
                        key={q.questionId}
                        disabled={submitting}
                      >
                        <legend>
                          {index + 1}. {q.questionText}{" "}
                          {q.isRequired && <span title="Bắt buộc">*</span>}
                        </legend>
                        {q.questionType === "SINGLE_CHOICE" ? (
                          [...q.options]
                            .sort((a, b) => a.orderNum - b.orderNum)
                            .map((option) => (
                              <label
                                className={styles.choice}
                                key={option.optionId}
                              >
                                <input
                                  type="radio"
                                  name={`question-${q.questionId}`}
                                  required={q.isRequired}
                                  value={option.optionId}
                                  checked={
                                    answers[q.questionId] ===
                                    String(option.optionId)
                                  }
                                  onChange={(e) =>
                                    setAnswers((a) => ({
                                      ...a,
                                      [q.questionId]: e.target.value,
                                    }))
                                  }
                                />
                                {option.optionText}
                              </label>
                            ))
                        ) : (
                          <textarea
                            aria-label={q.questionText}
                            required={q.isRequired}
                            maxLength={5000}
                            rows={4}
                            value={answers[q.questionId] || ""}
                            onChange={(e) =>
                              setAnswers((a) => ({
                                ...a,
                                [q.questionId]: e.target.value,
                              }))
                            }
                          />
                        )}
                      </fieldset>
                    ))}
                </div>
                <div className={styles.actions}>
                  <p>
                    Câu có dấu * là bắt buộc. Sau khi nộp, bạn không thể sửa câu
                    trả lời.
                  </p>
                  <button className={styles.primary} disabled={submitting}>
                    {submitting ? "Đang nộp…" : "Nộp khảo sát"}
                  </button>
                </div>
              </>
            )}
          </form>
        ) : (
          !surveyId &&
          loaded && (
            <>
              <div className={styles.filters} aria-label="Lọc khảo sát">
                {[
                  ["all", "Tất cả"],
                  ["pending", "Chưa thực hiện"],
                  ["completed", "Đã hoàn thành"],
                ].map(([key, label]) => (
                  <button
                    key={key}
                    aria-pressed={filter === key}
                    onClick={() => setFilter(key)}
                  >
                    {label}
                  </button>
                ))}
              </div>
              {visible.length === 0 ? (
                <section className={styles.card}>
                  <h2>Chưa có khảo sát trong mục này.</h2>
                  <p>Khi được phân công khảo sát mới, bạn sẽ thấy tại đây.</p>
                </section>
              ) : (
                <div className={styles.grid}>
                  {visible.map((item) => (
                    <article className={styles.card} key={item.surveyId}>
                      <p className={styles.eyebrow}>
                        {item.isCompleted ? "ĐÃ HOÀN THÀNH" : "CHƯA THỰC HIỆN"}
                      </p>
                      <h2>{item.title}</h2>
                      <p>{item.description}</p>
                      {item.rewardVoucherTitle && (
                        <p className={styles.reward}>
                          {item.isCompleted
                            ? "Phần thưởng của khảo sát"
                            : "Phần thưởng dự kiến"}
                          : {item.rewardVoucherTitle}
                        </p>
                      )}
                      {item.isCompleted ? (
                        <p>
                          Đã nộp{" "}
                          {item.completedAt &&
                            new Date(item.completedAt).toLocaleDateString(
                              "vi-VN",
                            )}
                        </p>
                      ) : (
                        <Link
                          className={styles.primary}
                          href={`/surveys/${item.surveyId}`}
                        >
                          Bắt đầu khảo sát ↗
                        </Link>
                      )}
                    </article>
                  ))}
                </div>
              )}
            </>
          )
        )}
      </div>
    </main>
  );
}
