import SwiftUI

/// 설정 화면 — 보안·클립보드·정렬·정보(Design.md 2.5, PRD 5.1 F-7).
struct SettingsView: View {
    @AppStorage(SettingsKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(SettingsKey.clipboardExpirySec) private var clipboardExpirySec = ClipboardExpiry.sixty.rawValue
    @AppStorage(SettingsKey.sortMode) private var sortModeRaw = SortMode.favoriteRecent.rawValue

    var body: some View {
        Form {
            Section {
                Toggle("앱 잠금 · Face ID", isOn: $isAppLockEnabled)
            } header: {
                Text("보안")
            } footer: {
                Text("켜면 앱 진입 시 인증을 요구합니다. 기본값은 꺼짐이며, 저장된 비밀번호는 잠금 설정과 무관하게 항상 Keychain에 암호화됩니다.")
            }

            Section {
                Picker("복사 후 자동 삭제", selection: $clipboardExpirySec) {
                    ForEach(ClipboardExpiry.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("클립보드")
            }

            Section {
                Picker("정렬 방식", selection: $sortModeRaw) {
                    ForEach(SortMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("목록 정렬")
            }

            Section("정보") {
                LabeledContent("버전", value: "1.0 (MVP)")
                LabeledContent("저장 방식", value: "로컬 · Keychain")
                LabeledContent("네트워크", value: "사용 안 함")
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
