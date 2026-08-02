import type { Area } from "@/types/area";

export const mockAreas: Area[] = [
  {
    id: "area-1",
    slug: "seongsu-strategic-zone-1",
    name: "성수전략정비구역 1지구",
    district: "성동구",
    address: "서울특별시 성동구 성수동1가 일대",
    projectType: "재개발",
    currentStage: "정비구역 지정",
    isShintong: false,
    isMoatown: false,
    isTohuga: true,
    expectedUnits: 3014,
    investmentScore: 86,
    riskScore: 44,
    summary: "한강변 입지와 대규모 정비계획을 갖춘 장기 관찰 대상 구역입니다.",
    updatedAt: "2026-07-28",
  },
  {
    id: "area-2",
    slug: "sanggye-newtown-zone-5",
    name: "상계뉴타운 5구역",
    district: "노원구",
    address: "서울특별시 노원구 상계동 일대",
    projectType: "재개발",
    currentStage: "사업시행인가",
    isShintong: false,
    isMoatown: false,
    isTohuga: false,
    expectedUnits: 2042,
    investmentScore: 78,
    riskScore: 38,
    summary: "사업 진행 속도와 동북권 주거 환경 개선 가능성을 함께 살펴볼 구역입니다.",
    updatedAt: "2026-07-24",
  },
  {
    id: "area-3",
    slug: "myeonmok-moa-town",
    name: "면목동 모아타운",
    district: "중랑구",
    address: "서울특별시 중랑구 면목동 일대",
    projectType: "모아타운",
    currentStage: "정비구역 지정",
    isShintong: false,
    isMoatown: true,
    isTohuga: false,
    expectedUnits: 1850,
    investmentScore: 72,
    riskScore: 51,
    summary: "소규모 정비사업이 모여 진행되는 만큼 구역별 속도 차이를 확인해야 합니다.",
    updatedAt: "2026-07-20",
  },
];

export function getAreaBySlug(slug: string) {
  return mockAreas.find((area) => area.slug === slug);
}

