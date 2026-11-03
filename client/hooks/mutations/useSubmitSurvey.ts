import { useMutation, useQueryClient } from "@tanstack/react-query";
import { surveyKeys } from "@/lib/query-keys/survey.keys";
import { submitSurveyApi, type SurveyResult } from "@/lib/surveys-api";

export type SubmitSurveyParams = {
  surveyId: number;
  answers: {
    questionId: number;
    selectedOptionId?: number;
    textAnswer?: string;
  }[];
};

export function useSubmitSurvey() {
  const queryClient = useQueryClient();

  return useMutation<SurveyResult, Error, SubmitSurveyParams>({
    mutationFn: ({ surveyId, answers }) => submitSurveyApi(surveyId, answers),
    onSuccess: (_, { surveyId }) => {
      void queryClient.invalidateQueries({ queryKey: surveyKeys.all });
      void queryClient.invalidateQueries({ queryKey: surveyKeys.detail(surveyId) });
    },
  });
}

