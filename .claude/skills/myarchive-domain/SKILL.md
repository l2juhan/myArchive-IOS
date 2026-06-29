---
name: myarchive-domain
description: "myArchive의 도메인 규칙·패턴을 담은 참조 스킬. 방식 B(SwiftData+Keychain) 저장, 시크릿 마스킹/터치 해제, 필드별 복사+클립보드 만료, 선택적 잠금, updatedAt 정렬/표기, F-15 색상 등 myArchive 고유 규칙을 구현/검증할 때 참조한다. 모델·보안·정렬·마스킹 작업 시 반드시 확인할 것."
---

# myArchive 도메인 규칙

myArchive 구현·검증의 도메인 단일 참조. PRD/Design.md의 핵심 규칙을 구현 관점으로 압축했다. 세부는 `docs/references/`(PRD·Design.md·keychain-schema)를 본다.

## 1. 저장 — 방식 B (절대 규칙)
- 메타데이터(서비스명·아이디·메모·URL·색·즐겨찾기·날짜·커스텀 구조)는 **SwiftData**.
- 시크릿(비밀번호·커스텀 값)은 **Keychain**, 메타에는 참조 키만(`passwordRef`/`valueRef`).
- 시크릿 평문은 SwiftData·UserDefaults·로그·스냅샷에 **절대** 들어가지 않는다.
- Keychain 접근성 `kSecAttrAccessibleWhenUnlocked`. 키 규칙 `pw_{id}`/`cf_{id}`.
- 삭제 시 메타+Keychain 함께 정리. (→ `KeychainService`, keychain-schema.md)

## 2. 시크릿 표시 — 마스킹/터치 해제 (F-3)
- 아이디·비밀번호·커스텀 값은 기본 **블러(5px)** + 눈 힌트. URL·메모는 비시크릿(항상 표시).
- 블러된 값을 **직접 탭하면 그 필드만** 평문 표시. 토글이 아니라 **단방향**.
- **약 22초 후 또는 상세 이탈 시 자동 재마스킹**. 상세를 벗어나면 `revealed` 초기화.

## 3. 복사 — 필드별 + 만료 (F-4 / F-8)
- 필드마다 **독립 복사 버튼**. 묶음 복사 없음.
- 복사 시 `UIPasteboard` 만료(30/60/120초, 기본 60) 설정 + 토스트("{라벨} 복사됨 · N초 후 자동 삭제") + 버튼 1.3s 체크.

## 4. 정렬·시간 — updatedAt 기준 (F-9 / F-14, v0.5)
- 기본(`favoriteRecent`): 즐겨찾기 그룹 최상단, 각 그룹 내부 `updatedAt ?? createdAt` 내림차순.
- 이름순(`name`): 즐겨찾기 우선 없이 `serviceName` 오름차순(한국어 로케일).
- 검색 중에는 단일 "검색 결과" 섹션. 신규 저장 직후 검색어 초기화.
- 보조 텍스트: 수정 이력 있으면 "N분 전 수정", 없으면 "N분 전 생성". `lastUsedAt` 금지.
- 상대시간: <1분 '방금 전' / <60분 'N분 전' / <24시간 'N시간 전' / <30일 'N일 전' / 이상 'N주 전'. (→ `CredentialSorter`, `RelativeTime`)

## 5. 검색 (F-2)
- `serviceName` 또는 `username` **부분 일치(대소문자 무시)**. 입력 즉시 인메모리 필터.

## 6. 잠금 (F-5, 선택)
- `isAppLockEnabled` 기본 **false**. 켜면 진입 시 잠금 화면 → LocalAuthentication(생체→암호 폴백).
- 잠금 ON일 때만: 백그라운드 화면 가림 + 재진입 재인증(F-10). 설정 '지금 잠그기'.
- 저장 보호(Keychain)는 잠금과 무관하게 항상 적용.

## 7. 계정 색 (F-15)
- 신규 기본 토스 파랑 `#3182F6`. 9색 프리셋 + 커스텀(네이티브 컬러 피커).
- 미지정 시 서비스명 해시 폴백. 밝은 색은 이니셜/체크 잉크색. 목록·상세 아바타에만 반영(정렬·검색 무관). (→ `MAAvatarPalette`)

## 8. 추가/수정 드래프트 (3.7)
- 서비스명 비면 저장 비활성. 커스텀 필드 인라인 추가/삭제, 라벨·값 모두 빈 항목은 저장 시 폐기.
- 신규 저장 시 `createdAt`=현재·`updatedAt`=nil, 편집 저장 시 `updatedAt`=현재.

## 9. 비목표 (하지 않는다)
클라우드 동기화·공유·AutoFill(v2)·다크 모드(v1.1)·외부 SDK·네트워크. 라이트 모드 전용.

## 구현 매핑
PRD 기능 ↔ 코드는 `docs/ARCHITECTURE.md`, 토큰은 `docs/DESIGN_SYSTEM.md`, 데이터는 `docs/references/keychain-schema.md` 참조. 마일스톤 M1~M6는 PRD 12장.
