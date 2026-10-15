// Shared logout for the customer header, including the profile/orders pages.
export async function logoutCustomer() {
  const response = await fetch("/api/auth/logout", { method: "POST" });
  const result = await response.json();
  if (!response.ok || result.signedOut !== true) {
    throw new Error(result.message || "Không thể đăng xuất. Vui lòng thử lại.");
  }

  try {
    localStorage.removeItem("techstoree_cart");
    localStorage.removeItem("techstoree_voucher");
  } catch {
    // Cookie logout still succeeds if browser storage is unavailable.
  }
  return result as { signedOut: true; backendRevoked: boolean; message: string };
}
