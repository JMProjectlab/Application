import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    // Brand
    static let brand = Color(hex: "534AB7")
    static let brandLight = Color(hex: "EEEDFE")
    static let brandDark = Color(hex: "3C3489")
}

// Per-player / per-team color pairs (background + foreground text)
struct Palette {
    static let pairs: [(bg: Color, fg: Color)] = [
        (Color(hex: "EEEDFE"), Color(hex: "3C3489")), // purple
        (Color(hex: "E1F5EE"), Color(hex: "085041")), // teal
        (Color(hex: "FAECE7"), Color(hex: "712B13")), // coral
        (Color(hex: "E6F1FB"), Color(hex: "0C447C")), // blue
        (Color(hex: "FAEEDA"), Color(hex: "633806")), // amber
        (Color(hex: "FBEAF0"), Color(hex: "72243E")), // pink
    ]
    static let bars: [Color] = [
        Color(hex: "534AB7"), Color(hex: "1D9E75"), Color(hex: "D85A30"),
        Color(hex: "185FA5"), Color(hex: "BA7517"), Color(hex: "993556"),
    ]

    static func pair(_ i: Int) -> (bg: Color, fg: Color) { pairs[i % pairs.count] }
    static func bar(_ i: Int) -> Color { bars[i % bars.count] }
}

extension String {
    var initials: String {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return String(trimmed.prefix(2)).uppercased()
    }
}
