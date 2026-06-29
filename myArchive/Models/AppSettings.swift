import Foundation

/// 정렬 모드 — F-9 / F-14 (Design.md 3.3).
enum SortMode: String, CaseIterable, Identifiable {
    case favoriteRecent // 기본: 즐겨찾기 우선 → 최근 활동순
    case name // 이름순: 즐겨찾기 우선 없이 serviceName 오름차순

    var id: String { rawValue }
    var label: String { self == .favoriteRecent ? "기본" : "이름순" }
}

/// 클립보드 만료 시간(초) — F-8 (기본 60).
enum ClipboardExpiry: Int, CaseIterable, Identifiable {
    case thirty = 30
    case sixty = 60
    case oneTwenty = 120

    var id: Int { rawValue }
    var label: String { "\(rawValue)초" }
}

/// 앱 설정 — UserDefaults 백업(PRD 9.4). @AppStorage 키와 동일하게 유지한다.
enum SettingsKey {
    static let isAppLockEnabled = "isAppLockEnabled" // 기본 false
    static let clipboardExpirySec = "clipboardExpirySec" // 기본 60
    static let sortMode = "sortMode" // 기본 "favoriteRecent"
}
