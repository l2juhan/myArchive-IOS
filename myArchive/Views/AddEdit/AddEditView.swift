import SwiftData
import SwiftUI

/// 추가/수정 화면 — 기본 정보·색상(F-15)·필드·추가 정보·즐겨찾기(Design.md 2.4 / 3.7).
/// 회색 캔버스 위 흰 카드 섹션 구성. 드래프트 상태·저장은 `AddEditViewModel`에 위임하고
/// 이 View는 표시·바인딩만 담당한다(값 조회/저장 로직 없음 — 경계 분리).
struct AddEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// 편집 대상(없으면 신규). 타이틀·기본색 세팅에 참조한다.
    private let editing: Credential?

    /// 폼 드래프트 소유. iOS 17 `@Observable`이라 `$vm.serviceName`으로 직접 바인딩한다.
    @State private var vm: AddEditViewModel
    @State private var isPasswordRevealed = false
    @State private var showSaveError = false

    init(editing: Credential? = nil) {
        self.editing = editing
        _vm = State(initialValue: AddEditViewModel(editing: editing))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    basicSection
                    colorSection
                    fieldsSection
                    extraSection
                    favoriteSection
                }
                .padding(.horizontal, MASpacing.screenHorizontal)
                .padding(.bottom, 40)
            }
            .background(MAColor.appBackground.ignoresSafeArea())
            .navigationTitle(editing == nil ? "새 계정" : "편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear(perform: applyDefaultColor)
            .alert("저장에 실패했어요", isPresented: $showSaveError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("다시 시도해 주세요.")
            }
        }
        .tint(MAColor.interactiveText)
    }

    // MARK: - 헤더(취소 / 저장)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("취소") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            // 유효 시 interactiveText(tint) 활성, 비활성은 시스템 disabled 톤.
            Button("저장", action: performSave)
                .fontWeight(.semibold)
                .disabled(!vm.isValid)
        }
    }

    // MARK: - ① 기본 정보

    private var basicSection: some View {
        section("기본 정보") {
            card {
                inputRow("서비스명", text: $vm.serviceName)
            }
        }
    }

    // MARK: - ② 색상(F-15)

    private var colorSection: some View {
        section("색상") {
            card {
                ColorPickerGrid(selectedHex: $vm.colorHex)
            }
        }
    }

    // MARK: - ③ 필드

    private var fieldsSection: some View {
        section("필드") {
            card {
                inputRow("아이디", text: $vm.username, mono: true, autocap: false)
                rowDivider
                passwordRow
                ForEach($vm.fields) { $field in
                    rowDivider
                    CustomFieldRow(label: $field.label, value: $field.value) {
                        withAnimation(MAMotion.reveal) { vm.removeField(field) }
                    }
                }
            }
            addFieldButton
        }
    }

    /// 비밀번호 — 모노 표시 + 우측 표시/숨김 토글(Design.md 2.4③).
    private var passwordRow: some View {
        HStack(spacing: MASpacing.gap) {
            Group {
                if isPasswordRevealed {
                    TextField("비밀번호", text: $vm.password)
                } else {
                    SecureField("비밀번호", text: $vm.password)
                }
            }
            .font(MAType.secretValue)
            .foregroundStyle(MAColor.ink)
            .tint(MAColor.primary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button(isPasswordRevealed ? "숨김" : "표시") {
                isPasswordRevealed.toggle()
            }
            .font(MAType.rowSubtitle)
            .foregroundStyle(MAColor.interactiveText)
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, MASpacing.rowVertical)
    }

    /// '+ 필드 추가' — 카드 하단 점선 버튼(Design.md 2.4③).
    private var addFieldButton: some View {
        Button {
            withAnimation(MAMotion.pop) { vm.addField() }
        } label: {
            Text("+ 필드 추가")
                .font(MAType.rowTitle)
                .foregroundStyle(MAColor.interactiveText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: MARadius.card, style: .continuous)
                        .strokeBorder(
                            MAColor.interactiveText.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                )
        }
        .buttonStyle(.plain)
        .padding(.top, MASpacing.sectionHeaderBottom)
    }

    // MARK: - ④ 추가 정보(선택)

    private var extraSection: some View {
        section("추가 정보") {
            card {
                inputRow("URL", text: $vm.urlString, autocap: false)
                    .keyboardType(.URL)
                rowDivider
                memoRow
            }
        }
    }

    /// 메모 — 여러 줄 입력(Design.md 2.4④ textarea).
    private var memoRow: some View {
        TextField("메모", text: $vm.memo, axis: .vertical)
            .font(MAType.fieldValue)
            .foregroundStyle(MAColor.ink)
            .tint(MAColor.primary)
            .lineLimit(3 ... 6)
            .padding(.horizontal, MASpacing.rowHorizontal)
            .padding(.vertical, MASpacing.rowVertical)
    }

    // MARK: - ⑤ 즐겨찾기

    private var favoriteSection: some View {
        section("즐겨찾기") {
            card {
                HStack(spacing: MASpacing.gap) {
                    Text("즐겨찾기")
                        .font(MAType.fieldValue)
                        .foregroundStyle(MAColor.ink)
                    Spacer()
                    MAToggle(isOn: $vm.isFavorite)
                }
                .padding(.horizontal, MASpacing.rowHorizontal)
                .padding(.vertical, MASpacing.rowVertical - 2)
            }
        }
    }

    // MARK: - 공통 레이아웃 헬퍼

    /// 회색 캔버스 위 섹션 — 작은 헤더 + 흰 카드 슬롯.
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(MAType.sectionHeader)
                .foregroundStyle(MAColor.secondary)
                .padding(.leading, 4)
                .padding(.top, MASpacing.sectionHeaderTop)
                .padding(.bottom, MASpacing.sectionHeaderBottom)
            content()
        }
    }

    /// 섹션 내용을 담는 흰 카드(radius 16).
    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MAColor.card)
            .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))
    }

    /// 단일 텍스트 입력 행(서비스명·아이디·URL 등).
    private func inputRow(
        _ placeholder: String,
        text: Binding<String>,
        mono: Bool = false,
        autocap: Bool = true
    ) -> some View {
        TextField(placeholder, text: text)
            .font(mono ? MAType.secretValue : MAType.fieldValue)
            .foregroundStyle(MAColor.ink)
            .tint(MAColor.primary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(autocap ? .sentences : .never)
            .padding(.horizontal, MASpacing.rowHorizontal)
            .padding(.vertical, MASpacing.rowVertical + 2)
    }

    /// 카드 내부 행 사이 헤어라인(좌측 인셋).
    private var rowDivider: some View {
        Rectangle()
            .fill(MAColor.divider)
            .frame(height: 0.5)
            .padding(.leading, MASpacing.rowHorizontal)
    }

    // MARK: - 액션

    /// 신규 계정은 기본색(토스 파랑)을 선택 상태로 보인다(Design.md 1.2 / 스크린샷 04).
    /// 편집은 로드된 색을 유지한다.
    private func applyDefaultColor() {
        if editing == nil, vm.colorHex.isEmpty {
            vm.colorHex = MAAvatarPalette.defaultHex
        }
    }

    /// 저장 — 방식 B(메타=SwiftData / 시크릿=Keychain)는 ViewModel이 처리한다.
    /// Keychain 쓰기가 모두 성공한 경우에만 닫고, 실패 시 화면을 유지하고 안내한다.
    /// (실패 시 dismiss 금지 — 비밀번호 없는 계정이 조용히 생성되는 것을 막는다.)
    private func performSave() {
        if vm.save(context: context) {
            dismiss()
        } else {
            showSaveError = true
        }
    }
}

// MARK: - Preview

@MainActor
private func addEditPreviewContainer(_ build: (ModelContext) -> Void = { _ in }) -> ModelContainer {
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

#Preview("신규") {
    AddEditView()
        .modelContainer(addEditPreviewContainer())
}

#Preview("편집") {
    let container = addEditPreviewContainer { context in
        context.insert(
            Credential(
                serviceName: "네이버",
                username: "naver_id",
                passwordRef: "preview_ref",
                colorHex: "#03C75A",
                isFavorite: true
            )
        )
    }
    let editing = try? container.mainContext.fetch(FetchDescriptor<Credential>()).first
    return AddEditView(editing: editing)
        .modelContainer(container)
}
