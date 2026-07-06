import SwiftUI
import UIKit

/// HEX 문자열로 Color를 만드는 헬퍼.
/// 디자인 토큰(Design.md 1장)과 계정별 색상(F-15)이 모두 HEX 기반이므로 공용으로 사용한다.
extension Color {
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let r, g, b, a: Double
        switch raw.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        default:
            r = 0
            g = 0
            b = 0
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// SwiftUI `Color`를 "#RRGGBB" 문자열로. 네이티브 컬러 피커에서 고른 커스텀 색(F-15)을
    /// 저장용 hex로 되돌릴 때 쓴다. UIColor 경유로 sRGB 성분을 뽑아 반올림·클램프한다.
    func toHex() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let channel = { (value: CGFloat) in Int((max(0, min(1, value)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", channel(r), channel(g), channel(b))
    }
}
