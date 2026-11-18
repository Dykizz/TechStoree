"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useProducts } from "@/hooks/queries/useProducts";
import SearchBar from "./SearchBar";

export default function HomeSearch() {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const { data } = useProducts({ pageSize: 100 });

  function search(value: string) {
    const keyword = value.trim();
    if (keyword) router.push(`/products?${new URLSearchParams({ search: keyword })}`);
  }

  return (
    <section className="relative z-[60] border-b border-border bg-white px-5 py-4 sm:px-8" aria-label="Tìm kiếm sản phẩm tại trang chủ">
      <form
        role="search"
        className="mx-auto flex max-w-[760px] items-center gap-3 max-sm:gap-2"
        onSubmit={(event) => {
          event.preventDefault();
          search(query);
        }}
      >
        <div className="min-w-0 flex-1">
          <SearchBar value={query} onChange={setQuery} onSearch={search} allProducts={data?.items ?? []} />
        </div>
        <button type="submit" disabled={!query.trim()} className="shrink-0 rounded-full bg-brand px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-brand-hover disabled:cursor-default disabled:opacity-50 max-sm:px-3">
          Tìm kiếm
        </button>
      </form>
    </section>
  );
}
