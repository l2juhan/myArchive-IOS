# DEPLOY — Archive / TestFlight 배포 가이드

myArchive는 **1인 개발·로컬 전용** iOS 앱이다(네트워크 권한 없음, 라이트 모드 전용). 배포 흐름은 표준 iOS: **XcodeGen → 서명 → archive → App Store Connect 업로드 → TestFlight**. 외부 라이브러리·서버가 없어 백엔드 배포는 없다.

## 0. 사전 준비 (1회)

- Apple Developer Program 가입.
- App Store Connect에 앱 등록(번들 ID `com.l2juhan.myArchive`, 이름 myArchive).
- Team ID 확보(Apple Developer 계정 Membership).

## 1. 서명 설정 (project.yml)

서명 정보는 코드가 아닌 `project.yml`에 둔다(`.xcodeproj`는 비추적·재생성 대상). `DEVELOPMENT_TEAM`이 비어 있으면 archive가 실패한다.

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "YOURTEAMID"   # 필수 — 비우지 않는다
    MARKETING_VERSION: "1.0"          # 사용자 노출 버전
    CURRENT_PROJECT_VERSION: "1"      # 빌드 번호
```

자동 서명을 쓰면 `CODE_SIGN_STYLE: Automatic`만으로 충분하다. 변경 후 반드시 재생성한다.

```bash
xcodegen generate
```

> **NSFaceIDUsageDescription** 은 `project.yml`의 `INFOPLIST_KEY_NSFaceIDUsageDescription`에 이미 설정됨(선택적 Face ID 잠금 F-5). 누락 시 App Store 심사 리젝 사유가 되므로 제거하지 않는다.

## 2. 버전·빌드 번호 관리

- `MARKETING_VERSION` = 사용자에게 보이는 버전(예: 1.0, 1.1). 기능 추가/수정 시 올린다.
- `CURRENT_PROJECT_VERSION` = 빌드 번호. **TestFlight 업로드마다 반드시 증가**(같은 번호 재업로드 불가).
- 둘 다 `project.yml`에서만 수정하고 `xcodegen generate`로 반영한다.

## 3. Archive

```bash
xcodebuild archive \
  -project myArchive.xcodeproj \
  -scheme myArchive \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/myArchive.xcarchive
```

## 4. App Store Connect 업로드

### 방법 A — Xcode Organizer (권장, 1인 개발에 단순)
1. `open build/myArchive.xcarchive` 또는 Xcode → Window → Organizer.
2. **Distribute App → App Store Connect → Upload** 진행.

### 방법 B — 커맨드라인 (xcrun)
ExportOptions.plist(`method: app-store`, `teamID` 지정)를 만든 뒤:

```bash
xcodebuild -exportArchive \
  -archivePath build/myArchive.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export

xcrun altool --upload-app -f build/export/myArchive.ipa \
  -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
# 또는 최신: xcrun notarytool 계열 대신 App Store Connect API 키 사용
```

App Store Connect API 키(Issuer ID + Key ID + .p8)를 환경변수로 두면 비대화형 업로드가 가능하다.

## 5. TestFlight

1. 업로드 후 App Store Connect에서 빌드 **처리(Processing) 완료** 대기(수 분~수십 분).
2. **수출 규정(Export Compliance)**: 자체 암호화를 추가 구현하지 않고 Keychain 등 OS 표준 API만 사용 → 일반적으로 "면제" 선택 가능. Info.plist에 `ITSAppUsesNonExemptEncryption = NO`를 두면 매 업로드 질문을 생략할 수 있다.
3. 내부 테스터에 빌드 할당 → 설치·검증.
4. 외부 테스터 사용 시 베타 심사 통과 필요.

## 배포 전 체크리스트

- [ ] `DEVELOPMENT_TEAM` 설정됨, `xcodegen generate` 재실행함.
- [ ] `CURRENT_PROJECT_VERSION`이 이전 업로드보다 큼.
- [ ] `NSFaceIDUsageDescription` 존재(Face ID 잠금 사용 시 필수).
- [ ] 라이트 모드 전용(`UIUserInterfaceStyle = Light`) 유지 — 다크 모드 미지원.
- [ ] 네트워크 권한 없음 — ATS·네트워크 키를 추가하지 않음(완전 오프라인, PRD 6.3).
- [ ] 시크릿 평문 누출 0 — 로그/UserDefaults/SwiftData에 평문 없음(보안 게이트).
- [ ] `xcodebuild test` green(TESTING.md).
- [ ] SwiftLint error 0, SwiftFormat 적용됨.
- [ ] AppIcon 모든 사이즈 채워짐, 스크린샷·개인정보 처리(앱은 데이터 수집 없음 → "수집 안 함") 명시.
- [ ] Release 구성으로 archive(Debug 아님).
