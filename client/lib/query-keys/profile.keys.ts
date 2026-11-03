export const profileKeys = {
  all: ["profile"] as const,
  detail: () => [...profileKeys.all, "detail"] as const,
};

export const techInterestKeys = {
  all: ["tech-interests"] as const,
};

