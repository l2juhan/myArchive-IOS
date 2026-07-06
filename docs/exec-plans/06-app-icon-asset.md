# 06 앱 아이콘 에셋 (squircle + 열쇠)

- 이슈: #6  ·  PRD: chore  ·  마일스톤: M1
- 상태: done

## 목표
1024×1024 마스터 앱 아이콘 PNG를 프로그래매틱하게 생성해 `Assets.xcassets/AppIcon.appiconset`에 반영한다.
모티프: 인디고 그라데이션(#6A6BD0→#4647AE→#36368A, 좌상→우하) 배경 위 흰 열쇠 글리프.

## 작업 분해
### UI (myarchive-ui)
- [x] Python 스크립트로 1024×1024 PNG 생성 (그라데이션 배경 + 열쇠 글리프)
- [x] `AppIcon.appiconset/AppIcon-1024.png` 배치
- [x] `Contents.json`에 filename 필드 추가

### Logic (myarchive-logic)
- 없음 (에셋 전용 작업)

### 검증 (myarchive-qa)
- [x] `xcodegen generate` 경고 없이 통과
- [x] SwiftLint 클린
- [ ] 실기기에서 홈 화면·설정 아이콘 표시 확인 (수동)

## 의존성
Python 3 + Pillow(또는 macOS 내장 `sips`/CoreGraphics Swift script). Pillow 없으면 Swift 스크립트로 폴백.

## 완료 조건
- `AppIcon.appiconset/` 안에 `AppIcon-1024.png`(1024×1024, PNG) 존재
- `Contents.json` images 항목에 `"filename": "AppIcon-1024.png"` 기재
- `xcodegen generate` 후 빌드 경고 없음 (CI 기준: `CODE_SIGNING_ALLOWED=NO`)
- 홈 화면·설정 아이콘이 인디고 그라데이션 + 열쇠로 표시 (실기기 수동 확인)

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
