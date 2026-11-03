export type CustomerSurvey = {
  surveyId: number;
  title: string;
  description: string | null;
  rewardVoucherTitle: string | null;
  isCompleted: boolean;
  completedAt: string | null;
  expiredAt?: string | null;
  isExpired?: boolean;
  isNotified?: boolean;
};

export type SurveyQuestion = {
  questionId: number;
  questionText: string;
  questionType: "SINGLE_CHOICE" | "MULTI_CHOICE" | "TEXT";
  isRequired: boolean;
  orderNum: number;
  options: { optionId: number; optionText: string; orderNum: number }[];
};

export type SurveyForm = {
  surveyId: number;
  title: string;
  description: string | null;
  rewardVoucherTitle: string | null;
  questions: SurveyQuestion[];
};

export type SurveyResult = {
  success: boolean;
  message: string;
  completedAt: string;
  rewardVoucher: {
    code: string;
    title: string;
    discountType: string;
    discountValue: number;
    minOrderValue: number;
    endDate: string;
  } | null;
};

export async function fetchSurveysApi(): Promise<CustomerSurvey[]> {
  const response = await fetch("/api/surveys", { cache: "no-store" });
  if (response.status === 401) throw new Error("UNAUTHORIZED");
  const body = await response.json();
  if (!response.ok || !body.success || !Array.isArray(body.data)) {
    throw new Error(body.message || "Không thể tải danh sách khảo sát.");
  }
  return body.data;
}

export async function fetchSurveyByIdApi(
  surveyId: string
): Promise<SurveyForm> {
  const response = await fetch(
    `/api/surveys/${encodeURIComponent(surveyId)}`,
    { cache: "no-store" }
  );
  if (response.status === 401) throw new Error("UNAUTHORIZED");
  const body = await response.json();
  if (
    !response.ok ||
    !body.success ||
    !body.data ||
    !Array.isArray(body.data.questions)
  ) {
    throw new Error(body.message || "Không thể tải biểu mẫu khảo sát.");
  }
  return body.data;
}

export async function submitSurveyApi(
  surveyId: number,
  answers: {
    questionId: number;
    selectedOptionId?: number;
    selectedOptionIds?: number[];
    textAnswer?: string;
  }[]
): Promise<SurveyResult> {
  const response = await fetch(`/api/surveys/${surveyId}/submit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ answers }),
  });
  const body = await response.json();
  if (!response.ok || !body.success) {
    throw new Error(body.message || "Gửi khảo sát không thành công.");
  }
  return body;
}
