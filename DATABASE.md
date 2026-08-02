
---

## 5) `DATABASE.md`

```md
# DATABASE - Redevelopment OS

## 1. 주요 테이블

초기 MVP에서는 아래 테이블을 우선 사용한다.

### 1) areas
구역 기본 정보

필드 예시:
- id
- name
- slug
- district
- address
- area_type
- project_type
- current_stage
- is_shintong
- is_moatown
- is_tohuga
- builder
- expected_units
- expected_move_in
- latitude
- longitude
- investment_score
- risk_score
- memo
- created_at
- updated_at

### 2) stage_history
사업 단계 변경 이력

필드 예시:
- id
- area_id
- stage_name
- stage_date
- source
- note
- created_at

### 3) favorites
관심 구역

필드 예시:
- id
- area_id
- created_at

### 4) score_breakdown
투자 점수 세부 항목

필드 예시:
- id
- area_id
- location_score
- business_score
- speed_score
- price_score
- risk_score
- total_score
- comment
- updated_at

---

## 2. areas 테이블 상세 정의 초안

| field | type | description |
|---|---|---|
| id | uuid | primary key |
| name | text | 구역명 |
| slug | text | URL용 식별자 |
| district | text | 자치구 |
| address | text | 대표 주소 |
| area_type | text | 구역 유형 |
| project_type | text | 재개발/재건축/모아타운 등 |
| current_stage | text | 현재 사업 단계 |
| is_shintong | boolean | 신통기획 여부 |
| is_moatown | boolean | 모아타운 여부 |
| is_tohuga | boolean | 토지거래허가구역 여부 |
| builder | text | 시공사 |
| expected_units | integer | 예상 세대수 |
| expected_move_in | text | 예상 입주 시기 |
| latitude | numeric | 위도 |
| longitude | numeric | 경도 |
| investment_score | numeric | 투자 점수 |
| risk_score | numeric | 리스크 점수 |
| memo | text | 메모 |
| created_at | timestamp | 생성일 |
| updated_at | timestamp | 수정일 |

---

## 3. 향후 확장 테이블
- transactions
- news_items
- official_sources
- alerts
- users

---

## 4. 데이터 원칙
1. 공식 정보와 개인 메모를 분리 가능하게 설계
2. 변경 이력은 별도 저장
3. 점수는 계산값과 세부항목을 함께 저장
4. 향후 자동화 연동이 가능하게 구조화