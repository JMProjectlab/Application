import SwiftUI
import UIKit

// MARK: - Couleurs
//
// Palette reprise de la charte graphique JMprojectlab : deux neutres (encre,
// gris nuage) portent presque toute l'interface, et le bleu est le seul accent,
// réservé à ce qui est actionnable ou sélectionné — jamais décoratif.

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

    // Neutres de la charte.
    static let ink = Color(light: Color(hex: "1D1D1F"), dark: Color(hex: "F5F5F7"))
    static let inkSecondary = Color(light: Color(hex: "6E6E73"), dark: Color(hex: "A1A1A6"))
    static let cloud = Color(light: Color(hex: "F5F5F7"), dark: Color(hex: "101012"))
    static let hairline = Color(light: Color(hex: "D2D2D7"), dark: Color(hex: "2A2A2C"))

    // Le bleu : seul accent de la charte.
    static let brand = Color(light: Color(hex: "0071E3"), dark: Color(hex: "2997FF"))
    /// Fond teinté d'un élément sélectionné ou actif (le bleu, très dilué).
    static let brandLight = Color.brand.opacity(0.12)
    /// Texte posé sur `brandLight`.
    static let brandDark = Color(light: Color(hex: "0058B0"), dark: Color(hex: "2997FF"))

    // Retours sémantiques (contrat réussi / chuté, bust, saisie invalide).
    // La charte ne définit ni vert ni rouge : on s'appuie sur les couleurs
    // système d'Apple, déjà adaptatives et cohérentes avec le reste d'iOS.
    static let success = Color(uiColor: .systemGreen)
    static let successLight = Color(uiColor: .systemGreen).opacity(0.12)
    static let danger = Color(uiColor: .systemRed)
    static let dangerLight = Color(uiColor: .systemRed).opacity(0.12)
    static let gold = Color(uiColor: .systemOrange)
    static let crownGold = Color(uiColor: .systemYellow)

    // Jeux à deux équipes (Belote, Coinche) : l'Équipe 1 prend le bleu, l'Équipe 2
    // prend l'encre — les deux piliers de la charte, sans introduire de teinte tierce.
    static let teamTwo = Color.ink
    static let teamTwoLight = Color.ink.opacity(0.08)
    static let teamTwoDark = Color.ink
}

// MARK: - Typographie
//
// Aucune police n'est embarquée : la pile système affiche SF Pro sur iOS, comme
// le prescrit la charte. Titres jamais plus gras que semi-bold, chasse serrée,
// et chiffres tabulaires pour que les scores ne sautent pas d'une manche à l'autre.

extension Font {
    static let jmDisplay = Font.system(size: 34, weight: .semibold)
    static let jmTitle = Font.system(size: 32, weight: .semibold)
    static let jmSubtitle = Font.system(size: 22, weight: .semibold)
    static let jmBody = Font.system(size: 17)
    static let jmCaption = Font.system(size: 13)

    /// Chiffres de score : SF Pro à chasse tabulaire.
    static func jmScore(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }

    /// Lignes de données compactes (historique, ratios) : SF Mono.
    static func jmData(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    /// Chasse serrée des titres de la charte (−0,02 em).
    func jmTightTracking(_ size: CGFloat) -> some View {
        tracking(size * -0.02)
    }
}

// MARK: - Couleurs joueurs
//
// Les avatars doivent rester distinguables entre eux : c'est de l'information, pas
// de la décoration. On s'appuie sur les teintes système d'Apple plutôt que sur des
// pastels sur mesure, pour rester dans le registre natif de la charte.

struct Palette {
    private static let hues: [Color] = [
        Color(uiColor: .systemBlue),
        Color(uiColor: .systemTeal),
        Color(uiColor: .systemOrange),
        Color(uiColor: .systemIndigo),
        Color(uiColor: .systemPink),
        Color(uiColor: .systemPurple),
    ]

    static let pairs: [(bg: Color, fg: Color)] = hues.map { (bg: $0.opacity(0.14), fg: $0) }
    static let bars: [Color] = hues

    static func pair(_ i: Int) -> (bg: Color, fg: Color) { pairs[i % pairs.count] }
    static func bar(_ i: Int) -> Color { bars[i % bars.count] }
}

extension String {
    var initials: String {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return String(trimmed.prefix(2)).uppercased()
    }
}
