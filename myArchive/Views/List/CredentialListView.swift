import SwiftData
import SwiftUI

/// 메인 목록 — 기본 진입 화면(Design.md 2.2 / 3.2 / 3.3).
/// 커스텀 고정 헤더(워드마크+액션+검색바) + 흰 카드 섹션 리스트 + 빈 상태/검색 0건.
/// 인메모리 검색(PRD 6.1) + 즐겨찾기/전체 섹션 + 정렬은 기성 서비스(CredentialSorter)에 위임.
struct CredentialListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var credentials: [Credential]
    @AppStorage(SettingsKey.sortMode) private var sortModeRaw = SortMode.favoriteRecent.rawValue

    @State private var query: String
    @State private var showingAdd = false
    @State private var headerHeight: CGFloat = 0

    /// 검색어 초기값 주입(주로 #Preview 검색 0건 상태 재현용).
    init(query: String = "") {
        _query = State(initialValue: query)
    }

    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .favoriteRecent }
    private var isSearching: Bool { !query.isEmpty }

    /// 검색 필터 — serviceName/username 부분 일치(대소문자 무시). Design.md 3.2.
    private var filtered: [Credential] {
        guard isSearching else { return credentials }
        let q = query.lowercased()
        return credentials.filter {
            $0.serviceName.lowercased().contains(q) || $0.username.lowercased().contains(q)
        }
    }

    /// 섹션 구성 — 검색 중엔 단일 "검색 결과", 그 외엔 즐겨찾기/전체 또는 이름순.
    private var sections: [CredentialSorter.ListSection] {
        CredentialSorter.sections(filtered, mode: sortMode, isSearching: isSearching)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MAColor.appBackground.ignoresSafeArea()

                scrollContent
                    .ignoresSafeArea(.container, edges: .top)

                header
                    .ignoresSafeArea(.container, edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let cred = credentials.first(where: { $0.id == id }) {
                    CredentialDetailView(credential: cred)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditView()
            }
        }
        .tint(MAColor.interactiveText)
    }

    // MARK: - 본문

    @ViewBuilder
    private var scrollContent: some View {
        if credentials.isEmpty {
            emptyState
        } else if isSearching, filtered.isEmpty {
            noResultState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sections, id: \.title) { section in
                        sectionHeader(section.title)
                        card(for: section.items)
                    }
                }
                .padding(.top, headerHeight)
                .padding(.bottom, MASpacing.sectionHeaderTop)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(MAType.sectionHeader)
            .foregroundStyle(MAColor.secondary)
            .padding(.leading, MASpacing.cardMargin + MASpacing.rowHorizontal)
            .padding(.top, MASpacing.sectionHeaderTop)
            .padding(.bottom, MASpacing.sectionHeaderBottom)
    }

    /// 한 섹션의 행들을 흰 카드 하나에 쌓고, 행 사이만 0.5px 헤어라인(아바타 우측 인셋부터).
    private func card(for items: [Credential]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, cred in
                NavigationLink(value: cred.id) {
                    CredentialRow(credential: cred) { toggleFavorite(cred) }
                }
                .buttonStyle(.plain)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(MAColor.divider)
                        .frame(height: 0.5)
                        .padding(.leading, dividerInset)
                }
            }
        }
        .background(MAColor.card)
        .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))
        .padding(.horizontal, MASpacing.cardMargin)
    }

    /// 헤어라인은 아바타 우측부터 시작(행 좌패딩 + 아바타 + gap).
    private var dividerInset: CGFloat {
        MASpacing.rowHorizontal + CredentialRow.avatarSize + MASpacing.gap
    }

    // MARK: - 고정 헤더

    private var header: some View {
        VStack(spacing: MASpacing.rowVertical) {
            HStack(spacing: 0) {
                Text("myArchive")
                    .font(MAType.wordmark)
                    .foregroundStyle(MAColor.ink)
                Spacer()
                HStack(spacing: 10) {
                    NavigationLink { SettingsView() } label: {
                        headerIcon("gearshape")
                    }
                    Button { showingAdd = true } label: {
                        headerIcon("plus")
                    }
                    .buttonStyle(.plain)
                }
            }

            if !credentials.isEmpty {
                searchBar
            }
        }
        .padding(.horizontal, MASpacing.screenHorizontal)
        .padding(.top, MASpacing.headerTop)
        .padding(.bottom, MASpacing.rowVertical)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(MAColor.divider)
                .frame(height: 0.5)
        }
        .background(.ultraThinMaterial)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: HeaderHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
    }

    /// 기어/플러스 38원형 — Fill 배경 + 회색 아이콘(Design.md 2.2).
    private func headerIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(MAColor.iconGray)
            .frame(width: 38, height: 38)
            .background(MAColor.fill)
            .clipShape(Circle())
    }

    private var searchBar: some View {
        HStack(spacing: MASpacing.gap) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MAColor.placeholder)

            TextField("서비스 또는 아이디 검색", text: $query)
                .font(MAType.searchInput)
                .foregroundStyle(MAColor.ink)
                .tint(MAColor.primary)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if isSearching {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(MAColor.placeholder)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .frame(height: 44)
        .background(MAColor.fill)
        .clipShape(RoundedRectangle(cornerRadius: MARadius.fill, style: .continuous))
    }

    // MARK: - 빈 상태 / 검색 0건

    /// 계정 0개(Design.md 2.2 빈 상태).
    private var emptyState: some View {
        VStack(spacing: MASpacing.cardMargin) {
            RoundedRectangle(cornerRadius: MARadius.card, style: .continuous)
                .fill(MAColor.fill)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "key.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(MAColor.secondary)
                )

            VStack(spacing: 6) {
                Text("아직 저장된 계정이 없어요")
                    .font(MAType.emptyTitle)
                    .foregroundStyle(MAColor.ink)
                Text("자주 쓰는 계정을 추가해\n한곳에서 안전하게 관리하세요.")
                    .font(MAType.caption)
                    .foregroundStyle(MAColor.secondary)
                    .multilineTextAlignment(.center)
            }

            Button { showingAdd = true } label: {
                Text("+ 새 계정 추가")
                    .font(MAType.rowTitle)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MASpacing.screenHorizontal)
                    .padding(.vertical, MASpacing.rowVertical)
                    .background(MAColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: MARadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, MASpacing.screenHorizontal)
    }

    /// 검색 결과 0건(Design.md 2.2).
    private var noResultState: some View {
        VStack(spacing: MASpacing.cardMargin) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(MAColor.placeholder)
            Text("'\(query)' 검색 결과가 없어요")
                .font(MAType.rowTitle)
                .foregroundStyle(MAColor.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, headerHeight)
        .padding(.horizontal, MASpacing.screenHorizontal)
    }

    // MARK: - 액션

    /// 별 토글 — isFavorite만 뒤집고 저장. updatedAt은 건드리지 않는다(즐겨찾기=정렬 플래그).
    /// Design.md 3.3/3.4 · exec-plan 확정 사항. @Query 갱신으로 그룹 자동 재배치.
    private func toggleFavorite(_ cred: Credential) {
        cred.isFavorite.toggle()
        try? modelContext.save()
    }
}

/// 고정 헤더 높이 측정 키 — 스크롤 본문 상단 인셋 계산용.
private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

@MainActor
private func listPreviewContainer(_ build: (ModelContext) -> Void) -> ModelContainer {
    do {
        let container = try ModelContainer(
            for: Credential.self, CustomField.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        build(container.mainContext)
        return container
    } catch {
        fatalError("Preview ModelContainer 생성 실패: \(error)")
    }
}

private func insertSampleData(into context: ModelContext) {
    let samples: [Credential] = [
        Credential(
            serviceName: "네이버",
            username: "naver_id",
            passwordRef: "r1",
            colorHex: "#03C75A",
            isFavorite: true,
            updatedAt: Date().addingTimeInterval(-8 * 60)
        ),
        Credential(
            serviceName: "우리은행",
            username: "woori_id",
            passwordRef: "r2",
            colorHex: "#3182F6",
            isFavorite: true,
            updatedAt: Date().addingTimeInterval(-2 * 3600)
        ),
        Credential(
            serviceName: "카카오",
            username: "kakao_id",
            passwordRef: "r3",
            colorHex: "#FEE500",
            createdAt: Date().addingTimeInterval(-35 * 60)
        ),
        Credential(
            serviceName: "토스",
            username: "toss_id",
            passwordRef: "r4",
            colorHex: "#3182F6",
            updatedAt: Date().addingTimeInterval(-5 * 3600)
        ),
        Credential(
            serviceName: "쿠팡",
            username: "coupang_id",
            passwordRef: "r5",
            colorHex: "#E4002B",
            createdAt: Date().addingTimeInterval(-1 * 86400)
        )
    ]
    samples.forEach { context.insert($0) }
}

#Preview("데이터 있음") {
    CredentialListView()
        .modelContainer(listPreviewContainer(insertSampleData))
}

#Preview("빈 상태") {
    CredentialListView()
        .modelContainer(listPreviewContainer { _ in })
}

#Preview("검색 0건") {
    CredentialListView(query: "없는검색어")
        .modelContainer(listPreviewContainer(insertSampleData))
}
