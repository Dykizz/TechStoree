"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent } from "react";
import { useProtectedSession } from "@/lib/use-protected-session";
import { publishNotification } from "@/lib/customer-notifications";
import { useSurveys } from "@/hooks/queries/useSurveys";
import { useSurveyDetail } from "@/hooks/queries/useSurveyDetail";
import { useSubmitSurvey } from "@/hooks/mutations/useSubmitSurvey";
import type {
  SurveyResult,
} from "@/lib/surveys-api";
import { cn } from "@/lib/utils";

export default function SurveysClient({ surveyId }: { surveyId?: string }) {
  const session = useProtectedSession();
  const router = useRouter();

  const isSessionReady = session.status === "ready";
  const {
    data: list = [],
    isLoading: isListLoading,
    error: listQueryError,
    refetch: refetchList,
  } = useSurveys(isSessionReady && !surveyId);

  const {
    data: form,
    isLoading: isDetailLoading,
    error: detailQueryError,
    refetch: refetchDetail,
  } = useSurveyDetail(surveyId, isSessionReady);

  const { mutate: submitSurvey, isPending: submitting } = useSubmitSurvey();

  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [multiAnswers, setMultiAnswers] = useState<Record<number, number[]>>({});
  const [filter, setFilter] = useState("all");
  const [actionError, setActionError] = useState("");
  const [result, setResult] = useState<SurveyResult | null>(null);

  function toggleMultiChoice(questionId: number, optionId: number) {
    setMultiAnswers((prev) => {
      const current = prev[questionId] || [];
      const exists = current.includes(optionId);
      const updated = exists
        ? current.filter((id) => id !== optionId)
        : [...current, optionId];
      return { ...prev, [questionId]: updated };
    });
  }

  const queryError = surveyId ? detailQueryError : listQueryError;
  const loaded = surveyId ? Boolean(form) : Boolean(list);
  const loading = surveyId ? isDetailLoading : isListLoading;

  useEffect(() => {
    if (queryError instanceof Error && queryError.message === "UNAUTHORIZED") {
      router.replace(
        `/login?next=${encodeURIComponent(surveyId ? "/surveys/" + surveyId : "/surveys")}`
      );
    }
  }, [queryError, surveyId, router]);

  // Gửi thông báo đẩy cho các khảo sát mới được giao
  useEffect(() => {
    if (session.status === "ready" && Array.isArray(list) && !surveyId) {
      list.forEach((item) => {
        if (!item.isCompleted && !item.isNotified && !item.isExpired) {
          publishNotification(session.user.userId, {
            id: `survey-assign:${item.surveyId}`,
            kind: "survey",
            title: `Khảo sát mới: ${item.title}`,
            message: item.rewardVoucherTitle
              ? `Làm khảo sát ngay để nhận phần thưởng: ${item.rewardVoucherTitle}!`
              : "Bạn có một bài khảo sát mới cần thực hiện.",
            href: `/surveys/${item.surveyId}`,
          });
          fetch(`/api/surveys/${item.surveyId}/mark-notified`, {
            method: "POST",
          }).catch(() => {});
        }
      });
    }
  }, [session, list, surveyId]);

  const error =
    actionError ||
    (queryError ? (queryError as Error).message || "Không thể tải khảo sát." : "");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form || submitting || result) return;
    const missing = form.questions.find((q) => {
      if (!q.isRequired) return false;
      if (q.questionType === "SINGLE_CHOICE") {
        return !answers[q.questionId]?.trim();
      }
      if (q.questionType === "MULTI_CHOICE") {
        return !multiAnswers[q.questionId] || multiAnswers[q.questionId].length === 0;
      }
      return !answers[q.questionId]?.trim();
    });
    if (missing) {
      setActionError(
        missing.questionType === "MULTI_CHOICE"
          ? `Vui lòng chọn ít nhất 1 đáp án cho: ${missing.questionText}`
          : `Vui lòng trả lời: ${missing.questionText}`
      );
      return;
    }
    setActionError("");

    submitSurvey(
      {
        surveyId: form.surveyId,
        answers: form.questions
          .map((q) => {
            if (q.questionType === "SINGLE_CHOICE") {
              const optId = answers[q.questionId]?.trim();
              return optId
                ? { questionId: q.questionId, selectedOptionId: Number(optId) }
                : null;
            }
            if (q.questionType === "MULTI_CHOICE") {
              const optIds = multiAnswers[q.questionId];
              return optIds && optIds.length > 0
                ? { questionId: q.questionId, selectedOptionIds: optIds }
                : null;
            }
            const text = answers[q.questionId]?.trim();
            return text
              ? { questionId: q.questionId, textAnswer: text }
              : null;
          })
          .filter(Boolean) as {
            questionId: number;
            selectedOptionId?: number;
            selectedOptionIds?: number[];
            textAnswer?: string;
          }[],
      },
      {
        onSuccess: (data) => {
          setResult(data);
          if (session.status === "ready") {
            publishNotification(session.user.userId, {
              id: `survey:${form.surveyId}`,
              kind: "survey",
              title: "Đã hoàn thành khảo sát",
              message: `Câu trả lời của bạn đã được ghi nhận.${data.rewardVoucher ? " Phần thưởng đã được hệ thống cấp; xem tại khảo sát." : ""}`,
              href: "/surveys",
            });
          }
        },
        onError: (err) => {
          if (err.message === "UNAUTHORIZED") {
            router.replace(
              `/login?next=${encodeURIComponent("/surveys/" + form.surveyId)}`
            );
            return;
          }
          setActionError(
            err.message || "Không thể nộp khảo sát. Vui lòng thử lại."
          );
        },
      }
    );
  }

  const visible = list.filter(
    (item) => filter === "all" || item.isCompleted === (filter === "completed"),
  );

  return (
    <main className="bg-surface min-h-[65vh] px-6 pt-12 pb-20 max-sm:px-4 max-sm:pt-8 max-sm:pb-14">
      <div className="max-w-5xl mx-auto">
        <Link
          href={surveyId ? "/surveys" : "/profile"}
          className="text-muted no-underline text-sm hover:text-brand transition-colors"
        >
          ← {surveyId ? "Khảo sát của tôi" : "Hồ sơ cá nhân"}
        </Link>
        <p className="text-brand font-bold text-xs tracking-widest mt-8 mb-4">
          TÀI KHOẢN TECHSTOREE
        </p>
        <h1 className="text-ink text-3xl sm:text-4xl lg:text-5xl tracking-tight leading-tight max-w-4xl mb-5 mt-0 font-bold">
          {surveyId
            ? form?.title || "Thực hiện khảo sát"
            : "Ý kiến của bạn. Trải nghiệm tốt hơn."}
        </h1>
        <p className="max-w-3xl text-neutral-600 leading-relaxed mb-8 text-sm sm:text-base">
          {surveyId
            ? form?.description
            : "Các khảo sát được giao riêng cho tài khoản của bạn. Phần thưởng (nếu có) sẽ được cấp tự động sau khi bạn nộp biểu mẫu."}
        </p>

        {error && (
          <div className="bg-rose-50 border border-rose-200 text-rose-800 rounded-xl p-5 mb-8 flex justify-between items-center" role="alert">
            <p className="m-0 text-sm font-medium">{error}</p>
            <button
              className="bg-white border border-rose-300 rounded-lg px-4 py-2 text-xs font-semibold cursor-pointer hover:bg-rose-100 transition-colors"
              onClick={() => {
                setActionError("");
                if (surveyId) void refetchDetail();
                else void refetchList();
              }}
            >
              Thử lại
            </button>
          </div>
        )}

        {loading ? (
          <div className="bg-white border border-border rounded-2xl p-12 text-center text-neutral-500 text-sm" role="status">
            Đang tải dữ liệu khảo sát…
          </div>
        ) : surveyId && form ? (
          <form
            className="bg-white border border-border rounded-2xl p-8 max-sm:p-5"
            onSubmit={submit}
          >
            {result ? (
              <div className="py-6 text-center" role="status">
                <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4 text-xl">
                  ✓
                </div>
                <h2 className="text-xl leading-snug tracking-tight m-0 mb-3.5 font-semibold text-ink">
                  Cảm ơn bạn đã chia sẻ.
                </h2>
                <p className="text-neutral-600 leading-relaxed text-sm">{result.message}</p>
                {result.rewardVoucher && (
                  <div className="bg-red-50 text-red-900 rounded-xl p-5 my-5 border border-red-200 text-left max-w-md mx-auto">
                    <strong className="block text-base font-bold mb-1">🎁 {result.rewardVoucher.title}</strong>
                    <p className="text-sm m-0">
                      Mã ưu đãi: <code className="bg-white px-2 py-0.5 rounded border border-red-200 font-mono font-bold text-brand">{result.rewardVoucher.code}</code>
                    </p>
                    <p className="text-xs text-neutral-600 mt-2 mb-0">
                      Hạn sử dụng: {new Date(result.rewardVoucher.endDate).toLocaleDateString("vi-VN")}
                    </p>
                  </div>
                )}
                <div className="mt-6">
                  <Link
                    className="inline-block no-underline border-0 rounded-lg bg-ink text-white px-6 py-3 font-semibold cursor-pointer transition-opacity hover:opacity-90"
                    href="/surveys"
                  >
                    Về danh sách khảo sát
                  </Link>
                </div>
              </div>
            ) : (
              <>
                {form.rewardVoucherTitle && (
                  <div className="bg-red-50 border border-red-100 text-red-900 rounded-xl p-4 mb-6 text-sm">
                    <strong>Phần thưởng khi hoàn thành:</strong>{" "}
                    {form.rewardVoucherTitle}
                  </div>
                )}
                <div className="flex flex-col gap-8">
                  {form.questions
                    .sort((a, b) => a.orderNum - b.orderNum)
                    .map((q) => (
                      <fieldset
                        key={q.questionId}
                        className="border-0 p-0 m-0 flex flex-col gap-3"
                      >
                        <legend className="text-base font-semibold text-ink mb-1">
                          {q.questionText}{" "}
                          {q.isRequired && (
                            <span className="text-brand">*</span>
                          )}
                        </legend>
                        {q.questionType === "SINGLE_CHOICE" ? (
                          q.options
                            .sort((a, b) => a.orderNum - b.orderNum)
                            .map((option) => (
                              <label
                                key={option.optionId}
                                className={cn(
                                  "flex items-center gap-3 p-3.5 border rounded-xl cursor-pointer text-sm font-medium transition-colors",
                                  answers[q.questionId] ===
                                    String(option.optionId)
                                    ? "bg-red-50/50 border-brand text-brand"
                                    : "border-border hover:bg-neutral-50 text-neutral-800"
                                )}
                              >
                                <input
                                  type="radio"
                                  name={`q_${q.questionId}`}
                                  value={option.optionId}
                                  className="accent-brand w-4 h-4"
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
                        ) : q.questionType === "MULTI_CHOICE" ? (
                          q.options
                            .sort((a, b) => a.orderNum - b.orderNum)
                            .map((option) => {
                              const checked = (multiAnswers[q.questionId] || []).includes(option.optionId);
                              return (
                                <label
                                  key={option.optionId}
                                  className={cn(
                                    "flex items-center gap-3 p-3.5 border rounded-xl cursor-pointer text-sm font-medium transition-colors",
                                    checked
                                      ? "bg-red-50/50 border-brand text-brand"
                                      : "border-border hover:bg-neutral-50 text-neutral-800"
                                  )}
                                >
                                  <input
                                    type="checkbox"
                                    name={`q_${q.questionId}`}
                                    className="accent-brand w-4 h-4"
                                    checked={checked}
                                    onChange={() =>
                                      toggleMultiChoice(
                                        q.questionId,
                                        option.optionId
                                      )
                                    }
                                  />
                                  {option.optionText}
                                </label>
                              );
                            })
                        ) : (
                          <textarea
                            aria-label={q.questionText}
                            required={q.isRequired}
                            maxLength={5000}
                            rows={4}
                            className="border border-border rounded-xl p-3.5 text-sm w-full outline-none focus:border-brand focus:ring-1 focus:ring-brand"
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
                <div className="flex gap-5 justify-between items-center my-7 max-sm:flex-col max-sm:items-stretch">
                  <p className="text-sm text-neutral-600 leading-relaxed max-w-lg">
                    Câu có dấu * là bắt buộc. Sau khi nộp, bạn không thể sửa câu
                    trả lời.
                  </p>
                  <button
                    className="inline-block no-underline border-0 rounded-lg bg-ink text-white px-6 py-3.5 font-semibold cursor-pointer shrink-0 transition-opacity hover:opacity-90 disabled:opacity-50 disabled:cursor-wait"
                    disabled={submitting}
                  >
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
              <div className="flex flex-wrap gap-2.5 my-8" aria-label="Lọc khảo sát">
                {[
                  ["all", "Tất cả"],
                  ["pending", "Chưa thực hiện"],
                  ["completed", "Đã hoàn thành"],
                ].map(([key, label]) => (
                  <button
                    key={key}
                    aria-pressed={filter === key}
                    onClick={() => setFilter(key)}
                    className={cn(
                      "border rounded-full px-5 py-2.5 cursor-pointer text-sm transition-colors",
                      filter === key
                        ? "bg-ink text-white border-ink font-semibold"
                        : "border-border bg-white text-neutral-700 hover:border-neutral-400"
                    )}
                  >
                    {label}
                  </button>
                ))}
              </div>
              {visible.length === 0 ? (
                <section className="bg-white border border-border rounded-2xl p-7 max-sm:p-5 min-w-0 m-0">
                  <h2 className="text-xl leading-snug tracking-tight m-0 mb-2 font-semibold text-ink">
                    Chưa có khảo sát trong mục này.
                  </h2>
                  <p className="text-neutral-600 text-sm">Khi được phân công khảo sát mới, bạn sẽ thấy tại đây.</p>
                </section>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  {visible.map((item) => (
                    <article className="bg-white border border-border rounded-2xl p-7 max-sm:p-5 min-w-0 m-0 flex flex-col justify-between" key={item.surveyId}>
                      <div>
                        <p className="text-brand font-bold text-xs tracking-widest mt-0 mb-3">
                          {item.isCompleted ? "ĐÃ HOÀN THÀNH" : "CHƯA THỰC HIỆN"}
                        </p>
                        <h2 className="text-xl leading-snug tracking-tight m-0 mb-3 font-semibold text-ink">
                          {item.title}
                        </h2>
                        <p className="text-neutral-600 leading-relaxed text-sm mb-4">{item.description}</p>
                        {item.rewardVoucherTitle && (
                          <p className="bg-red-50 text-red-900 rounded-lg p-3.5 my-3 leading-relaxed text-sm border border-red-100 font-medium">
                            {item.isCompleted
                              ? "Phần thưởng của khảo sát"
                              : "Phần thưởng dự kiến"}
                            : {item.rewardVoucherTitle}
                          </p>
                        )}
                      </div>
                      <div className="mt-4 pt-3 border-t border-neutral-100">
                        {item.isCompleted ? (
                          <p className="text-xs text-neutral-500 font-medium">
                            Đã nộp{" "}
                            {item.completedAt &&
                              new Date(item.completedAt).toLocaleDateString(
                                "vi-VN",
                              )}
                          </p>
                        ) : item.isExpired ? (
                          <p className="text-sm text-red-600 font-semibold m-0">
                            Đã hết hạn làm bài
                          </p>
                        ) : (
                          <>
                            {item.expiredAt && (
                              <p className="text-xs text-amber-600 font-medium mb-3">
                                Hạn chót: {new Date(item.expiredAt).toLocaleDateString("vi-VN")}{" "}
                                {new Date(item.expiredAt).toLocaleTimeString("vi-VN", {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                })}
                              </p>
                            )}
                            <Link
                              className="inline-block no-underline border-0 rounded-lg bg-ink text-white px-5 py-2.5 text-sm font-semibold cursor-pointer transition-opacity hover:opacity-90"
                              href={`/surveys/${item.surveyId}`}
                            >
                              Bắt đầu khảo sát ↗
                            </Link>
                          </>
                        )}
                      </div>
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
