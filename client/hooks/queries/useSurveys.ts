import { useQuery } from "@tanstack/react-query";
import { surveyKeys } from "@/lib/query-keys/survey.keys";
import { fetchSurveysApi } from "@/lib/surveys-api";

export function useSurveys(enabled = true) {
  return useQuery({
    queryKey: surveyKeys.lists(),
    queryFn: fetchSurveysApi,
    enabled,
    staleTime: 3 * 60 * 1000,
  });
}

