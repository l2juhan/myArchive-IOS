import LocalAuthentication

/// 선택적 앱 진입 잠금 — F-5 (PRD 7.4).
/// 생체(Face ID/Touch ID) 인증, 불가 시 기기 암호로 폴백.
enum AuthService {
    /// 잠금 해제 인증을 시도한다. 성공 시 true.
    static func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "암호로 잠금 해제"

        var error: NSError?
        // deviceOwnerAuthentication: 생체 → 실패/불가 시 기기 암호 폴백.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "저장된 계정 정보를 보호하기 위해 잠금을 해제합니다."
            )
        } catch {
            return false
        }
    }

    /// 생체 인증 사용 가능 여부 — 설정 화면 안내 문구에 활용.
    static var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }
}
