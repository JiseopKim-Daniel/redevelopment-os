# ARCHITECTURE - Redevelopment OS

## 1. 시스템 개요

이 프로젝트는 웹 프론트엔드 + 데이터베이스 + 향후 자동화 워크플로 구조로 설계한다.

### 구성 요소
1. Frontend
2. Database
3. Data Ingestion / Automation
4. AI Analysis

---

## 2. 구성

### Frontend
- Next.js
- TypeScript
- Tailwind CSS

역할:
- 사용자 UI 제공
- 구역 목록 / 상세 조회
- 지도 표시
- 관심 구역 관리

### Database
- Supabase (PostgreSQL)

역할:
- 구역 정보 저장
- 사업 단계 저장
- 메모 / 점수 저장
- 향후 사용자 데이터 저장

### Automation
- n8n (추후)
- 필요 시 scripts 디렉토리의 수집 스크립트 사용

역할:
- 공식 데이터 수집
- 변경 감지
- DB 업데이트

### AI Layer
- OpenAI API (추후)

역할:
- 구역 요약 생성
- 투자 코멘트 생성
- 리스크 분석 보조

---

## 3. 초기 아키텍처 흐름

1. 사용자가 웹 앱 접속
2. Next.js가 Supabase에서 구역 데이터를 조회
3. 목록/상세 페이지에서 데이터 표시
4. 투자 점수는 DB 또는 계산 함수로 제공
5. 추후 자동화 프로세스가 정기적으로 데이터를 업데이트

---

## 4. 디렉토리 구조 초안

```text
/app
  /areas
  /areas/[slug]
  /favorites
  /settings

/components
/lib
/scripts
/docs