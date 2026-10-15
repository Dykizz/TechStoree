"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import type { SessionUser } from "./auth-server";

type GuardState =
  | { status: "checking"; user: null; message: "" }
  | { status: "ready"; user: SessionUser; message: "" }
  | { status: "error"; user: null; message: string };

export function useProtectedSession(enabled = true) {
  const router = useRouter();
  const [attempt, setAttempt] = useState(0);
  const [state, setState] = useState<GuardState>({
    status: "checking",
    user: null,
    message: "",
  });

  useEffect(() => {
    if (!enabled) return;
    const controller = new AbortController();
    async function verify() {
      try {
        const response = await fetch("/api/auth/session", {
          cache: "no-store",
          signal: controller.signal,
        });
        if (response.status === 401) {
          router.replace(
            `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`,
          );
          return;
        }
        const result = (await response.json()) as {
          user?: SessionUser;
          message?: string;
        };
        if (!controller.signal.aborted) {
          setState(
            response.ok && result.user
              ? { status: "ready", user: result.user, message: "" }
              : {
                  status: "error",
                  user: null,
                  message:
                    result.message ||
                    "Không thể kiểm tra phiên. Vui lòng thử lại.",
                },
          );
        }
      } catch {
        if (!controller.signal.aborted) {
          setState({
            status: "error",
            user: null,
            message: "Không thể kết nối đến máy chủ. Vui lòng thử lại.",
          });
        }
      }
    }
    void verify();
    return () => controller.abort();
  }, [attempt, enabled, router]);

  const retry = useCallback(() => {
    setState({ status: "checking", user: null, message: "" });
    setAttempt((value) => value + 1);
  }, []);

  return { ...state, retry };
}
