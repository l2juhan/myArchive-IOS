# DESIGN_SYSTEM — 토큰 ↔ Design.md 매핑

DesignSystem 코드는 `docs/references/Design.md` 1장의 확정값을 SwiftUI 상수로 재현한 것이다. **Design.md가 단일 소스**이며, 토큰을 바꾸면 이 문서와 Design.md를 함께 본다(doc-sync-map: `design-tokens`).

## 파일 ↔ Design.md 절

| 코드 | Design.md | 내용 |
| --- | --- | --- |
| `DesignSystem/MAColor.swift` (`MAColor`) | 1.1 | 시맨틱 색상 |
| `DesignSystem/MAColor.swift` (`MAAvatarPalette`) | 1.2 | 계정 아바타 9색 + 폴백 해시 |
| `DesignSystem/MAType.swift` (`MAType`) | 1.3 | 타이포 위계 |
| `DesignSystem/MAType.swift` (`MARadius`/`MASpacing`) | 1.4 | 라운드·간격 |
| `DesignSystem/MAType.swift` (`MAMotion`) | 1.5 | 모션 |
| `DesignSystem/Color+Hex.swift` | — | HEX → Color 헬퍼 |

## 사용 규칙

- 색·폰트·라운드·간격·모션을 **하드코딩하지 않는다.** 반드시 토큰을 경유한다.
- 새 값이 필요하면: ① Design.md에 있으면 그 값으로 토큰 추가, ② 없으면 가장 가까운 토큰 재사용 후 exec-plan에 질문.
- 폰트는 시스템(SF Pro / Apple SD Gothic Neo)으로 대체하되 size/weight 위계 유지. 시크릿 값은 모노스페이스(`MAType.secretValue`).
- 라이트 모드 전용. 다크 모드 색 분기를 넣지 않는다(v1.1 이관).

## 아바타 색 규칙 (F-15)

- 신규 계정 기본값: `MAAvatarPalette.defaultHex`(토스 파랑 `#3182F6`).
- 미지정/시드: `MAAvatarPalette.fallbackHex(for:)` — 서비스명 해시.
- 밝은 스와치(흰·노랑)는 이니셜/체크를 잉크색으로(`foreground(on:)`).
- 색은 목록·상세 아바타에만 반영. 정렬·검색에 영향 없음.

## 핵심 토큰 빠른 참조

Primary `#4647AE` · Interactive `#6D94C5` · Accent `#FF5722` · App BG `#E8EDF2` · Card `#FFFFFF` · Ink `#303841` · Success `#1F9D6B` · Destructive `#E5484D` · Toast `#1B2330`. 카드 radius 16 · Fill 12 · 아바타 12/17 · 모달 20.
