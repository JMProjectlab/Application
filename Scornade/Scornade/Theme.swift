import SwiftUI
import UIKit

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

    /// Couleur adaptative clair/sombre (façon Asset Catalog, définie en code).
    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }

    // Brand — repris de la charte graphique du portfolio ("blueprint / vellum"),
    // variantes clair/sombre officielles de la charte.
    static let brand = Color(light: Color(hex: "2C86C9"), dark: Color(hex: "5FB6E8"))       // --line
    static let brandLight = Color(light: Color(hex: "D9E9F6"), dark: Color(hex: "143454"))  // --surface-2
    static let brandDark = Color(light: Color(hex: "123C63"), dark: Color(hex: "EAF1F6"))   // --accent / --ink

    // Rouge d'alerte / d'erreur (contrat chuté, bust, saisie invalide) — reprend
    // le "stamp" de la charte du portfolio.
    static let danger = Color(light: Color(hex: "C23B27"), dark: Color(hex: "FF6E55"))       // --stamp
    static let dangerLight = Color(light: Color(hex: "FCEBEB"), dark: Color(hex: "3A1714"))

    // Vert de succès et or — la charte du portfolio n'a que du bleu et du rouge ;
    // on garde ces teintes existantes mais on les rend enfin adaptatives clair/sombre.
    static let success = Color(light: Color(hex: "0F6E56"), dark: Color(hex: "3FD9B0"))
    static let successLight = Color(light: Color(hex: "E1F5EE"), dark: Color(hex: "123A32"))
    static let gold = Color(light: Color(hex: "BA7517"), dark: Color(hex: "E0AA4A"))
    static let crownGold = Color(light: Color(hex: "C99A2E"), dark: Color(hex: "E8C465"))

    // Identité "Équipe 2" dans les jeux à deux équipes (Belote, Coinche) : le rouge
    // tampon de la charte fait pendant au bleu de l'Équipe 1 (brand).
    static let teamTwo = danger
    static let teamTwoLight = Color(light: Color(hex: "FBE7E2"), dark: Color(hex: "3A1B18"))
    static let teamTwoDark = Color(light: Color(hex: "7A2216"), dark: Color(hex: "FF6E55"))
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
