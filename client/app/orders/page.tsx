"use client";

import Link from "next/link";
import { Suspense, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useProtectedSession } from "@/lib/use-protected-session";
import { useCart } from "@/lib/context/CartContext";
import { useOrders } from "@/hooks/queries/useOrders";
import { useCancelOrder } from "@/hooks/mutations/useCancelOrder";
import {
  notifyOrderCancelled,
  notifyPaymentConfirmed,
} from "@/lib/customer-notifications";
import {
  fetchProductById,
} from "@/lib/products-client";
import type { Order, OrderItem } from "@/lib/types/order";
import { OrderReviewProvider } from "@/components/reviews/OrderReviewActions";
import Pagination from "@/components/ui/Pagination";
import OrderFilterBar from "@/components/orders/OrderFilterBar";
import OrderCard from "@/components/orders/OrderCard";

function OrdersContent() {
  const query = useSearchParams();
  const session = useProtectedSession();
  const { addItem, busy } = useCart();
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState(query.get("code") || "");
  const [sortBy, setSortBy] = useState("created_desc");
  const [dateMode, setDateMode] = useState("all");
  const [exactDate, setExactDate] = useState("");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [page, setPage] = useState(1);
  const [notice, setNotice] = useState("");
  const [actionId, setActionId] = useState("");
  const [actionError, setActionError] = useState("");

  const handleResetFilters = () => {
    setSortBy("created_desc");
    setDateMode("all");
    setExactDate("");
    setFromDate("");
    setToDate("");
    setSearch("");
    setPage(1);
  };

  const orderFilters = useMemo(() => {
    const params: Record<string, string> = {
      page: String(page),
      pageSize: "10",
    };
    if (status) params.status = status;
    if (search.trim()) params.search = search.trim();

    if (sortBy === "price_desc") {
      params.sortBy = "totalAmount";
      params.isAscending = "false";
    } else if (sortBy === "price_asc") {
      params.sortBy = "totalAmount";
      params.isAscending = "true";
    } else if (sortBy === "created_asc") {
      params.sortBy = "createdAt";
      params.isAscending = "true";
    } else {
      params.sortBy = "createdAt";
      params.isAscending = "false";
    }

    const todayStr = new Date().toISOString().split("T")[0];
    if (dateMode === "exact" && exactDate) {
      params.fromDate = exactDate;
      params.toDate = exactDate;
    } else if (dateMode === "from" && fromDate) {
      params.fromDate = fromDate;
      params.toDate = todayStr;
    } else if (dateMode === "range") {
      if (fromDate) params.fromDate = fromDate;
      if (toDate) params.toDate = toDate;
    } else if (dateMode === "today") {
      params.fromDate = todayStr;
      params.toDate = todayStr;
    } else if (dateMode === "7days") {
      const d7 = new Date();
      d7.setDate(d7.getDate() - 7);
      params.fromDate = d7.toISOString().split("T")[0];
      params.toDate = todayStr;
    } else if (dateMode === "30days") {
      const d30 = new Date();
      d30.setDate(d30.getDate() - 30);
      params.fromDate = d30.toISOString().split("T")[0];
      params.toDate = todayStr;
    }
    return params;
  }, [page, status, search, sortBy, dateMode, exactDate, fromDate, toDate]);

  const isEnabled = session.status === "ready";
  const {
    data: ordersData,
    isLoading: loading,
    error: queryError,
    refetch,
  } = useOrders(orderFilters, isEnabled);

  const orders = ordersData?.orders || [];
  const totalPages = ordersData?.totalPages || 1;
  const error =
    actionError ||
    (queryError ? (queryError as Error).message || "Không thể tải đơn hàng." : "");

  // Bắn thông báo nếu có cập nhật trạng thái đơn
  useEffect(() => {
    if (session.status === "ready" && ordersData?.orders) {
      const userId = session.user.userId;
      ordersData.orders.forEach((order: Order) => {
        notifyPaymentConfirmed(userId, order);
        notifyOrderCancelled(userId, order);
      });
    }
  }, [session, ordersData]);

  const { mutate: cancelOrder } = useCancelOrder();

  const handleCancelOrder = (order: Order) => {
    const reason = window.prompt("Nhập lý do hủy đơn hàng:");
    if (!reason || !reason.trim()) return;

    setActionId(order.orderId);
    cancelOrder(
      { orderId: order.orderId, reason: reason.trim() },
      {
        onSuccess: () => {
          setNotice(`Đã hủy đơn hàng ${order.orderCode} thành công.`);
          setActionError("");
          setActionId("");
        },
        onError: (e) => {
          setActionError(e.message || "Có lỗi khi hủy đơn hàng.");
          setActionId("");
        },
      }
    );
  };

  const handleReorder = async (item: OrderItem) => {
    setActionId(item.orderItemId);
    try {
      const product = await fetchProductById(item.productId);
      if (!product) throw new Error("Sản phẩm không tồn tại.");
      const variant = product.variants.find((v) => v.variantId === item.variantId);
      if (!variant) throw new Error("Biến thể không tồn tại.");
      if (variant.stockQuantity < 1) throw new Error("Sản phẩm tạm thời hết hàng.");

      const ok = await addItem(
        {
          productId: item.productId,
          productName: item.productName,
          variantId: item.variantId,
          variantName: item.variantName,
          attributes: variant.attributes,
          price: variant.promotion?.promotionalPrice || variant.price,
          imageUrl: item.imageUrl,
          stockQuantity: variant.stockQuantity,
        },
        1,
        true
      );
      if (ok) {
        setNotice(`Đã thêm "${item.productName}" vào giỏ hàng.`);
        setActionError("");
      }
    } catch (e) {
      setActionError(e instanceof Error ? e.message : "Không thể mua lại sản phẩm.");
    } finally {
      setActionId("");
    }
  };

  return (
    <main className="min-h-[calc(100vh-68px)] bg-[#fbfbfb] px-4 py-9 pb-20 sm:px-6">
      <div className="max-w-[1020px] mx-auto">
        <div className="mb-6">
          <p className="text-brand text-[10px] font-bold tracking-[.13em] leading-[1.7] uppercase">THEO DÕI MUA SẮM</p>
          <h1 className="text-2xl sm:text-[2.2rem] font-bold text-[#111111] mb-2 leading-tight">
            Đơn hàng của bạn<span className="text-brand">.</span>
          </h1>
          <p className="text-[#666666] text-[0.95rem]">
            Xem lịch sử đơn hàng, hành trình giao và quét mã chuyển khoản thanh
            toán mọi lúc.
          </p>
        </div>

        <OrderFilterBar
          status={status}
          search={search}
          sortBy={sortBy}
          dateMode={dateMode}
          exactDate={exactDate}
          fromDate={fromDate}
          toDate={toDate}
          onStatusChange={(newStatus) => {
            setStatus(newStatus);
            setPage(1);
          }}
          onSearchChange={(newSearch) => {
            setSearch(newSearch);
            setPage(1);
          }}
          onSortByChange={(newSort) => {
            setSortBy(newSort);
            setPage(1);
          }}
          onDateModeChange={(newMode) => {
            setDateMode(newMode);
            setPage(1);
          }}
          onExactDateChange={(newExact) => {
            setExactDate(newExact);
            setPage(1);
          }}
          onFromDateChange={(newFrom) => {
            setFromDate(newFrom);
            setPage(1);
          }}
          onToDateChange={(newTo) => {
            setToDate(newTo);
            setPage(1);
          }}
          onResetFilters={handleResetFilters}
        />

        {notice && (
          <p role="status" className="p-4 my-5 rounded-[10px] bg-[#eef8f1] text-[#205e39]">
            {notice}
          </p>
        )}
        {error && (
          <div role="alert" className="p-4 my-5 rounded-[10px] bg-[#fff0f1] text-[#8b1926] [&>p]:m-0 [&>button]:mt-2 [&>button]:px-3 [&>button]:py-1.5 [&>button]:bg-white [&>button]:border [&>button]:border-[#fecdd3] [&>button]:rounded-md [&>button]:cursor-pointer">
            <p>{error}</p>
            <button onClick={() => { setActionError(""); void refetch(); }}>Thử lại</button>
          </div>
        )}

        {loading ? (
          <div role="status" className="bg-white border border-[#ebebeb] rounded-[14px] p-10 sm:p-[60px_24px] text-center text-[#666666] flex flex-col items-center gap-3">
            Đang tải đơn hàng…
          </div>
        ) : !error && !orders.length ? (
          <div className="bg-white border border-[#ebebeb] rounded-[14px] p-10 sm:p-[60px_24px] text-center text-[#666666] flex flex-col items-center gap-3 [&>h2]:text-[1.05rem] [&>h2]:font-semibold [&>h2]:text-[#222222] [&>h2]:m-0 [&>p]:text-[0.88rem] [&>p]:text-[#777777] [&>p]:max-w-[420px] [&>p]:m-0 [&>a]:inline-block [&>a]:mt-2 [&>a]:bg-[#111111] [&>a]:text-white [&>a]:px-[22px] [&>a]:py-2.5 [&>a]:rounded-lg [&>a]:no-underline [&>a]:text-[0.88rem] [&>a]:font-semibold [&>a]:hover:bg-brand [&>a]:transition-colors [&>a]:duration-200">
            <h2>Chưa có đơn hàng phù hợp</h2>
            <p>
              Đơn hàng sẽ xuất hiện ở đây sau khi bạn đặt hàng hoặc khớp bộ
              lọc.
            </p>
            <Link href="/products">Khám phá sản phẩm →</Link>
          </div>
        ) : (
          !error && (
            <OrderReviewProvider itemIds={orders.filter((order) => order.status === "DELIVERED").flatMap((order) => order.items.map((item) => String(item.orderItemId)))}>
              <div className="flex flex-col gap-5">
                {orders.map((order) => (
                  <OrderCard
                    key={order.orderId}
                    order={order}
                    busy={busy}
                    actionId={actionId}
                    onReorder={handleReorder}
                    onCancel={handleCancelOrder}
                  />
                ))}
              </div>
            </OrderReviewProvider>
          )
        )}

        {!loading && !error && (
          <Pagination
            currentPage={page}
            totalPages={totalPages}
            onPageChange={setPage}
          />
        )}
      </div>
    </main>
  );
}

export default function OrdersPage() {
  return (
    <Suspense
      fallback={
        <div style={{ padding: "40px", textAlign: "center" }}>
          Đang tải trang đơn hàng…
        </div>
      }
    >
      <OrdersContent />
    </Suspense>
  );
}
