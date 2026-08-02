# redevelopment-os
Real Estate Intelligent Platform
# Redevelopment OS

서울 재개발/재건축 투자 정보를 체계적으로 관리하고, 공식 데이터 기반으로 자동 업데이트되는 투자 분석 플랫폼.

## 목표
이 프로젝트의 목표는 서울의 재개발/재건축 구역 정보를 한곳에 모으고, 다음 기능을 제공하는 것이다.

- 구역별 사업 단계 조회
- 지도 기반 탐색
- 신통기획 / 모아타운 / 토지거래허가구역 여부 확인
- 투자 점수 계산
- 관심 구역 관리
- 공식 데이터 기반 자동 업데이트
- AI 기반 요약 및 투자 리포트

## 핵심 사용자
- 1차: 개인 투자자 (프로젝트 소유자 본인)
- 2차: 서울 재개발 투자에 관심 있는 일반 사용자

## MVP 범위
- 서울 재개발/재건축 구역 데이터베이스 구축
- 구역 목록 및 상세 페이지
- 기본 지도 표시
- 사업 단계 / 기본 속성 조회
- 투자 점수 계산 로직 v1
- 관심 구역 저장

## 기술 스택
- Frontend: Next.js, TypeScript, Tailwind CSS
- Backend / DB: Supabase
- Map: Mapbox or Kakao Maps (추후 결정)
- Automation: n8n
- AI: OpenAI API

## 문서
- `PRD.md`: 제품 요구사항 문서
- `ROADMAP.md`: 개발 단계 및 일정
- `ARCHITECTURE.md`: 시스템 구조
- `DATABASE.md`: 데이터베이스 설계
- `TODO.md`: 우선순위 작업 목록

## 개발 원칙
1. 공식 정보 우선
2. MVP부터 빠르게 구현
3. 수동 정리보다 자동화 가능한 구조 우선
4. 투자 판단에 필요한 핵심 데이터 중심 설계