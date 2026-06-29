# 확정 폴더 구조

```
myArchive-IOS/
├── CLAUDE.md                  # 하네스 규칙 + docs 매니페스트 + 승인 게이트
├── project.yml                # XcodeGen 단일 소스 (.xcodeproj 생성)
├── .swiftlint.yml             # 린트 규칙(보안 커스텀 규칙 포함)
├── .swiftformat               # 포맷 규칙
├── .gitignore
├── .githooks/                 # git core.hooksPath
│   ├── pre-commit             # exec-plan 스테이징 + SwiftLint error 차단
│   └── pre-push               # view-inventory 신선도 + doc-sync-map
├── scripts/
│   └── gen-view-inventory.sh  # generated 문서 생성기
├── .claude/
│   ├── settings.json          # PostToolUse(format) · PreToolUse(git 게이트)
│   ├── doc-sync-map.json      # 코드↔문서 동기화 규칙
│   ├── hooks/                 # 훅 실행 스크립트
│   ├── agents/                # myarchive-ui / -logic / -qa
│   ├── skills/                # 오케스트레이터 + 도메인 + 워크플로 스킬
│   └── commands/              # /review /gc /health /quality /docs-sync
├── myArchive/                 # 앱 소스
│   ├── App/                   # 진입점·루트(잠금 게이트)
│   ├── DesignSystem/          # 색·타이포·라운드·간격·모션 토큰
│   ├── Models/                # SwiftData @Model + 설정 enum
│   ├── Services/              # Keychain·Auth·Clipboard·Sorter·RelativeTime
│   ├── ViewModels/            # 화면별 상태(MVVM)
│   ├── Views/                 # Lock/List/Detail/AddEdit/Settings/Components
│   └── Resources/             # Assets.xcassets (AppIcon, AccentColor)
├── myArchiveTests/            # 단위 테스트
├── __tests__/structural/      # 구조 제약 검증
└── docs/                      # 프로젝트 문서 (매니페스트는 CLAUDE.md)
    ├── design-docs/           # core-beliefs · feedback-log
    ├── exec-plans/            # 이슈별 작업 계획(머지 시 삭제)
    ├── generated/             # view-inventory (자동 생성)
    └── references/            # PRD·Design.md·screenshots·keychain-schema (1차 자료)
```

## 레이어 경계 규칙

- `Views/` 와 `DesignSystem/` → **myarchive-ui** 담당. 표시만.
- `Models/` · `Services/` · `ViewModels/` → **myarchive-logic** 담당. 값 처리·보안.
- UI는 시크릿 값을 직접 다루지 않는다. Logic이 제공하는 API를 호출만 한다.
- 외부 라이브러리 없음. Apple 표준 프레임워크(SwiftUI·SwiftData·Security·LocalAuthentication·UIKit 연동)만.
