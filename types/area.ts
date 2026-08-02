export type ProjectStage =
  | "정비구역 지정"
  | "조합설립인가"
  | "사업시행인가"
  | "관리처분인가";

export interface Area {
  id: string;
  slug: string;
  name: string;
  district: string;
  address: string;
  projectType: "재개발" | "재건축" | "모아타운";
  currentStage: ProjectStage;
  isShintong: boolean;
  isMoatown: boolean;
  isTohuga: boolean;
  expectedUnits: number;
  investmentScore: number;
  riskScore: number;
  summary: string;
  updatedAt: string;
}

