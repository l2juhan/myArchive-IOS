# myArchive — iOS

빠르고 가벼운 **로컬 전용 iOS 비밀번호 관리 앱**. Swift · SwiftUI · iOS 17+ · SwiftData(메타) · Keychain(시크릿, 방식 B) · LocalAuthentication · MVVM. 외부 라이브러리 없음.

## 시작하기

```bash
brew install xcodegen swiftlint swiftformat   # 도구 (최초 1회)
xcodegen generate                             # project.yml → myArchive.xcodeproj 생성
open myArchive.xcodeproj                       # Xcode에서 실행
```

`.xcodeproj`는 `project.yml`에서 생성되며 git으로 추적하지 않는다. 소스/설정 변경 후 `xcodegen generate`로 재생성한다.

## 프로젝트 구조

```
myArchive/         앱 소스 (App · DesignSystem · Models · Services · ViewModels · Views · Resources)
myArchiveTests/    단위 테스트
docs/              제품/설계 문서 (매니페스트는 CLAUDE.md)
.claude/           Claude Code 하네스 (agents · skills · commands · hooks)
.githooks/         git 게이트 (pre-commit · pre-push)
```

자세한 구조는 `docs/folder-structure.md`, 제품 요구사항은 `docs/references/MyArchive_PRD_v0.5.md`, 디자인은 `docs/references/Design.md` 참조.

## 개발 하네스

작업은 에이전트 팀(`myarchive-ui`/`-logic`/`-qa`)으로 처리하며, edit→commit→review→push→pr→merge 각 시점에 훅(게이트)과 스킬(워커)이 한 쌍으로 동작한다. 규칙·승인 게이트는 `CLAUDE.md` 참조.

- 기능 구현: "myArchive ○○ 구현해" → `myarchive-orchestrator`가 팀 조율
- 점검: `/health` `/quality` `/review` `/gc` `/docs-sync`

## 마일스톤 (PRD 12장)

M1 UI 골격 → M2 메타 영속화 → M3 시크릿 저장 → M4 잠금/설정 → M5 보안 마감 → M6 폴리싱.
현재: 빌드 가능한 골격(디자인 토큰·데이터 모델·서비스·화면 스텁) 완성, 타입체크/lint 통과.
