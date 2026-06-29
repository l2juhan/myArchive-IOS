import SwiftUI

/// 시맨틱 색상 토큰 — Design.md 1.1 단일 소스.
/// HTML/CSS를 이식하지 않고 확정 HEX 값을 SwiftUI 상수로 재현한다.
enum MAColor {
    // Primary (Indigo)
    static let primary = Color(hex: "#4647AE") // 솔리드 주요 버튼, 색상 선택 링, Face ID 펄스
    static let primaryPressed = Color(hex: "#393A90") // 주요 버튼 눌림

    static let interactiveText = Color(hex: "#6D94C5") // 내비 텍스트, URL 링크, 토글, '+ 필드 추가'

    // Accent (Orange)
    static let accent = Color(hex: "#FF5722") // 필드별 복사 아이콘, 채워진 별
    static let favChipBG = Color(hex: "#FFE7E0") // 상세 즐겨찾기 활성 칩 배경
    static let favChipText = Color(hex: "#DD451B") // 상세 즐겨찾기 활성 칩 텍스트

    // Surfaces
    static let appBackground = Color(hex: "#E8EDF2") // 모든 화면 캔버스
    static let card = Color(hex: "#FFFFFF") // 카드/행 컨테이너 (radius 16)
    static let fill = Color(hex: "#ECEEF2") // 검색 바, 기어 버튼
    static let fillPressed = Color(hex: "#DFE3EA")
    static let copyButtonBG = Color(hex: "#F1F3F7") // 복사 버튼 바탕
    static let segmentTrack = Color(hex: "#E9EBF0") // 세그먼트 트랙
    static let chipBG = Color(hex: "#EEF0F4") // 타임스탬프 칩

    // Text
    static let ink = Color(hex: "#303841") // 제목/본문/값
    static let secondary = Color(hex: "#8B93A3") // 섹션 헤더, 보조
    static let secondaryAlt = Color(hex: "#9099A8") // 타임스탬프, 필드 라벨
    static let fieldLabel = Color(hex: "#6B7280")
    static let placeholder = Color(hex: "#AAB0BC")
    static let caption = Color(hex: "#9AA1B0")
    static let captionAlt = Color(hex: "#AEB4C0")

    // Lines / States
    static let divider = Color(red: 60 / 255, green: 67 / 255, blue: 80 / 255, opacity: 0.09)
    static let emptyStar = Color(hex: "#CFD3D2")
    static let success = Color(hex: "#1F9D6B") // 복사 성공 체크, 토스트 배지
    static let destructive = Color(hex: "#E5484D") // 삭제, 커스텀 필드 제거
    static let toastSurface = Color(hex: "#1B2330") // 토스트 배경
    static let toastSub = Color(hex: "#AAB2C0")

    // 아이콘 톤
    static let iconGray = Color(hex: "#5F6776") // 기어/플러스 아이콘
    static let toggleOff = Color(hex: "#CDD2DB") // 토글 꺼짐
}

/// 계정별 아바타 팔레트 — Design.md 1.2.
enum MAAvatarPalette {
    /// 사용자 선택 9색 프리셋 (라벨 순서대로). 토스 파랑이 신규 계정 기본값.
    static let presets: [(hex: String, label: String)] = [
        ("#E4002B", "쿠팡"),
        ("#FF7A00", "알바몬"),
        ("#FEE500", "카카오"),
        ("#03C75A", "네이버"),
        ("#3182F6", "토스"), // 신규 계정 기본값
        ("#1B2838", "스팀"),
        ("#5865F2", "디스코드"),
        ("#FFFFFF", "흰색"),
        ("#000000", "검정")
    ]

    static let defaultHex = "#3182F6" // 토스 파랑 — 신규 계정 기본

    /// 밝은 스와치는 체크/이니셜을 잉크색으로(가독성). Design.md 1.2.
    static let lightSwatches: Set<String> = ["#FFFFFF", "#FEE500"]

    /// 색 미지정 시 서비스명 해시로 자동 배정하는 폴백 팔레트. Design.md 1.2.
    static let fallback = [
        "#1F9D6B", "#E0A32B", "#3B6FE0", "#4647AE", "#D6455D",
        "#C2342F", "#2A3550", "#0F9AA8", "#7B54D6", "#2BB6C4"
    ]

    /// 서비스명 해시 기반 폴백 색 선택 (정렬·검색엔 영향 없음, 순수 시각 식별).
    static func fallbackHex(for serviceName: String) -> String {
        let sum = serviceName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return fallback[sum % fallback.count]
    }

    /// 아바타 배경 위 전경(이니셜/체크) 색 — 밝은 색이면 잉크, 아니면 흰색.
    static func foreground(on hex: String) -> Color {
        lightSwatches.contains(hex.uppercased()) ? MAColor.ink : .white
    }
}
