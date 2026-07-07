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

    // MARK: 동일 활동시각 tie-break

    /// 동일 activityDate를 가진 원소들의 순서 — **현재 구현 동작 문서화**.
    /// 현재 `byActivity`는 `$0.activityDate > $1.activityDate`만 비교하고 serviceName
    /// tie-break을 하지 않는다. 따라서 동일 시각의 상대 순서는 Swift `sorted`의 안정성
    /// (Swift 5부터 stable sort 보장 → 입력 순서 보존)에 의존하며, serviceName 오름차순으로
    /// 재배열되지 않는다. 구현 변경은 범위 밖이므로, 여기서는 결정적으로 통과하도록
    /// "같은 시각 그룹에 두 원소가 모두 포함되는지"를 집합으로 검증한다.
    func testEqualActivityDateKeepsBothItems() {
        // 같은 시각(base)을 공유하는 두 원소 — serviceName은 역순으로 입력.
        let zulu = makeCredential(name: "Zulu", created: base)
        let alpha = makeCredential(name: "Alpha", created: base)
        // 이들보다 확실히 오래된 원소 하나(뒤쪽에 위치해야 함).
        let older = makeCredential(name: "Bravo", created: base.addingTimeInterval(-1000))

        let sections = CredentialSorter.sections([zulu, alpha, older], mode: .favoriteRecent)

        XCTAssertEqual(sections.count, 1)
        let names = sections[0].items.map(\.serviceName)
        // 동일 시각 그룹(Zulu·Alpha)이 older(Bravo)보다 앞선다 — 활동순 자체는 결정적.
        XCTAssertEqual(Set(names.prefix(2)), ["Zulu", "Alpha"])
        XCTAssertEqual(names.last, "Bravo")
        // 참고: serviceName 오름차순 tie-break은 미구현이라 prefix가 ["Alpha","Zulu"]로
        // 정렬되리라 단정하지 않는다(입력 순서 보존 = ["Zulu","Alpha"]가 현재 관찰 동작).
    }

    // MARK: 빈 입력 0건 처리

    /// favoriteRecent: 즐겨찾기가 없으므로 "전체" 섹션 1개에 items 0건.
    func testEmptyInputFavoriteRecent() {
        let sections = CredentialSorter.sections([], mode: .favoriteRecent)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "전체")
        XCTAssertTrue(sections[0].items.isEmpty)
    }

    /// name: "이름순" 섹션 1개에 items 0건.
    func testEmptyInputNameMode() {
        let sections = CredentialSorter.sections([], mode: .name)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "이름순")
        XCTAssertTrue(sections[0].items.isEmpty)
    }

    /// 검색 중 빈 입력: "검색 결과" 섹션 1개에 items 0건.
    func testEmptyInputSearching() {
        let sections = CredentialSorter.sections([], mode: .favoriteRecent, isSearching: true)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title, "검색 결과")
        XCTAssertTrue(sections[0].items.isEmpty)
    }
}
