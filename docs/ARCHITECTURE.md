# ARCHITECTURE — 코드 컨벤션 & 아키텍처

myArchive는 **MVVM + 방식 B(SwiftData 메타 + Keychain 시크릿)** 로 구성된다. 외부 라이브러리 없이 Apple 표준 프레임워크만 사용한다.

## 레이어

```
View (SwiftUI)  ──호출──▶  ViewModel (@Observable)  ──▶  Service / Model
   표시만                    화면 상태·조율               값 처리·보안·영속
```

- **View** (`Views/`, `DesignSystem/`): 선언형 UI. 디자인 토큰만 사용. 시크릿 값을 직접 보유/가공하지 않는다.
- **ViewModel** (`ViewModels/`): 화면 상태(`query`, `revealed`, `draft`, `toast` 등), 사용자 액션을 서비스 호출로 변환. iOS 17 `@Observable` 사용.
- **Service** (`Services/`): `KeychainService`(시크릿), `AuthService`(잠금), `ClipboardService`(만료 복사), `CredentialSorter`(정렬/섹션), `RelativeTime`(표기).
- **Model** (`Models/`): SwiftData `@Model`(`Credential`, `CustomField`) + 설정 enum(`SortMode`, `ClipboardExpiry`, `SettingsKey`).

## 핵심 규칙

1. **시크릿 격리**: 비밀번호·커스텀 값은 Keychain에만. SwiftData/UserDefaults/로그에 평문 금지. 메타에는 참조 키(`passwordRef`/`valueRef`)만.
2. **정렬·시간 기준**: `updatedAt ?? createdAt`. 표기는 "수정/생성"(v0.5). `lastUsedAt` 사용 금지.
3. **잠금은 선택**: `isAppLockEnabled` 기본 false. 저장 보호(Keychain)는 잠금과 무관하게 항상 적용.
4. **상태 소유**: 영속 상태는 SwiftData/UserDefaults, 휘발 UI 상태는 ViewModel/`@State`. 마스킹 해제·토스트·드래프트는 휘발.
5. **인메모리 검색**: 메타데이터는 메모리에서 필터. 시크릿은 표시 시점에만 Keychain 조회(PRD 6.1).
6. **에러 전파**: Keychain OSStatus는 타입화된 에러로. 삼키지 않는다.

## 네이밍

- 디자인 토큰: `MAColor`/`MAType`/`MARadius`/`MASpacing`/`MAMotion`.
- View: `{화면}View`, 컴포넌트: 역할 기반(`AvatarView`, `CopyButton`).
- 서비스: `{역할}Service`(stateless enum) 또는 `{역할}Store`(상태 보유).

## 상태 변수 매핑 (Design.md 3.10 → 구현)

`stack`→NavigationStack path, `isLocked`→RootView, `creds[]`→`@Query`, `query`/`sortMode`→ListVM, `appLock`/`expiry`→`@AppStorage`, `revealed{}`/`pwShown`/`draft`/`toast`/`copiedKey`/`confirmDelete`/`authing`→해당 화면 ViewModel.
