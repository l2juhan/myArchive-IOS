import SwiftUI

/// 타이포그래피 토큰 — Design.md 1.3.
/// 폰트는 시스템(SF Pro / Apple SD Gothic Neo)으로 대체하되 size/weight 위계를 따른다.
/// 시크릿 값·비밀번호 입력은 모노스페이스로 표시한다.
enum MAType {
    static let wordmark = Font.system(size: 30, weight: .heavy) // myArchive 헤더
    static let brand = Font.system(size: 24, weight: .heavy) // 마이아카이브(잠금)
    static let detailTitle = Font.system(size: 22, weight: .bold) // 상세 서비스명
    static let emptyTitle = Font.system(size: 18, weight: .bold) // 빈 상태 제목(목록 2.2)
    static let sectionHeader = Font.system(size: 13, weight: .semibold)
    static let rowTitle = Font.system(size: 16, weight: .semibold)
    static let rowSubtitle = Font.system(size: 13, weight: .medium) // 타임스탬프
    static let searchInput = Font.system(size: 16, weight: .medium)
    static let fieldLabel = Font.system(size: 12, weight: .semibold)
    static let fieldValue = Font.system(size: 16, weight: .medium)
    static let barButton = Font.system(size: 16, weight: .medium)
    static let barButtonStrong = Font.system(size: 16, weight: .semibold)
    static let toastTitle = Font.system(size: 14, weight: .semibold)
    static let toastSub = Font.system(size: 12, weight: .medium)
    static let caption = Font.system(size: 12, weight: .medium)

    /// 시크릿 값(아이디·비밀번호·커스텀)은 모노스페이스.
    static let secretValue = Font.system(size: 16, weight: .medium, design: .monospaced)
}

/// 라운드 / 간격 토큰 — Design.md 1.4.
enum MARadius {
    static let card: CGFloat = 16
    static let fill: CGFloat = 12
    static let listAvatar: CGFloat = 12 // 42px 아바타
    static let detailAvatar: CGFloat = 17 // 62px 아바타
    static let button: CGFloat = 12 // 10~14 범위
    static let copyButton: CGFloat = 10
    static let segment: CGFloat = 7
    static let modal: CGFloat = 20
    static let toast: CGFloat = 14
    static let togglePill: CGFloat = 31
}

enum MASpacing {
    static let headerTop: CGFloat = 54 // 상태바 여백
    static let screenHorizontal: CGFloat = 20
    static let cardMargin: CGFloat = 16 // 14~16
    static let rowVertical: CGFloat = 12 // 11~14
    static let rowHorizontal: CGFloat = 14 // 행 좌우 패딩(11~14)
    static let sectionHeaderTop: CGFloat = 16 // 섹션 헤더 상(14~18)
    static let sectionHeaderBottom: CGFloat = 7 // 섹션 헤더 하
    static let fieldRow: CGFloat = 12
    static let gap: CGFloat = 11 // 9~13
}

/// 모션 토큰 — Design.md 1.5.
enum MAMotion {
    static let toast = Animation.easeOut(duration: 0.26) // translateY 14→0
    static let modal = Animation.easeInOut(duration: 0.18)
    static let pop = Animation.easeOut(duration: 0.20) // scale .93→1
    static let reveal = Animation.easeInOut(duration: 0.20)
    static let segment = Animation.easeInOut(duration: 0.18)
    static let pulse = Animation.easeInOut(duration: 1.9).repeatForever(autoreverses: false)
}
