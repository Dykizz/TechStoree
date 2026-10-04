import type { Metadata } from "next";
import ProfileClient from "./profile-client";

export const metadata: Metadata = {
  title: "Hồ sơ của tôi | TechStoree",
  description: "Xem và cập nhật hồ sơ khách hàng TechStoree.",
};

export default async function ProfilePage({ searchParams }: PageProps<"/profile">) {
  const query = await searchParams;
  const preview = process.env.NODE_ENV === "development" && query.preview === "1";
  return <ProfileClient preview={preview} />;
}
