import type { Metadata } from "next";
import SurveysClient from "./surveys-client";
export const metadata: Metadata = { title: "Khảo sát của tôi | TechStoree" };
export default function SurveysPage() {
  return <SurveysClient />;
}
