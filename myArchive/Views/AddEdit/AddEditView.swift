import SwiftData
import SwiftUI

/// 추가/수정 화면 — 기본 정보·색상(F-15)·필드·추가 정보·즐겨찾기(Design.md 2.4 / 3.7).
/// 현재는 골격(색상 그리드·커스텀 필드 인라인 추가/삭제는 M1/M2/M3에서 마감).
struct AddEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// 편집 대상(없으면 신규).
    var editing: Credential?

    @State private var serviceName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var colorHex = MAAvatarPalette.defaultHex
    @State private var isFavorite = false

    private var isValid: Bool { !serviceName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("서비스명", text: $serviceName)
                }
                Section("필드") {
                    TextField("아이디", text: $username)
                    SecureField("비밀번호", text: $password)
                    // TODO(M1/M3): 커스텀 필드 인라인 추가/삭제
                }
                Section {
                    Toggle("즐겨찾기", isOn: $isFavorite)
                }
                // TODO(M1): 색상 스와치 그리드(F-15), 추가 정보(URL·메모)
            }
            .navigationTitle(editing == nil ? "새 계정" : "편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(!isValid)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
        .tint(MAColor.interactiveText)
    }

    private func loadIfEditing() {
        guard let editing else { return }
        serviceName = editing.serviceName
        username = editing.username
        colorHex = editing.colorHex
        isFavorite = editing.isFavorite
        password = KeychainService.get(editing.passwordRef) ?? ""
    }

    /// 저장 — 시크릿은 Keychain, 메타는 SwiftData(방식 B). M2/M3에서 커스텀 필드까지 확장.
    private func save() {
        let cred = editing ?? Credential(serviceName: "", username: "", passwordRef: "")
        cred.serviceName = serviceName
        cred.username = username
        cred.colorHex = colorHex
        cred.isFavorite = isFavorite
        if cred.passwordRef.isEmpty { cred.passwordRef = KeychainService.passwordRef(for: cred.id) }
        try? KeychainService.set(password, for: cred.passwordRef)

        if editing == nil {
            context.insert(cred)
        } else {
            cred.updatedAt = .now
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddEditView()
        .modelContainer(for: [Credential.self, CustomField.self], inMemory: true)
}
