import SwiftData
import SwiftUI

/// 메인 목록 — 기본 진입 화면(Design.md 2.2 / 3.2 / 3.3).
/// 인메모리 검색(PRD 6.1) + 즐겨찾기/전체 섹션 + 정렬.
/// 행·빈 상태·검색 0건의 시각 디테일은 M1/M6에서 마감한다. 현재는 동작 골격.
struct CredentialListView: View {
    @Query private var credentials: [Credential]
    @AppStorage(SettingsKey.sortMode) private var sortModeRaw = SortMode.favoriteRecent.rawValue

    @State private var query = ""
    @State private var showingAdd = false

    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .favoriteRecent }

    /// 검색 필터 — serviceName/username 부분 일치(대소문자 무시). Design.md 3.2.
    private var filtered: [Credential] {
        guard !query.isEmpty else { return credentials }
        let q = query.lowercased()
        return credentials.filter {
            $0.serviceName.lowercased().contains(q) || $0.username.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if credentials.isEmpty {
                    ContentUnavailableView(
                        "아직 저장된 계정이 없어요",
                        systemImage: "key.fill",
                        description: Text("오른쪽 위 + 버튼으로 첫 계정을 추가하세요.")
                    )
                } else {
                    List {
                        ForEach(CredentialSorter.sections(filtered, mode: sortMode), id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.items) { cred in
                                    NavigationLink(value: cred.id) {
                                        rowLabel(cred)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("myArchive")
            .searchable(text: $query, prompt: "서비스 또는 아이디 검색")
            .navigationDestination(for: UUID.self) { id in
                if let cred = credentials.first(where: { $0.id == id }) {
                    CredentialDetailView(credential: cred)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditView()
            }
        }
        .tint(MAColor.interactiveText)
    }

    private func rowLabel(_ cred: Credential) -> some View {
        HStack(spacing: MASpacing.gap) {
            AvatarView(initial: cred.initial, colorHex: cred.colorHex, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(cred.serviceName).font(MAType.rowTitle).foregroundStyle(MAColor.ink)
                Text(RelativeTime.subtitle(for: cred))
                    .font(MAType.rowSubtitle).foregroundStyle(MAColor.secondaryAlt)
            }
            Spacer()
            Image(systemName: cred.isFavorite ? "star.fill" : "star")
                .foregroundStyle(cred.isFavorite ? MAColor.accent : MAColor.emptyStar)
        }
    }
}

#Preview {
    CredentialListView()
        .modelContainer(for: [Credential.self, CustomField.self], inMemory: true)
}
