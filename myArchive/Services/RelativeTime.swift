import Foundation

/// 상대시간 표기 — Design.md 3.4.
/// 규칙: <1분 '방금 전', <60분 'N분 전', <24시간 'N시간 전', <30일 'N일 전', 그 이상 'N주 전'.
enum RelativeTime {
    static func phrase(from date: Date, now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        let minutes = Int(seconds / 60)
        if minutes < 1 { return "방금 전" }
        if minutes < 60 { return "\(minutes)분 전" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)시간 전" }
        let days = hours / 24
        if days < 30 { return "\(days)일 전" }
        return "\(days / 7)주 전"
    }

    /// 행/상세 보조 텍스트: 수정 이력 있으면 "N분 전 수정", 없으면 "N분 전 생성".
    static func subtitle(for credential: Credential, now: Date = .now) -> String {
        let suffix = credential.wasEdited ? "수정" : "생성"
        return "\(phrase(from: credential.activityDate, now: now)) \(suffix)"
    }
}
