# 데이터 모델 + Keychain 스키마 (방식 B) — 1차 자료

myArchive의 저장 아키텍처는 **방식 B**다: 메타데이터는 SwiftData, 시크릿은 Keychain, 메타에는 Keychain 참조 키만. 모델·시크릿 저장 작업은 이 문서를 먼저 읽는다(PRD 7·9장 근거). 스키마를 바꾸면 이 문서를 함께 갱신한다(doc-sync-map: `data-model-keychain`).

## SwiftData — 메타데이터

### Credential (`@Model`)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| id | UUID (.unique) | 고유 식별자 |
| serviceName | String | 서비스명 (검색 대상) |
| username | String | 아이디 (검색 대상, 화면 마스킹) |
| passwordRef | String | 비밀번호의 Keychain 키 |
| memo | String? | 메모(비시크릿) |
| urlString | String? | URL(비시크릿) |
| colorHex | String | 아바타 색(F-15), 미지정 시 해시 폴백 |
| isFavorite | Bool | 즐겨찾기(정렬 1순위) |
| createdAt | Date | 생성 시각 |
| updatedAt | Date? | 수정 시각 |
| customFields | [CustomField] | `@Relationship(.cascade)` |

파생: `activityDate = updatedAt ?? createdAt`, `wasEdited = updatedAt != nil`.

### CustomField (`@Model`)
| 필드 | 타입 | 설명 |
| --- | --- | --- |
| id | UUID (.unique) | 고유 식별자 |
| label | String | 필드 이름(예: "2차 비밀번호") |
| valueRef | String | 값의 Keychain 키 |
| sortOrder | Int | 상세 표시 순서 |
| credential | Credential? | 역참조 |

## Keychain — 시크릿

- 클래스: `kSecClassGenericPassword`, 서비스: `com.l2juhan.myArchive.secrets`.
- 접근성: **`kSecAttrAccessibleWhenUnlocked`**(기기 잠금 해제 시에만 접근, PRD 7.3).
- 키 규칙: 비밀번호 `pw_{credentialID}`, 커스텀 값 `cf_{fieldID}` (`KeychainService.passwordRef/valueRef`).

| Keychain account(키) | 값 |
| --- | --- |
| `pw_{credential.id}` | 비밀번호 평문 |
| `cf_{field.id}` | 커스텀 필드 값 평문 |

## 정합성 규칙 (PRD 13)

- 계정 삭제 시: SwiftData에서 제거 + `passwordRef` 및 모든 `valueRef`를 Keychain에서 삭제.
- 커스텀 필드 삭제 시: 메타 제거 + `valueRef` Keychain 삭제.
- 조회 실패(메타는 있는데 Keychain 값 없음) 시: 사용자에게 안내, 평문 추측 금지.

## UserDefaults — 설정 (PRD 9.4)

| 키(`SettingsKey`) | 기본값 |
| --- | --- |
| isAppLockEnabled | false |
| clipboardExpirySec | 60 |
| sortMode | "favoriteRecent" |
