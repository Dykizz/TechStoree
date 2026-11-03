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
  const [filter, setFilter] = useState("all");
  const [actionError, setActionError] = useState("");
  const [result, setResult] = useState<SurveyResult | null>(null);

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

  const error =
    actionError ||
    (queryError ? (queryError as Error).message || "Không thể tải khảo sát." : "");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form || submitting || result) return;
    const missing = form.questions.find(
      (q) => q.isRequired && !answers[q.questionId]?.trim()
    );
    if (missing) {
      setActionError(`Vui lòng trả lời: ${missing.questionText}`);
      return;
    }
    setActionError("");

    submitSurvey(
      {
        surveyId: form.surveyId,
        answers: form.questions
          .filter((q) => answers[q.questionId]?.trim())
          .map((q) => ({
            questionId: q.questionId,
            ...(q.questionType === "SINGLE_CHOICE"
              ? { selectedOptionId: Number(answers[q.questionId]) }
              : { textAnswer: answers[q.questionId].trim() }),
          })),
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
            : "Các khảo sát được giao riêng cho tài khoản của bạn. Phần thưởng, nếu có, được xác nhận bởi hệ thống sau khi nộp."}
        </p>

        {session.status === "error" ? (
          <div className="border border-red-200 bg-red-50 text-red-900 rounded-xl p-5 leading-relaxed my-6 text-sm" role="alert">
            {session.message}
            <button
              onClick={session.retry}
              className="block mt-3 bg-white border border-red-200 px-4.5 py-2.5 rounded-lg cursor-pointer hover:bg-red-50 transition-colors"
            >
              Thử lại
            </button>
          </div>
        ) : session.status === "checking" || loading || (!loaded && !error) ? (
          <p role="status" className="text-neutral-500 text-sm">Đang tải khảo sát…</p>
        ) : null}

        {error && (
          <div className="border border-red-200 bg-red-50 text-red-900 rounded-xl p-5 leading-relaxed my-6 text-sm" role="alert">
            {error}
            {!form && (
              <button
                onClick={() => {
                  setActionError("");
                  if (surveyId) void refetchDetail();
                  else void refetchList();
                }}
                className="block mt-3 bg-white border border-red-200 px-4.5 py-2.5 rounded-lg cursor-pointer hover:bg-red-50 transition-colors"
              >
                Thử lại
              </button>
            )}
          </div>
        )}

        {result ? (
          <section className="bg-white border border-border rounded-2xl p-7 max-sm:p-5 min-w-0 m-0" role="status">
            <p className="text-brand font-bold text-xs tracking-widest mt-0 mb-4">ĐÃ HOÀN THÀNH</p>
            <h2 className="text-xl leading-snug tracking-tight m-0 mb-3.5 font-semibold text-ink">
              Cảm ơn bạn đã chia sẻ.
            </h2>
            <p className="text-neutral-600 leading-relaxed text-sm">{result.message}</p>
            {result.rewardVoucher && (
              <div className="bg-red-50 text-red-900 rounded-lg p-4 my-5 leading-relaxed text-sm border border-red-100">
                <strong>{result.rewardVoucher.title}</strong>
                <p className="mt-1">
                  Mã ưu đãi: <code className="bg-white px-2 py-0.5 rounded border border-red-200 font-mono text-xs">{result.rewardVoucher.code}</code>
                </p>
                <p className="mt-1 text-xs text-red-700">
                  Điều kiện sử dụng được kiểm tra khi áp dụng mã tại giỏ hàng.
                </p>
              </div>
            )}
            <Link
              className="inline-block no-underline border-0 rounded-lg bg-ink text-white px-6 py-3.5 font-semibold cursor-pointer mt-3.5 transition-opacity hover:opacity-90"
              href="/surveys"
            >
              Về danh sách khảo sát
            </Link>
          </section>
        ) : surveyId && form ? (
          <form onSubmit={(event) => void submit(event)}>
            {form.rewardVoucherTitle && (
              <p className="bg-red-50 text-red-900 rounded-lg p-4 my-5 leading-relaxed text-sm border border-red-100 font-medium">
                Phần thưởng dự kiến: {form.rewardVoucherTitle}
              </p>
            )}
            {form.questions.length === 0 ? (
              <p className="text-neutral-500 text-sm">Khảo sát chưa có câu hỏi. Vui lòng quay lại sau.</p>
            ) : (
              <>
                <div className="grid gap-5">
                  {[...form.questions]
                    .sort((a, b) => a.orderNum - b.orderNum)
                    .map((q, index) => (
                      <fieldset
                        className="bg-white border border-border rounded-2xl p-7 max-sm:p-5 min-w-0 m-0"
                        key={q.questionId}
                        disabled={submitting}
                      >
                        <legend className="font-semibold max-w-full leading-relaxed px-2.5 text-base text-ink">
                          {index + 1}. {q.questionText}{" "}
                          {q.isRequired && <span className="text-brand" title="Bắt buộc">*</span>}
                        </legend>
                        {q.questionType === "SINGLE_CHOICE" ? (
                          [...q.options]
                            .sort((a, b) => a.orderNum - b.orderNum)
                            .map((option) => (
                              <label
                                className="flex gap-3 items-start p-3.5 border border-border rounded-lg my-3 leading-normal cursor-pointer text-sm hover:bg-neutral-50 transition-colors"
                                key={option.optionId}
                              >
                                <input
                                  type="radio"
                                  className="accent-brand mt-1 shrink-0"
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
                                <span className="text-neutral-800">{option.optionText}</span>
                              </label>
                            ))
                        ) : (
                          <textarea
                            className="w-full resize-y p-3.5 border border-border rounded-lg leading-relaxed text-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand mt-3"
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
                        ) : (
                          <Link
                            className="inline-block no-underline border-0 rounded-lg bg-ink text-white px-5 py-2.5 text-sm font-semibold cursor-pointer transition-opacity hover:opacity-90"
                            href={`/surveys/${item.surveyId}`}
                          >
                            Bắt đầu khảo sát ↗
                          </Link>
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
