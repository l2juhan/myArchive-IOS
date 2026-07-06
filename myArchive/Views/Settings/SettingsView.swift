import SwiftUI

/// 설정 화면 — 보안·클립보드·정렬·정보(Design.md 2.5, PRD F-7).
/// 커스텀 ScrollView 카드 레이아웃 — 앱 공통 디자인 언어(흰 카드 + 회색 캔버스) 사용.
struct SettingsView: View {
    @AppStorage(SettingsKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(SettingsKey.clipboardExpirySec) private var clipboardExpirySec = ClipboardExpiry.sixty.rawValue
    @AppStorage(SettingsKey.sortMode) private var sortModeRaw = SortMode.favoriteRecent.rawValue

    @Environment(AppLockController.self) private var lockController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                securitySection
                clipboardSection
                sortSection
                infoSection
            }
            .padding(.horizontal, MASpacing.screenHorizontal)
            .padding(.vertical, 20)
        }
        .background(MAColor.appBackground.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { backButton }
        .tint(MAColor.interactiveText)
    }

    // MARK: - 헤더(‹ 목록)

    /// 목록이 자체 내비바를 숨겨 기본 back 라벨이 비므로, Design.md대로 '‹ 목록'을 직접 둔다.
    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("목록", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
                    .font(MAType.barButton)
            }
        }
    }

    // MARK: - 섹션

    private var securitySection: some View {
        settingsSection(header: "보안", footer: "켜면 앱 진입 시 Face ID 인증을 요구합니다. 비밀번호는 잠금과 무관하게 항상 Keychain에 암호화됩니다.") {
            VStack(spacing: 0) {
                HStack(spacing: MASpacing.gap) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("앱 잠금 · Face ID")
                            .font(MAType.rowTitle)
                            .foregroundStyle(MAColor.ink)
                        Text("앱을 열 때 인증을 요구해요")
                            .font(MAType.caption)
                            .foregroundStyle(MAColor.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isAppLockEnabled)
                        .labelsHidden()
                        .tint(MAColor.primary)
                }
                .padding(.horizontal, MASpacing.rowHorizontal)
                .padding(.vertical, MASpacing.rowVertical)

                if isAppLockEnabled {
                    Rectangle()
                        .fill(MAColor.divider)
                        .frame(height: 0.5)
                        .padding(.leading, MASpacing.rowHorizontal)

                    Button {
                        lockController.lock()
                        dismiss()
                    } label: {
                        HStack {
                            Text("지금 잠그기")
                                .font(MAType.rowTitle)
                                .foregroundStyle(MAColor.interactiveText)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(MAColor.interactiveText)
                        }
                        .padding(.horizontal, MASpacing.rowHorizontal)
                        .padding(.vertical, MASpacing.rowVertical)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAppLockEnabled)
    }

    private var clipboardSection: some View {
        settingsSection(header: "클립보드", footer: "정해진 시간 뒤 클립보드에서 지워, 다른 앱이 읽지 못하게 해요.") {
            VStack(alignment: .leading, spacing: 10) {
                Text("복사 후 자동 삭제")
                    .font(MAType.rowTitle)
                    .foregroundStyle(MAColor.ink)
                MASegmentedControl(
                    options: ClipboardExpiry.allCases.map { (label: $0.label, value: $0.rawValue) },
                    selection: $clipboardExpirySec
                )
            }
            .padding(.horizontal, MASpacing.rowHorizontal)
            .padding(.vertical, MASpacing.rowVertical)
        }
    }

    private var sortSection: some View {
        settingsSection(header: "목록 정렬", footer: "기본은 즐겨찾기를 맨 위에, 그다음 최근 수정 순서로 보여줘요.") {
            VStack(alignment: .leading, spacing: 10) {
                Text("정렬 방식")
                    .font(MAType.rowTitle)
                    .foregroundStyle(MAColor.ink)
                MASegmentedControl(
                    options: SortMode.allCases.map { (label: $0.label, value: $0.rawValue) },
                    selection: $sortModeRaw
                )
            }
            .padding(.horizontal, MASpacing.rowHorizontal)
            .padding(.vertical, MASpacing.rowVertical)
        }
    }

    private var infoSection: some View {
        settingsSection(header: "정보", footer: nil) {
            VStack(spacing: 0) {
                infoRow(label: "버전", value: "1.0")
                Rectangle().fill(MAColor.divider).frame(height: 0.5).padding(.leading, MASpacing.rowHorizontal)
                infoRow(label: "저장 방식", value: "로컬 · Keychain")
                Rectangle().fill(MAColor.divider).frame(height: 0.5).padding(.leading, MASpacing.rowHorizontal)
                infoRow(label: "네트워크", value: "사용 안 함")
            }
        }
    }

    // MARK: - 헬퍼

    /// 섹션 헤더 + 흰 카드 + 선택적 헬퍼 텍스트 래퍼.
    private func settingsSection(
        header: String,
        footer: String?,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(header)
                .font(MAType.sectionHeader)
                .foregroundStyle(MAColor.secondary)
                .padding(.leading, 4)

            content()
                .background(MAColor.card)
                .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))

            if let footer {
                Text(footer)
                    .font(MAType.caption)
                    .foregroundStyle(MAColor.secondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MAType.rowTitle)
                .foregroundStyle(MAColor.secondary)
            Spacer()
            Text(value)
                .font(MAType.rowTitle)
                .foregroundStyle(MAColor.ink)
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, MASpacing.rowVertical)
    }
}

// MARK: - Preview

#Preview("잠금 꺼짐") {
    NavigationStack { SettingsView() }
        .environment(AppLockController())
}

#Preview("잠금 켜짐 — 지금 잠그기 노출") {
    @Previewable @AppStorage(SettingsKey.isAppLockEnabled) var isAppLockEnabled = false
    let lc = AppLockController()
    return NavigationStack { SettingsView() }
        .environment(lc)
        .onAppear { isAppLockEnabled = true }
}
