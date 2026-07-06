import SwiftData
import SwiftUI

/// 상세 화면 — 아이덴티티 + 필드 카드(시크릿 블러 + 눈 힌트) + 필드별 복사 + 삭제. Design.md 2.3.
/// 값 처리는 DetailViewModel로 위임하고 여기서는 표시·전이만 담당한다.
struct CredentialDetailView: View {
    let credential: Credential

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var vm: DetailViewModel
    @State private var isEditingPresented = false
    @State private var showDeleteDialog = false

    init(credential: Credential) {
        self.credential = credential
        _vm = State(initialValue: DetailViewModel(credential: credential))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                identitySection
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                if !vm.fieldItems.isEmpty {
                    fieldsCard
                }

                deleteButton
                    .padding(.top, 12)

                footerCaption
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, MASpacing.screenHorizontal)
        }
        .background(MAColor.appBackground.ignoresSafeArea())
        .navigationTitle(credential.serviceName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(MAColor.interactiveText)
        .toolbar { toolbarContent }
        .onDisappear { vm.resetReveal() }
        .sheet(isPresented: $isEditingPresented) {
            AddEditView(editing: vm.credential)
        }
        .overlay {
            MAConfirmDialog(
                isPresented: $showDeleteDialog,
                title: "이 계정을 삭제할까요?",
                message: "삭제하면 되돌릴 수 없어요.",
                onConfirm: {
                    vm.delete(context: context)
                    dismiss()
                }
            )
        }
    }

    // MARK: - 툴바

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("편집") { isEditingPresented = true }
                .font(MAType.barButtonStrong)
        }
    }

    // MARK: - 아이덴티티

    private var identitySection: some View {
        VStack(spacing: 10) {
            AvatarView(initial: vm.credential.initial, colorHex: vm.credential.colorHex, size: 62)

            Text(vm.credential.serviceName)
                .font(MAType.detailTitle)
                .foregroundStyle(MAColor.ink)

            if let url = vm.credential.urlString, !url.isEmpty {
                Text(url)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MAColor.interactiveText)
            }

            HStack(spacing: 8) {
                MAFavoriteChip(isOn: $vm.isFavorite)
                    .onChange(of: vm.isFavorite) { vm.saveFavorite(context: context) }
                MATimestampChip(text: RelativeTime.subtitle(for: vm.credential))
            }
            .padding(.top, 2)
        }
    }

    // MARK: - 필드 카드

    private var fieldsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.fieldItems.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(MAColor.divider)
                        .frame(height: 0.5)
                        .padding(.leading, MASpacing.rowHorizontal)
                }
                DetailFieldRow(
                    item: item,
                    isRevealed: vm.revealedFields.contains(item.id),
                    onReveal: { vm.reveal(id: item.id) }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: MARadius.card, style: .continuous)
                .fill(MAColor.card)
        )
    }

    // MARK: - 삭제 버튼

    private var deleteButton: some View {
        Button { showDeleteDialog = true } label: {
            Text("계정 삭제")
                .font(MAType.barButtonStrong)
                .foregroundStyle(MAColor.destructive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MASpacing.rowVertical)
                .background(
                    RoundedRectangle(cornerRadius: MARadius.card, style: .continuous)
                        .fill(MAColor.card)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 푸터 캡션

    private var footerCaption: some View {
        Text("비밀번호와 민감 필드는 기기 Keychain에 암호화 저장됩니다")
            .font(MAType.caption)
            .foregroundStyle(MAColor.caption)
            .multilineTextAlignment(.center)
            .padding(.horizontal, MASpacing.screenHorizontal)
    }
}

/// 필드 카드 한 행 — 라벨 + 값(kind별 스타일) + 복사 버튼. Design.md 2.3.
private struct DetailFieldRow: View {
    let item: DetailViewModel.FieldItem
    let isRevealed: Bool
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: MASpacing.gap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(MAType.fieldLabel)
                    .foregroundStyle(MAColor.fieldLabel)
                valueText
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            CopyButton(action: {})
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, MASpacing.rowVertical)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.kind == .secret, !isRevealed { onReveal() }
        }
    }

    @ViewBuilder
    private var valueText: some View {
        switch item.kind {
        case .secret:
            Text(item.value)
                .font(MAType.secretValue)
                .foregroundStyle(MAColor.ink)
                .lineLimit(1)
                .blur(radius: isRevealed ? 0 : 5)
                .overlay(alignment: .trailing) {
                    if !isRevealed {
                        Image(systemName: "eye")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MAColor.secondary)
                    }
                }
                .animation(MAMotion.reveal, value: isRevealed)
        case .link:
            Text(item.value)
                .font(MAType.fieldValue)
                .foregroundStyle(MAColor.interactiveText)
                .lineLimit(1)
        case .plain:
            Text(item.value)
                .font(MAType.fieldValue)
                .foregroundStyle(MAColor.ink)
        }
    }
}

// MARK: - Preview

@MainActor
private func detailPreviewContainer(_ build: (ModelContext) -> Credential) -> (ModelContainer, Credential) {
    do {
        let container = try ModelContainer(
            for: Credential.self, CustomField.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let cred = build(container.mainContext)
        return (container, cred)
    } catch {
        fatalError("Preview ModelContainer 생성 실패: \(error)")
    }
}

#Preview("풍부한 계정") {
    let (container, cred) = detailPreviewContainer { context in
        let cred = Credential(
            serviceName: "네이버",
            username: "juhan@naver.com",
            passwordRef: "preview-pw",
            memo: "복구 이메일은 gmail 쪽",
            urlString: "https://naver.com",
            colorHex: "#03C75A",
            isFavorite: true,
            updatedAt: .now.addingTimeInterval(-3600 * 24 * 3)
        )
        context.insert(cred)
        return cred
    }
    return NavigationStack {
        CredentialDetailView(credential: cred)
    }
    .modelContainer(container)
}

#Preview("최소 계정") {
    let (container, cred) = detailPreviewContainer { context in
        let cred = Credential(
            serviceName: "Steam",
            username: "player_one",
            passwordRef: "preview-pw2",
            colorHex: "#1B2838"
        )
        context.insert(cred)
        return cred
    }
    return NavigationStack {
        CredentialDetailView(credential: cred)
    }
    .modelContainer(container)
}
