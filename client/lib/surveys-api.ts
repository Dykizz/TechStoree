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
