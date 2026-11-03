"use client";

import Link from "next/link";
import type { ProfileData } from "@/lib/auth-server";

interface ProfileOverviewProps {
  profile: ProfileData;
  preview: boolean;
}

export default function ProfileOverview({ profile, preview }: ProfileOverviewProps) {
  const initials =
    profile.fullName
      .trim()
      .split(/\s+/)
      .slice(-2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "T";

  return (
    <aside
      className="bg-white border border-[#e9e9eb] rounded-[20px] shadow-[0_16px_50px_rgba(22,23,30,0.035)] p-8 max-[780px]:grid max-[780px]:grid-cols-[54px_1fr] max-[780px]:gap-x-4 max-[780px]:p-[22px]"
      aria-label="Thông tin tài khoản"
    >
      <div
        className="w-[72px] h-[72px] grid place-items-center rounded-full mb-8 bg-[#f8e8e9] text-[#ad1826] text-2xl font-bold max-[780px]:row-span-3 max-[780px]:w-[54px] max-[780px]:h-[54px] max-[780px]:m-0 max-[780px]:text-[19px]"
        aria-hidden="true"
      >
        {initials}
      </div>
      <p className="text-[#9a9aa0] text-[10px] font-[750] tracking-[0.17em]">
        TÀI KHOẢN CỦA TÔI
      </p>
      <h2 className="my-2.5 mb-1 [overflow-wrap:anywhere] text-2xl tracking-[-0.035em] font-bold text-[#1d1d1f] max-[780px]:my-1 max-[780px]:text-[19px]">
        {profile.fullName || profile.username}
      </h2>
      <p className="text-[#6e6e75] text-[13px] [overflow-wrap:anywhere]">
        {profile.email}
      </p>
      <div className="h-px bg-[#ececef] my-7 mb-[22px] max-[780px]:hidden" />
      <p className="text-[#86868e] text-xs leading-[1.7] max-[780px]:hidden">
        {preview
          ? "Đây là thông tin minh họa, không phải tài khoản thật."
          : "Thông tin được lưu trên tài khoản TechStoree của bạn."}
      </p>
      <Link
        className="flex items-center justify-between mt-[25px] pt-[17px] border-t border-[#ececef] text-[#1d1d1f] text-xs font-bold no-underline hover:text-brand max-[780px]:col-start-2 max-[780px]:mt-1.5 max-[780px]:pt-0 max-[780px]:border-t-0"
        href="/surveys"
      >
        Khảo sát của tôi <span aria-hidden="true">↗</span>
      </Link>
      <Link
        className="flex items-center justify-between mt-3 pt-3 border-t border-[#ececef] text-[#1d1d1f] text-xs font-bold no-underline hover:text-brand max-[780px]:col-start-2 max-[780px]:mt-1.5 max-[780px]:pt-0 max-[780px]:border-t-0"
        href="/vouchers"
      >
        Mã giảm giá của tôi <span aria-hidden="true">↗</span>
      </Link>
    </aside>
  );
}
