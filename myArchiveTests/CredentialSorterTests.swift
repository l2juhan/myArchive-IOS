import XCTest
@testable import myArchive

/// CredentialSorter.sections(_:mode:isSearching:) 검증.
/// 순수 정렬·섹션 로직만 다루므로 ModelContainer 없이 @Model 인스턴스를 생성해 테스트한다.
final class CredentialSorterTests: XCTestCase {
    /// 고정 기준 시각 — 상대적 createdAt/updatedAt 계산용.
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeCredential(
        name: String,
        isFavorite: Bool = false,
        created: Date,
        updated: Date? = nil
    ) -> Credential {
        Credential(
            serviceName: name,
            username: "\(name)@example.com",
            passwordRef: "pw_\(name)",
            isFavorite: isFavorite,
            createdAt: created,
            updatedAt: updated
        )
    }

    /// 기본 모드: 즐겨찾기 섹션 우선 + 각 섹션 내 활동순(updatedAt ?? createdAt) 내림차순.
    func testFavoriteRecentSectionsAndOrder() {
        let favOld = makeCredential(name: "Apple", isFavorite: true, created: base)
        let favNew = makeCredential(name: "Google", isFavorite: true, created: base.addingTimeInterval(1000))
        // updatedAt이 createdAt을 덮어쓰는지: 오래 전 생성됐지만 최근 수정 → 활동순 상위.
        let otherRecent = makeCredential(
            name: "Naver",
            created: base.addingTimeInterval(-10000),
            updated: base.addingTimeInterval(5000)
        )
        let otherStale = makeCredential(name: "Kakao", created: base.addingTimeInterval(2000))

        let sections = CredentialSorter.sections(
            [favOld, otherStale, favNew, otherRecent],
            mode: .favoriteRecent
        )

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].title, "즐겨찾기")
        XCTAssertEqual(sections[1].title, "전체")
        // 즐겨찾기: 활동순 내림차순 → Google(신규) 먼저.
        XCTAssertEqual(sections[0].items.map(\.serviceName), ["Google", "Apple"])
        // 전체: Naver(updatedAt 5000) > Kakao(createdAt 2000).
        XCTAssertEqual(sections[1].items.map(\.serviceName), ["Naver", "Kakao"])
    }

    /// 즐겨찾기가 없으면 "전체" 단일 섹션만 남는다.
    func testFavoriteRecentWithoutFavorites() {
        let a = makeCredential(name: "Apple", created: base)
        let b = makeCredential(name: "Google", created: base.addingTimeInterval(1000))

        let sections = CredentialSorter.sections([a, b], mode: .favoriteRecent)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "전체")
    }

    /// 이름순 모드: 즐겨찾기 우선 없이 serviceName 오름차순 단일 섹션.
    func testNameModeSingleSectionAscending() {
        let fav = makeCredential(name: "Zulu", isFavorite: true, created: base.addingTimeInterval(9999))
        let mid = makeCredential(name: "Mike", created: base)
        let first = makeCredential(name: "Alpha", created: base)

        let sections = CredentialSorter.sections([fav, mid, first], mode: .name)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "이름순")
        // 즐겨찾기(Zulu)여도 이름순에서는 우선되지 않는다.
        XCTAssertEqual(sections[0].items.map(\.serviceName), ["Alpha", "Mike", "Zulu"])
    }

    /// 검색 모드: mode와 무관하게 단일 "검색 결과" 섹션, 활동순.
    func testSearchingSingleSection() {
        let a = makeCredential(name: "Apple", isFavorite: true, created: base)
        let b = makeCredential(name: "Google", created: base.addingTimeInterval(1000))

        let sections = CredentialSorter.sections([a, b], mode: .favoriteRecent, isSearching: true)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "검색 결과")
        // 활동순 내림차순: Google(신규) 먼저.
        XCTAssertEqual(sections[0].items.map(\.serviceName), ["Google", "Apple"])
    }
}
