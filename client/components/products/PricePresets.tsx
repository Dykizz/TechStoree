"use client";

import { cn } from "@/lib/utils";

export interface PricePreset {
  id: string;
  label: string;
  desc: string;
  min?: number;
  max?: number;
}

export const PRESETS: PricePreset[] = [
  { id: "all", label: "Tất cả mức giá", desc: "Toàn bộ dải giá" },
  {
    id: "under-2m",
    label: "Dưới 2 triệu",
    desc: "< 2.000.000 ₫",
    max: 2000000,
  },
  {
    id: "2m-5m",
    label: "2 - 5 triệu",
    desc: "2.000.000 - 5.000.000 ₫",
    min: 2000000,
    max: 5000000,
  },
  {
    id: "2m-10m",
    label: "2 - 10 triệu",
    desc: "2.000.000 - 10.000.000 ₫",
    min: 2000000,
    max: 10000000,
  },
  {
    id: "5m-10m",
    label: "5 - 10 triệu",
    desc: "5.000.000 - 10.000.000 ₫",
    min: 5000000,
    max: 10000000,
  },
  {
    id: "10m-20m",
    label: "10 - 20 triệu",
    desc: "10.000.000 - 20.000.000 ₫",
    min: 10000000,
    max: 20000000,
  },
  {
    id: "above-20m",
    label: "Trên 20 triệu",
    desc: "> 20.000.000 ₫",
    min: 20000000,
  },
];

interface PricePresetsProps {
  activePresetId?: string;
  onSelectPreset: (preset: PricePreset) => void;
}

export default function PricePresets({
  activePresetId,
  onSelectPreset,
}: PricePresetsProps) {
  return (
    <div className="grid grid-cols-2 gap-2 mb-3.5 max-[480px]:grid-cols-1">
      {PRESETS.map((preset) => {
        const isSelected = activePresetId === preset.id;
        return (
          <button
            key={preset.id}
            type="button"
            className={cn(
              "flex flex-col items-start p-2 sm:px-2.5 border rounded-lg text-left cursor-pointer transition-all duration-150",
              isSelected
                ? "border-ink bg-ink text-white hover:bg-[#222222] hover:border-[#222222]"
                : "border-[#e5e5e5] bg-white hover:border-ink hover:bg-[#fafafa]"
            )}
            onClick={() => onSelectPreset(preset)}
          >
            <span className="text-[0.82rem] font-semibold leading-[1.25]">
              {preset.label}
            </span>
            <span
              className={cn(
                "text-[0.7rem] mt-0.5",
                isSelected ? "text-[#bbbbbb]" : "text-[#888888]"
              )}
            >
              {preset.desc}
            </span>
          </button>
        );
      })}
    </div>
  );
}
