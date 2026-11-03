"use client";

import type { RefObject, FormEvent, KeyboardEvent } from "react";
import type { ProfileData } from "@/lib/auth-server";

export type FormValues = {
  fullName: string;
  phone: string;
  dateOfBirth: string;
  techInterest: string;
  address: string;
};

interface ProfileFormProps {
  profile: ProfileData;
  form: FormValues;
  editing: boolean;
  saving: boolean;
  saveError: string;
  notice: string;
  preview: boolean;
  interests: { key: string; displayName: string }[];
  nameInputRef: RefObject<HTMLInputElement | null>;
  editButtonRef: RefObject<HTMLButtonElement | null>;
  onChangeField: (field: keyof FormValues, value: string) => void;
  onBeginEditing: () => void;
  onCancelEditing: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
}

export default function ProfileForm({
  profile,
  form,
  editing,
  saving,
  saveError,
  notice,
  preview,
  interests,
  nameInputRef,
  editButtonRef,
  onChangeField,
  onBeginEditing,
  onCancelEditing,
  onSubmit,
}: ProfileFormProps) {
  const handleFormKeyDown = (event: KeyboardEvent<HTMLFormElement>) => {
    if (event.key === "Enter") {
      const target = event.target as HTMLElement;
      if (target.tagName.toLowerCase() === "textarea") {
        return;
      }
      event.preventDefault();
    }
  };

  return (
    <section
      className="bg-white border border-[#e9e9eb] rounded-[20px] shadow-[0_16px_50px_rgba(22,23,30,0.035)] p-[clamp(26px,4vw,46px)]"
      aria-labelledby="profile-heading"
    >
      <div className="flex items-start justify-between gap-5 pb-[30px] border-b border-[#ececef]">
        <div>
          <p className="text-brand text-[11px] font-extrabold tracking-[0.18em]">
            THÔNG TIN CÁ NHÂN
          </p>
          <h2 id="profile-heading" className="mt-2 text-[28px] tracking-[-0.04em] font-bold text-[#1d1d1f] max-[540px]:text-[23px]">
            Chi tiết hồ sơ
          </h2>
        </div>
        <span className="border border-[#ececef] rounded-full py-[7px] px-3 text-[#7a7a82] text-[11px] whitespace-nowrap">
          {preview ? "Dữ liệu mẫu" : "Riêng tư"}
        </span>
      </div>
      <form
        onSubmit={onSubmit}
        onKeyDown={handleFormKeyDown}
        aria-describedby="profile-edit-hint"
        aria-busy={saving}
      >
        <p id="profile-edit-hint" className="mt-[22px] text-[#6e6e75] text-[13px] leading-relaxed" role="status">
          {editing
            ? "Bạn đang chỉnh sửa hồ sơ. Thông tin chỉ được cập nhật khi bạn lưu thay đổi."
            : "Thông tin đang ở chế độ chỉ xem. Chọn Chỉnh sửa để cập nhật hồ sơ."}
        </p>
        <fieldset
          id="profile-fields"
          className="grid grid-cols-2 gap-6 gap-x-5 min-w-0 m-0 pt-6 border-0 max-[540px]:grid-cols-1 max-[540px]:gap-5"
          disabled={saving}
          aria-label="Thông tin cá nhân"
        >
          <div className="min-w-0">
            <label htmlFor="profile-name" className="block mb-2 text-[10px] font-extrabold tracking-[0.12em] text-[#1d1d1f]">
              HỌ VÀ TÊN <span className="text-brand">*</span>
            </label>
            <input
              ref={nameInputRef}
              id="profile-name"
              autoComplete="name"
              value={form.fullName}
              readOnly={!editing}
              onChange={(event) => onChangeField("fullName", event.target.value)}
              maxLength={100}
              className="block w-full min-w-0 h-[52px] px-[15px] border border-[#dedee3] rounded-[10px] bg-white text-[#1d1d1f] text-sm outline-none transition-[border-color,box-shadow,background-color] duration-200 hover:border-[#b9b9c1] focus:border-brand focus:ring-3 focus:ring-brand/12 placeholder:text-[#aaaab1] read-only:border-[#e6e6e9] read-only:bg-[#f5f5f6] read-only:text-[#4f4f57] read-only:focus:border-[#b9b9c1] read-only:focus:ring-3 read-only:focus:ring-[#1d1d1f]/[0.04] disabled:opacity-70 disabled:cursor-wait"
              required
            />
          </div>
          <div className="min-w-0">
            <label htmlFor="profile-phone" className="block mb-2 text-[10px] font-extrabold tracking-[0.12em] text-[#1d1d1f]">
              SỐ ĐIỆN THOẠI
            </label>
            <input
              id="profile-phone"
              type="tel"
              autoComplete="tel"
              value={form.phone}
              readOnly={!editing}
              onChange={(event) => onChangeField("phone", event.target.value)}
              maxLength={15}
              placeholder="Chưa cập nhật"
              className="block w-full min-w-0 h-[52px] px-[15px] border border-[#dedee3] rounded-[10px] bg-white text-[#1d1d1f] text-sm outline-none transition-[border-color,box-shadow,background-color] duration-200 hover:border-[#b9b9c1] focus:border-brand focus:ring-3 focus:ring-brand/12 placeholder:text-[#aaaab1] read-only:border-[#e6e6e9] read-only:bg-[#f5f5f6] read-only:text-[#4f4f57] read-only:focus:border-[#b9b9c1] read-only:focus:ring-3 read-only:focus:ring-[#1d1d1f]/[0.04] disabled:opacity-70 disabled:cursor-wait"
            />
          </div>
          <div className="min-w-0">
            <label htmlFor="profile-birth" className="block mb-2 text-[10px] font-extrabold tracking-[0.12em] text-[#1d1d1f]">
              NGÀY SINH
            </label>
            <input
              id="profile-birth"
              type="date"
              value={form.dateOfBirth}
              readOnly={!editing}
              max={new Date().toISOString().slice(0, 10)}
              onChange={(event) => onChangeField("dateOfBirth", event.target.value)}
              className="block w-full min-w-0 h-[52px] px-[15px] border border-[#dedee3] rounded-[10px] bg-white text-[#1d1d1f] text-sm outline-none transition-[border-color,box-shadow,background-color] duration-200 hover:border-[#b9b9c1] focus:border-brand focus:ring-3 focus:ring-brand/12 placeholder:text-[#aaaab1] read-only:border-[#e6e6e9] read-only:bg-[#f5f5f6] read-only:text-[#4f4f57] read-only:focus:border-[#b9b9c1] read-only:focus:ring-3 read-only:focus:ring-[#1d1d1f]/[0.04] disabled:opacity-70 disabled:cursor-wait"
            />
          </div>
          <div className="min-w-0">
            <label htmlFor="profile-interest" className="block mb-2 text-[10px] font-extrabold tracking-[0.12em] text-[#1d1d1f]">
              SỞ THÍCH CÔNG NGHỆ
            </label>
            <select
              id="profile-interest"
              value={form.techInterest}
              disabled={!editing || saving || interests.length === 0}
              onChange={(event) => onChangeField("techInterest", event.target.value)}
              className="w-full min-w-0 h-[52px] border border-[#dedee3] rounded-[10px] px-[15px] bg-white text-[#1d1d1f] text-sm outline-none hover:border-[#b9b9c1] focus:border-brand focus:ring-3 focus:ring-brand/12 disabled:opacity-100 disabled:bg-[#f5f5f6] disabled:text-[#4f4f57] disabled:border-[#e6e6e9]"
            >
              <option value="">Chưa cập nhật</option>
              {form.techInterest &&
                !interests.some((i) => i.key === form.techInterest) && (
                  <option value={form.techInterest}>{form.techInterest}</option>
                )}
              {interests.map((interest) => (
                <option key={interest.key} value={interest.key}>
                  {interest.displayName}
                </option>
              ))}
            </select>
          </div>
          <div className="min-w-0 col-span-full max-[540px]:col-auto">
            <label htmlFor="profile-address" className="block mb-2 text-[10px] font-extrabold tracking-[0.12em] text-[#1d1d1f]">
              ĐỊA CHỈ
            </label>
            <textarea
              id="profile-address"
              autoComplete="street-address"
              value={form.address}
              readOnly={!editing}
              onChange={(event) => onChangeField("address", event.target.value)}
              maxLength={255}
              rows={3}
              placeholder="Chưa cập nhật"
              className="block w-full min-w-0 min-h-[84px] p-[12px_15px] border border-[#dedee3] rounded-[10px] bg-white text-[#1d1d1f] font-inherit text-sm leading-normal outline-none resize-y transition-[border-color,box-shadow,background-color] duration-200 hover:border-[#b9b9c1] focus:border-brand focus:ring-3 focus:ring-brand/12 placeholder:text-[#aaaab1] read-only:border-[#e6e6e9] read-only:bg-[#f5f5f6] read-only:text-[#4f4f57] read-only:resize-none read-only:focus:border-[#b9b9c1] read-only:focus:ring-3 read-only:focus:ring-[#1d1d1f]/[0.04] disabled:opacity-70 disabled:cursor-wait"
            />
          </div>
        </fieldset>
        <div className="mt-[38px] p-[25px_27px_22px] border border-[#ececef] rounded-[13px] bg-[#fafafa] max-[540px]:p-5">
          <p className="text-brand text-[11px] font-extrabold tracking-[0.18em] mb-3.5 text-[#6e6e75]">
            THÔNG TIN ĐĂNG NHẬP
          </p>
          <div className="flex gap-[18px] justify-between py-[11px] border-b border-[#e8e8eb] text-[13px] max-[540px]:block [&>span]:text-[#73737a] [&>strong]:text-right [&>strong]:[overflow-wrap:anywhere] [&>strong]:font-[650] max-[540px]:[&>strong]:block max-[540px]:[&>strong]:mt-1 max-[540px]:[&>strong]:text-left">
            <span>Tên đăng nhập</span>
            <strong>{profile.username}</strong>
          </div>
          <div className="flex gap-[18px] justify-between py-[11px] border-b border-[#e8e8eb] text-[13px] max-[540px]:block [&>span]:text-[#73737a] [&>strong]:text-right [&>strong]:[overflow-wrap:anywhere] [&>strong]:font-[650] max-[540px]:[&>strong]:block max-[540px]:[&>strong]:mt-1 max-[540px]:[&>strong]:text-left">
            <span>Địa chỉ email</span>
            <strong>{profile.email}</strong>
          </div>
          <p className="pt-3.5 text-[#92929a] text-xs leading-normal">
            Tên đăng nhập và email hiện chưa thể thay đổi từ trang hồ sơ.
          </p>
        </div>
        {saveError && (
          <p className="mt-5 p-[12px_14px] rounded-[9px] text-[13px] leading-normal text-[#9b1c25] bg-[#fff0f1]" role="alert">
            {saveError}
          </p>
        )}
        {notice && (
          <p className="mt-5 p-[12px_14px] rounded-[9px] text-[13px] leading-normal text-[#1b683c] bg-[#edfaf1]" role="status">
            {notice}
          </p>
        )}
        <div className="flex justify-end gap-2.5 mt-[26px] max-[540px]:flex-col-reverse max-[540px]:[&>button]:w-full">
          {editing ? (
            <>
              <button
                className="min-h-[47px] px-[22px] rounded-[9px] text-[13px] font-bold cursor-pointer transition-[background,transform] duration-200 border border-[#dedee3] bg-white text-[#4f4f57] hover:bg-[#f4f4f5] focus-visible:outline focus-visible:outline-3 focus-visible:outline-brand/35 focus-visible:outline-offset-3 disabled:opacity-60 disabled:cursor-default"
                type="button"
                onClick={onCancelEditing}
                disabled={saving}
              >
                Hủy
              </button>
              <button
                className="min-h-[47px] px-[22px] rounded-[9px] text-[13px] font-bold cursor-pointer transition-[background,transform] duration-200 border border-[#1d1d1f] bg-[#1d1d1f] text-white hover:bg-brand hover:border-brand focus-visible:outline focus-visible:outline-3 focus-visible:outline-brand/35 focus-visible:outline-offset-3 disabled:opacity-60 disabled:cursor-default"
                type="submit"
                disabled={saving}
              >
                {saving ? "Đang lưu…" : "Lưu thay đổi"}
              </button>
            </>
          ) : (
            <button
              ref={editButtonRef}
              className="min-h-[47px] px-[22px] rounded-[9px] text-[13px] font-bold cursor-pointer transition-[background,transform] duration-200 border border-[#1d1d1f] bg-[#1d1d1f] text-white hover:bg-brand hover:border-brand focus-visible:outline focus-visible:outline-3 focus-visible:outline-brand/35 focus-visible:outline-offset-3 disabled:opacity-60 disabled:cursor-default"
              type="button"
              onClick={onBeginEditing}
              disabled={saving}
              aria-controls="profile-fields"
            >
              Chỉnh sửa
            </button>
          )}
        </div>
      </form>
    </section>
  );
}
