---
name: pr-create
description: "품질 점검 통과 후 Pull Request를 만든다. 'PR 만들어', 'PR 올려', 'pull request 생성', '풀리퀘 올려줘' 같은 요청 시 트리거. 먼저 /quality를 선행해 QUALITY_SCORE.md를 확인하고, .github/pull_request_template.md 형식 그대로 본문 초안을 채워 승인받은 뒤 gh pr create로 생성한다. exec-plan과 관련 이슈를 PR에 링크한다."
---

# pr-create

작업을 리뷰 가능한 PR로 올린다. PR은 **외부로 나가는 행위**라 품질 선행 → 초안 → 승인 → 생성의 게이트를 거친다(승인 게이트 3·4).

## 왜

PR 본문이 부실하면 리뷰어가 맥락을 못 잡는다. 변경 요약·검증 내역·스크린샷을 담아야 리뷰가 빠르다. 품질 점수를 먼저 확인해 미달 상태로 올리는 걸 막는다.

## 본문은 `.github/pull_request_template.md`를 따른다 (단일 소스)

PR 본문 형식을 스킬이 임의로 정하지 않는다. 리포의 PR 템플릿이 **단일 소스**다. 매번 `.github/pull_request_template.md`를 읽어 그 섹션 구조(관련 이슈 / 한 줄 요약 / 변경 사항 / 직접 확인하는 법 / 테스트 / 스크린샷 / 리뷰어 참고사항)를 그대로 채운다. 템플릿 상단 주석의 톤 가이드(있으면 `docs/PR-writing-guide.md`)도 따른다.

## 절차

1. **품질 선행** — `/quality`를 돌려 `docs/QUALITY_SCORE.md`를 확인한다. 등급이 기준 미만이면 먼저 개선을 권하고, 강행 시 그 사실을 PR 본문 "리뷰어 참고사항"에 명시한다.
2. **문서 동기화 확인** — docs-sync가 끝났는지(view-inventory 신선, doc-sync-map 경고 없음) 확인한다. 안 됐으면 먼저 docs-sync.
3. **템플릿 로드** — `.github/pull_request_template.md`를 읽는다. 섹션 구조와 `<!-- 주석 -->` 안내를 가져온다.
4. **변경 수집** — base 브랜치 기준으로 `git log {base}..HEAD --oneline`, `git diff --stat {base}..HEAD`로 커밋·변경 규모를 본다. 관련 이슈 번호·exec-plan slug를 찾는다. (base는 아래 "base 브랜치" 참조.)
5. **본문 초안(승인 게이트 3)** — 템플릿 각 섹션을 실제 내용으로 채운다. **섹션을 빼거나 추가하지 않는다.** "관련 이슈"는 `closes #nn`, UI 변경이면 스크린샷 표를 채운다. 빈 섹션은 "해당 없음".
6. **PR 생성(승인 게이트 4)** — 승인 후 `gh pr create --base develop --title ... --body ...` 실행. URL을 보고한다.

## base 브랜치

CLAUDE.md 분기 전략에 따라 **base는 `develop`**(main은 배포 전용)이다. 생성 전 `git branch -a`로 `develop` 존재를 확인하고, 없으면 `git switch -c develop && git push -u origin develop`(승인 후)으로 만들고 진행한다.

## 규칙

- **템플릿 구조를 보존한다.** `.github/pull_request_template.md`가 바뀌면 이 스킬도 자동으로 새 형식을 따른다(매번 읽으므로).
- PR 본문에 "🤖 Generated with Claude Code"를 **넣지 않는다**(글로벌 규칙).
- 작업 브랜치에서 생성한다(base 브랜치에서 직접 PR 금지).
- 시크릿 평문·실제 비밀번호를 본문/스크린샷에 넣지 않는다(보안 앱).
- 승인 전 `gh pr create`를 실행하지 않는다.

## 다음 단계

PR 생성 후 리뷰가 달리면 pr-review-check로 코멘트를 정리한다. 머지는 merge 스킬.
