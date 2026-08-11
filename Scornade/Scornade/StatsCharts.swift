import SwiftUI

/// Les formes graphiques des statistiques.
///
/// Tout est dessiné à la main plutôt qu'avec Swift Charts : les trois formes
/// dont on a besoin — un anneau, des barres, une jauge — tiennent en quelques
/// tracés, et le rendu reste identique à celui du site, qui n'a pas de
/// bibliothèque non plus.
///
/// L'ordre des teintes n'est pas décoratif : c'est lui qui garantit que deux
/// parts voisines restent distinguables en vision daltonienne. Il a été retenu
/// en énumérant les ordres possibles et en ne gardant que ceux qui passent
/// toutes les portes dans les deux modes. Ne pas réordonner sans revalider.
enum VizPalette {
    static let slots: [Color] = [
        Color(light: Color(hex: "0A84FF"), dark: Color(hex: "0A84FF")),
        Color(light: Color(hex: "FF9500"), dark: Color(hex: "D97200")),
        Color(light: Color(hex: "30B0C7"), dark: Color(hex: "16A2B9")),
        Color(light: Color(hex: "5E5CE6"), dark: Color(hex: "5E5CE6")),
        Color(light: Color(hex: "FF2D55"), dark: Color(hex: "FF2D55")),
        Color(light: Color(hex: "AF52DE"), dark: Color(hex: "AF52DE")),
    ]
    /// Au-delà, on replie la queue sur « Autres ». Jamais une septième teinte
    /// générée : elle serait indistinguable des autres en vision daltonienne.
    static let maxSlices = 6

    static func slot(_ i: Int) -> Color { slots[i % slots.count] }

    static let track = Color(light: Color(hex: "E5E5EA"), dark: Color(hex: "2A2A2C"))
}

/// Une part de l'anneau.
struct VizSlice: Identifiable {
    let id: String
    let label: String
    let value: Int
}

/// Replie une série trop longue sur « Autres ».
func foldTail(_ slices: [VizSlice], max: Int = VizPalette.maxSlices) -> [VizSlice] {
    guard slices.count > max else { return slices }
    let head = Array(slices.prefix(max - 1))
    let rest = slices.dropFirst(max - 1).reduce(0) { $0 + $1.value }
    return head + [VizSlice(id: "__autres__", label: String(localized: "Autres"), value: rest)]
}

/// Anneau de répartition.
///
/// Les parts sont séparées par un vide de 2 pt dans la couleur du fond — c'est
/// le fond qui sépare, pas un contour, qui ajouterait de l'encre sans donnée.
struct DonutChart: View {
    let slices: [VizSlice]
    var size: CGFloat = 168
    var thickness: CGFloat = 26
    var centerValue: String = ""
    var centerLabel: String = ""

    private var total: Int { max(1, slices.reduce(0) { $0 + $1.value }) }

    var body: some View {
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                DonutArc(start: startAngle(i), end: endAngle(i))
                    .stroke(VizPalette.slot(i), style: StrokeStyle(lineWidth: thickness, lineCap: .butt))
            }
            VStack(spacing: 1) {
                Text(centerValue).font(.jmScore(22, weight: .semibold))
                Text(centerLabel).font(.caption2).foregroundStyle(Color.inkSecondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Répartition"))
        .accessibilityValue(Text(slices.map { "\($0.label) \($0.value)" }.joined(separator: ", ")))
    }

    /// L'écart de 2 pt est exprimé en degrés à partir du rayon moyen, pour que
    /// deux parts voisines se touchent visuellement de la même façon quelle que
    /// soit leur taille.
    private var gapDegrees: Double {
        let r = (size - thickness) / 2
        return Double(2 / max(r, 1)) * 180 / .pi
    }

    private func fraction(upTo i: Int) -> Double {
        Double(slices.prefix(i).reduce(0) { $0 + $1.value }) / Double(total)
    }

    private func startAngle(_ i: Int) -> Angle { .degrees(-90 + fraction(upTo: i) * 360) }

    private func endAngle(_ i: Int) -> Angle {
        let full = -90 + fraction(upTo: i + 1) * 360
        // Une part minuscule reste visible plutôt que d'être avalée par l'écart.
        let start = -90 + fraction(upTo: i) * 360
        return .degrees(Swift.max(start + 0.5, full - gapDegrees))
    }
}

/// Barre arrondie du seul côté de la valeur.
///
/// `UnevenRoundedRectangle` ferait la même chose en une ligne, mais elle est
/// arrivée avec iOS 17 et la cible du projet est 16.2.
private struct BarFill: Shape {
    var radius: CGFloat = 5
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = Swift.min(radius, rect.height / 2, rect.width)
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct DonutArc: Shape {
    let start: Angle
    let end: Angle
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = (Swift.min(rect.width, rect.height)) / 2
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: r, startAngle: start, endAngle: end, clockwise: false)
        return p
    }
}

/// Légende de l'anneau.
///
/// Elle porte toujours la valeur écrite. En mode clair, deux des six teintes
/// passent sous 3:1 face au fond : la valeur ne doit jamais reposer sur la
/// seule couleur.
struct DonutLegend: View {
    let slices: [VizSlice]
    private var total: Int { max(1, slices.reduce(0) { $0 + $1.value }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(slices.enumerated()), id: \.element.id) { i, slice in
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(VizPalette.slot(i))
                        .frame(width: 11, height: 11)
                    Text(slice.label).font(.subheadline).lineLimit(1)
                    Spacer(minLength: 8)
                    Text("\(slice.value) · \(Int(round(Double(slice.value) / Double(total) * 100))) %")
                        .font(.caption).foregroundStyle(Color.inkSecondary)
                        .monospacedDigit()
                }
            }
        }
    }
}

/// Une barre horizontale, teinte unique.
///
/// Comparer des grandeurs est le travail d'une longueur : colorier chaque barre
/// selon sa valeur dépenserait le canal identité à réécrire ce que la longueur
/// montre déjà.
struct VizBar: View {
    let label: String
    let ratio: Double          // 0…1
    let display: String
    /// Renseigné quand la barre désigne un joueur : la pastille porte alors son
    /// identité, la barre ne fait que la longueur.
    var avatarColorIndex: Int?

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                if let avatarColorIndex {
                    Avatar(name: label, colorIndex: avatarColorIndex, size: 22)
                }
                Text(label).font(.subheadline).lineLimit(1)
            }
            .frame(width: 118, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(VizPalette.track)
                    // Extrémité arrondie côté valeur, carrée sur l'origine : la
                    // barre part d'une ligne de base commune, elle ne flotte pas.
                    BarFill()
                        .fill(VizPalette.slot(0))
                        .frame(width: geo.size.width * min(max(ratio, 0), 1))
                }
            }
            .frame(height: 10)

            Text(display)
                .font(.caption).foregroundStyle(Color.inkSecondary)
                .monospacedDigit()
                .frame(width: 46, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Jauge — un taux face à son plafond.
///
/// C'est la forme juste pour « x % de victoires » : un camembert à deux parts
/// dirait la même chose en moins lisible.
struct VizMeter: View {
    let pct: Int
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(VizPalette.track)
                BarFill(radius: 4)
                    .fill(VizPalette.slot(0))
                    .frame(width: geo.size.width * min(max(Double(pct) / 100, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityLabel(Text("Taux de victoire"))
        .accessibilityValue(Text("\(pct) %"))
    }
}
