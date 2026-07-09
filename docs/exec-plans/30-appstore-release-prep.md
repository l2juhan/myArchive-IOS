# 30 App Store 배포 준비 — 리포 설정(수출규정·Privacy Manifest)

- 이슈: #30  ·  PRD: (배포)  ·  마일스톤: 출시
- 상태: 리포 작업 완료(수출규정·Privacy Manifest) · 후속(스토어 제출)은 수동/외부

## 목표
App Store/TestFlight 업로드가 **심사 반려·제출 경고 없이 통과**하도록, 리포에서 처리해야 하는
빌드 산출물 요건을 갖춘다. 구체적으로 (a) 암호화 수출규정 면제 선언, (b) Privacy Manifest 추가.
앱 아이콘·버전은 이미 충족되어 있어 검증만 한다.

> 범위 밖(이번 계획 아님): 계정/서명/ASC 앱 레코드(수동 GUI, 이미 완료). 스토어 메타데이터·스크린샷·
> 개인정보처리방침 URL 호스팅·연령등급·Archive/업로드/제출은 TestFlight 이후 후속 단계(아래 "후속").

## 작업 분해

### UI (myarchive-ui)
- 없음 (SwiftUI 화면 변경 없음)

### Logic (myarchive-logic)
- [x] **수출규정**: `project.yml`을 `GENERATE_INFOPLIST_FILE` → XcodeGen `info.properties`(물리 Info.plist 생성)로
      전환하고 `ITSAppUsesNonExemptEncryption: false`를 진짜 불리언으로 주입. 기존 키(Face ID·라이트모드·
      세로고정·버전변수) 전부 이관. (`INFOPLIST_KEY_`는 불리언을 문자열로 낼 위험 + 헤드리스 검증 불가라 배제)
- [x] **Privacy Manifest**: `myArchive/PrivacyInfo.xcprivacy` 생성 — `NSPrivacyTracking=false`,
      `TrackingDomains=[]`, `CollectedDataTypes=[]`, `AccessedAPITypes`에 UserDefaults(`CA92.1`)만. 번들 리소스 포함.

### 검증 (myarchive-qa)
- [x] Required Reason API 재감사: UserDefaults 외 없음(파일 타임스탬프/디스크/부팅시간/키보드 미사용) 확인.
- [x] `xcodegen generate` 성공 → SwiftFormat 0/34, SwiftLint clean(Swift 코드 미변경 → 타입체크 상태 불변).
- [x] 생성 Info.plist에 `ITSAppUsesNonExemptEncryption => false`(불리언) 존재, `.xcprivacy` Copy Bundle Resources 포함,
      `INFOPLIST_FILE` 정상·리소스 중복 0 확인.
- [x] 앱 아이콘 1024·알파 없음(기존 충족) / `MARKETING_VERSION=1.0`·`CURRENT_PROJECT_VERSION=1` 확인.
- [ ] **실기기 핸드오프**: Archive→업로드는 사용자가 Xcode로 수동 수행(하네스 실기기 정책). QA 자동화는 여기까지.

## 의존성
Logic 두 작업은 독립(병렬 가능) → QA가 `xcodegen generate` 후 일괄 검증. UI 없음.

## 완료 조건
- `xcodegen generate` 결과 Info.plist에 `ITSAppUsesNonExemptEncryption = false` 반영.
- `PrivacyInfo.xcprivacy`가 존재하고 UserDefaults(CA92.1)만 선언, 수집/추적 없음으로 App Privacy와 일치.
- typecheck/lint 통과. 앱 아이콘·버전 요건 충족 확인.
- (관찰 가능) 이 상태로 사용자가 Archive 시 수출규정 재질문이 안 뜨고, Privacy 경고 없이 업로드 준비됨.

## 후속 (이번 PR 이후, 대부분 수동/외부)
- 스토어 메타데이터(이름·부제·설명·키워드·카테고리·Support URL·Copyright·리뷰연락처)
- 스크린샷 iPhone 6.9" 1290×2796(실기기 캡처)
- App Privacy "Data Not Collected" 선언(ASC)
- 개인정보처리방침 URL·Support URL 호스팅(정적 페이지 — 원하면 리포에 마크다운 초안 별도 작성 가능)
- 연령등급 설문(4+) 응답
- 버전/빌드 번호 규칙 → Archive → 업로드 → TestFlight 내부 테스터 설치 → Submit for Review

## 진행 로그
- 2026-07-09: 리포 작업 구현·검증 완료.
  - `project.yml`: 앱 타깃을 `info.properties` 방식으로 전환(`ITSAppUsesNonExemptEncryption=false` + 기존 키 이관).
  - `myArchive/Info.plist`(신규 생성물), `myArchive/PrivacyInfo.xcprivacy`(신규) 추가.
  - `xcodegen generate` 후 Info.plist 불리언·xcprivacy 리소스 포함·lint 통과 확인.
  - 병행: GitHub Pages(`gh-pages`)에 개인정보처리방침/지원 페이지 게시(제출용 URL 확보).
  - 후속(수동): 스토어 메타/스크린샷/App Privacy·연령등급 입력 → Archive → 업로드 → TestFlight → 제출.
