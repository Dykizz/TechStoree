import { useQuery } from "@tanstack/react-query";
import { surveyKeys } from "@/lib/query-keys/survey.keys";
import { fetchSurveyByIdApi } from "@/lib/surveys-api";

export function useSurveyDetail(surveyId: string | undefined, enabled = true) {
  return useQuery({
    queryKey: surveyKeys.detail(surveyId || ""),
    queryFn: () => fetchSurveyByIdApi(surveyId || ""),
    enabled: enabled && Boolean(surveyId),
    staleTime: 5 * 60 * 1000,
  });
}

