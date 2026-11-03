"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { useProtectedSession } from "@/lib/use-protected-session";
import { publishNotification } from "@/lib/customer-notifications";
import type { ProfileData } from "@/lib/auth-server";
import { useProfile } from "@/hooks/queries/useProfile";
import { useTechInterests } from "@/hooks/queries/useTechInterests";
import { useUpdateProfile } from "@/hooks/mutations/useUpdateProfile";
import ProfileOverview from "@/components/profile/ProfileOverview";
import ProfileForm, { type FormValues } from "@/components/profile/ProfileForm";

const previewProfile: ProfileData = {
  userId: 0,
  username: "khach_hang_mau",
  fullName: "Nguyễn Minh Anh",
  email: "minhanh@example.com",
  role: "USER",
  phone: "090 123 4567",
  dateOfBirth: "1998-05-18T00:00:00Z",
  techInterest: "AUDIO_STUDIO",
  address: "Quận 1, TP. Hồ Chí Minh",
};

function toForm(profile: ProfileData): FormValues {
  return {
    fullName: profile.fullName || "",
    phone: profile.phone || "",
    dateOfBirth: profile.dateOfBirth?.slice(0, 10) || "",
    techInterest: profile.techInterest || "",
    address: profile.address || "",
  };
}

export default function ProfileClient({
  preview = false,
}: {
  preview?: boolean;
}) {
  const router = useRouter();
  const session = useProtectedSession(!preview);

  // TanStack Query hooks
  const { data: interests = [] } = useTechInterests();
  const isEnabled = !preview && session.status === "ready";
  const {
    data: serverProfile,
    error: queryError,
    refetch,
  } = useProfile(isEnabled);

  const [previewData, setPreviewData] = useState<ProfileData>(previewProfile);
  const profile = preview ? previewData : (serverProfile ?? null);

  const [form, setForm] = useState<FormValues | null>(
    preview ? toForm(previewProfile) : null
  );

  // Đồng bộ form khi nạp được profile từ server
  const [syncedProfile, setSyncedProfile] = useState<ProfileData | null>(null);
  if (profile && profile !== syncedProfile && !preview) {
    setSyncedProfile(profile);
    setForm(toForm(profile));
  }

  const [editing, setEditing] = useState(false);
  const [saveError, setSaveError] = useState("");
  const [notice, setNotice] = useState("");

  const { mutate: updateProfile, isPending: saving } = useUpdateProfile();

  const nameInput = useRef<HTMLInputElement>(null);
  const editButton = useRef<HTMLButtonElement>(null);
  const wasEditing = useRef(false);

  useEffect(() => {
    if (editing) nameInput.current?.focus();
    else if (wasEditing.current) editButton.current?.focus();
    wasEditing.current = editing;
  }, [editing]);

  useEffect(() => {
    if (queryError instanceof Error && queryError.message === "UNAUTHORIZED") {
      router.replace("/login?next=%2Fprofile");
    }
  }, [queryError, router]);

  function changeField(field: keyof FormValues, value: string) {
    if (!editing || saving) return;
    setForm((current) => (current ? { ...current, [field]: value } : current));
    setSaveError("");
    setNotice("");
  }

  function beginEditing() {
    if (!profile || saving) return;
    setForm(toForm(profile));
    setSaveError("");
    setNotice("");
    setEditing(true);
  }

  function cancelEditing() {
    if (saving || !profile) return;
    setForm(toForm(profile));
    setSaveError("");
    setNotice("");
    setEditing(false);
  }

  async function handleSave(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!form || saving) return;
    setSaveError("");
    setNotice("");

    if (preview) {
      setPreviewData((current) => ({
        ...current,
        ...form,
        userId: current.userId,
      }));
      setEditing(false);
      setNotice("Bản xem trước: thông tin đã được cập nhật.");
      return;
    }

    updateProfile(form, {
      onSuccess: (updated) => {
        setForm(toForm(updated));
        setEditing(false);
        setNotice("Đã lưu thông tin cá nhân.");
        publishNotification(updated.userId, {
          id: `profile:${crypto.randomUUID()}`,
          kind: "profile",
          title: "Hồ sơ đã được cập nhật",
          message: "Thông tin cá nhân của bạn đã được lưu thành công.",
          href: "/profile",
        });
      },
      onError: (err) => {
        setSaveError(
          err.message || "Không thể kết nối đến máy chủ. Vui lòng thử lại."
        );
      },
    });
  }

  const loadingError = queryError ? queryError.message : "";
  const error = preview
    ? ""
    : session.status === "error"
      ? session.message
      : loadingError;

  return (
    <main className="min-h-[calc(100vh-68px)] bg-[#f7f7f6] text-[#1d1d1f]">
      {preview && (
        <Link className="border-0 bg-transparent text-[#3c3c43] text-[13px] font-[650] no-underline cursor-pointer hover:text-brand disabled:opacity-50 disabled:cursor-default" href="/profile">
          Xem trang thật
        </Link>
      )}

      <div className="max-w-[1280px] mx-auto pt-[clamp(42px,6vw,88px)] px-[clamp(24px,5vw,72px)] pb-[100px] max-[540px]:pt-11 max-[540px]:pb-[60px]">
        <div className="mb-[45px] max-[540px]:mb-7">
          <p className="text-brand text-[11px] font-extrabold tracking-[0.18em]">
            KHÔNG GIAN CỦA BẠN
          </p>
          <h1 className="my-3.5 mb-4 text-[clamp(39px,5vw,66px)] leading-[1.04] tracking-[-0.055em] font-[680]">
            Hồ sơ cá nhân<span className="text-brand">.</span>
          </h1>
          <p className="text-[#6e6e75] text-base leading-relaxed max-[540px]:text-sm">
            Quản lý thông tin của bạn trong một nơi đơn giản và an toàn.
          </p>
        </div>

        {preview && (
          <div className="-mt-2.5 mb-[26px] p-[15px_19px] border border-[#ead5d7] rounded-[11px] bg-[#fff3f4] text-[#853641] text-[13px] leading-normal" role="status">
            BẢN XEM TRƯỚC · Thông tin bên dưới là dữ liệu mẫu. Bạn có thể thử chỉnh sửa giao diện; không có thay đổi nào được gửi tới backend.
          </div>
        )}

        {!preview &&
        (session.status === "checking" ||
          (session.status === "ready" && !profile && !error)) ? (
          <div className="bg-white border border-[#e9e9eb] rounded-[20px] shadow-[0_16px_50px_rgba(22,23,30,0.035)] p-11 text-[#777780] text-[15px]" role="status">
            Đang xác minh và tải hồ sơ của bạn…
          </div>
        ) : error ? (
          <div className="bg-white border border-[#e9e9eb] rounded-[20px] shadow-[0_16px_50px_rgba(22,23,30,0.035)] p-11 text-[#777780] text-[15px]" role="alert">
            <h2 className="text-[#1d1d1f] text-[23px] font-bold">Chưa thể mở hồ sơ</h2>
            <p className="my-3 mb-6 leading-normal">{error}</p>
            <button
              className="min-h-[47px] px-[22px] rounded-[9px] text-[13px] font-bold cursor-pointer transition-[background,transform] duration-200 border border-[#1d1d1f] bg-[#1d1d1f] text-white hover:bg-brand hover:border-brand focus-visible:outline focus-visible:outline-3 focus-visible:outline-brand/35 focus-visible:outline-offset-3"
              type="button"
              onClick={() => {
                if (session.status === "error") session.retry();
                else void refetch();
              }}
            >
              Thử lại
            </button>
          </div>
        ) : profile && form ? (
          <div className="grid grid-cols-[minmax(240px,290px)_minmax(0,1fr)] gap-7 items-start max-[780px]:grid-cols-1">
            <ProfileOverview profile={profile} preview={preview} />
            <ProfileForm
              profile={profile}
              form={form}
              editing={editing}
              saving={saving}
              saveError={saveError}
              notice={notice}
              preview={preview}
              interests={interests}
              nameInputRef={nameInput}
              editButtonRef={editButton}
              onChangeField={changeField}
              onBeginEditing={beginEditing}
              onCancelEditing={cancelEditing}
              onSubmit={(e) => void handleSave(e)}
            />
          </div>
        ) : null}
      </div>
    </main>
  );
}
