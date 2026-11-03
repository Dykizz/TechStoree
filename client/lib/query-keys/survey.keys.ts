export const surveyKeys = {
  all: ["surveys"] as const,
  lists: () => [...surveyKeys.all, "list"] as const,
  details: () => [...surveyKeys.all, "detail"] as const,
  detail: (id: string | number) => [...surveyKeys.details(), String(id)] as const,
};

