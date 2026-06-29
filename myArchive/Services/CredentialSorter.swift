import Foundation

/// 목록 정렬·섹션 분리 — F-9 / F-14 (Design.md 3.3, PRD 9.4).
enum CredentialSorter {
    struct ListSection {
        let title: String
        let items: [Credential]
    }

    /// 검색 중에는 단일 "검색 결과" 섹션, 이름순은 단일 "이름순" 섹션,
    /// 기본 모드는 즐겨찾기/전체 분리(Design.md 2.2 / 3.2).
    static func sections(_ creds: [Credential], mode: SortMode, isSearching: Bool = false) -> [ListSection] {
        if isSearching {
            return [ListSection(title: "검색 결과", items: byActivity(creds))]
        }
        switch mode {
        case .name:
            return [ListSection(title: "이름순", items: byName(creds))]
        case .favoriteRecent:
            let favorites = byActivity(creds.filter(\.isFavorite))
            let others = byActivity(creds.filter { !$0.isFavorite })
            var result: [ListSection] = []
            if !favorites.isEmpty { result.append(ListSection(title: "즐겨찾기", items: favorites)) }
            result.append(ListSection(title: "전체", items: others))
            return result
        }
    }

    /// 최근 활동순(updatedAt ?? createdAt 내림차순).
    private static func byActivity(_ creds: [Credential]) -> [Credential] {
        creds.sorted { $0.activityDate > $1.activityDate }
    }

    /// serviceName 오름차순(한국어 로케일).
    private static func byName(_ creds: [Credential]) -> [Credential] {
        creds.sorted { $0.serviceName.localizedCompare($1.serviceName) == .orderedAscending }
    }
}
