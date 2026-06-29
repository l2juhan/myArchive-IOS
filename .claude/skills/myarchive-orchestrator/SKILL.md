---
name: myarchive-orchestrator
description: "myArchive iOS 앱 기능 구현을 에이전트 팀으로 조율하는 오케스트레이터. 화면·모델·서비스·잠금 등 'myArchive 기능을 만들어/구현해/추가해', '계정 상세 만들어', 'M2 진행해' 같은 구현 요청 시 이 스킬로 팀을 구성해 ui/logic/qa를 배정한다. 단순 질문이 아닌 실제 코드 작업에 트리거한다."
---

# myArchive Orchestrator

myArchive 기능 구현을 **에이전트 팀**으로 조율한다. "누가 언제 어떤 순서로 협업하는가"를 정의한다. 개별 에이전트의 "어떻게"는 `myarchive-ui`/`-logic`/`-qa` 정의와 `myarchive-domain` 스킬에 있다.

## 실행 모드: 에이전트 팀 (기본)

리더(오케스트레이터)가 `TeamCreate`로 팀을 만들고 `TaskCreate`로 작업을 할당한다. 팀원은 `SendMessage`로 직접 조율하고, 산출물은 파일(소스 코드)로, 진행은 `TaskUpdate`로 공유한다. 모든 Agent 호출은 `model: "opus"`.

## 워크플로우

### Phase 0: 컨텍스트 로드
- 현재 작업의 exec-plan(`docs/exec-plans/`)을 읽는다. 없으면 github-issue-work로 먼저 계획을 세운다(승인 게이트).
- CLAUDE.md 매니페스트에서 작업 관련 문서만 선별해 읽는다(PRD 절·Design.md 화면·keychain-schema 등).
- `myarchive-domain` 스킬로 도메인 규칙(보안·정렬·마스킹·방식 B)을 확인한다.

### Phase 1: 작업 분해
- exec-plan의 항목을 **UI 작업 / Logic 작업 / 검증 작업**으로 분류한다.
- 의존성을 정한다: 보통 Logic의 API 시그니처가 먼저, UI가 그 위에. QA는 각 모듈 완성 직후 점진 검증.

### Phase 2: 팀 구성
```
TeamCreate(team_name: "myarchive", members: [
  { name: "ui",    agent: myarchive-ui },
  { name: "logic", agent: myarchive-logic },
  { name: "qa",    agent: myarchive-qa (general-purpose) }
])
TaskCreate([...UI/Logic/검증 작업, 의존성 포함])
```
팀 크기 3명(소~중규모). 작업이 많으면 한 에이전트가 순차로 여러 작업을 claim.

### Phase 3: 구현 (자체 조율)
- logic이 먼저 모델/서비스/ViewModel API를 정하고 ui에 시그니처를 SendMessage.
- ui가 화면을 구현하며 디자인 토큰을 적용. 토큰 추가 시 팀 브로드캐스트.
- 파일 저장 시 PostToolUse가 SwiftFormat+SwiftLint 자동 교정(edit 게이트).
- 각 모듈 완성 직후 qa가 빌드/타입체크/lint + 경계면 교차 검증(incremental QA). 결함은 담당에게 직접 전달, 최대 2회 루프.

### Phase 4: 종합
- 리더가 산출물과 QA 결과를 종합한다.
- exec-plan-sync로 진행을 계획에 반영(commit 시점 게이트와 짝).
- 작업 내용을 정리해 보고하고 **사용자 승인**을 받는다(승인 게이트 2).

### Phase 5: 정리
- 팀을 정리한다. 후속 작업이 다른 전문가 조합이면 새 팀을 구성한다.

## 데이터 전달 프로토콜
- **메시지(SendMessage)**: API 시그니처 교환, 토큰 변경 브로드캐스트, QA 결함 전달.
- **태스크(TaskCreate/Update)**: 진행·의존성·claim.
- **파일**: 소스 코드(최종 산출물), 필요 시 `_workspace/`에 중간 메모.

## 에러 핸들링
- 빌드/검증 실패 → 담당이 1회 자체 수정. 재실패 시 QA가 원인을 SendMessage로 확인 후 재할당. 2회 후에도 실패면 결과 없이 진행하고 보고서에 누락 명시.
- 보안/데이터 손실 위험(BLOCK)은 즉시 멈추고 사용자에게 보고.
- 상충하는 설계 의견은 삭제하지 않고 출처를 병기해 리더가 판단.

## 테스트 시나리오

**정상 흐름**: "상세 화면 시크릿 블러+터치 해제 구현" → Phase0 exec-plan 로드 → logic이 마스킹 상태/타이머 API 제공 → ui가 블러+탭 해제 View 구현 → qa가 22초 재마스킹·이탈 재마스킹·평문 누출 교차 검증 → 종합·승인.

**에러 흐름**: qa가 "이탈 후 재진입 시 재마스킹 안 됨" BLOCK 판정 → ui에 SendMessage → ui가 onDisappear에서 revealed 초기화 누락 수정 → qa 재검증 PASS. 2회째도 실패면 사용자 보고.
