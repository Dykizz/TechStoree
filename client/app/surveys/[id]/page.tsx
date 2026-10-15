import type { Metadata } from "next";
import SurveysClient from "../surveys-client";
export const metadata: Metadata = { title: "Thực hiện khảo sát | TechStoree" };
export default async function SurveyPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <SurveysClient key={id} surveyId={id} />;
}
