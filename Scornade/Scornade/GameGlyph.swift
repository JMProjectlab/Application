import SwiftUI

/// Pictogramme d'un jeu.
///
/// Les jeux édités (Uno, Skyjo, Papayoo, Scrabble, Dominos, Mille Bornes…) ont des
/// logos déposés qu'on ne peut pas embarquer : on dessine à la place un motif qui
/// évoque le matériel du jeu — un pli de cartes, une grille, une tuile — sans
/// reprendre aucun élément de marque. Les autres jeux gardent leur SF Symbol.
struct GameGlyph: View {
    let gameId: String
    var size: CGFloat = 22
    var tint: Color = .inkSecondary

    var body: some View {
        Group {
            switch gameId {
            case "uno":         fannedCards
            case "skyjo":       cardGrid
            case "papayoo":     suitCard
            case "scrabble":    letterTile
            case "dominos":     dominoTile
            case "millebornes": milestone
            default:            fallbackSymbol
            }
        }
        .frame(width: size, height: size)
        .foregroundStyle(tint)
    }

    // Échelle : tous les tracés sont pensés dans une boîte de 22 pt.
    private var u: CGFloat { size / 22 }

    private var fallbackSymbol: some View {
        Image(systemName: GameCatalog.game(id: gameId)?.symbol ?? "questionmark")
            .font(.system(size: size * 0.86))
    }

    /// Uno — trois cartes en éventail.
    private var fannedCards: some View {
        ZStack {
            card(w: 9, h: 13).rotationEffect(.degrees(-16)).offset(x: -4 * u)
            card(w: 9, h: 13).rotationEffect(.degrees(16)).offset(x: 4 * u)
            card(w: 9, h: 13, filled: true)
        }
    }

    /// Skyjo — le tableau de cartes face visible.
    private var cardGrid: some View {
        VStack(spacing: 1.6 * u) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 1.6 * u) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 0.8 * u)
                            .fill(tint)
                            .frame(width: 3.6 * u, height: 4.4 * u)
                    }
                }
            }
        }
    }

    /// Papayoo — une carte avec ses points (et non un dé : c'est un jeu de plis).
    private var suitCard: some View {
        ZStack {
            card(w: 13, h: 17)
            VStack(spacing: 2 * u) {
                pip
                HStack(spacing: 2 * u) { pip; pip }
            }
        }
    }

    /// Scrabble — une tuile lettre avec sa valeur.
    private var letterTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.4 * u)
                .stroke(tint, lineWidth: 1.5 * u)
                .frame(width: 17 * u, height: 17 * u)
            Text("A")
                .font(.system(size: 9.5 * u, weight: .semibold))
                .offset(x: -1 * u, y: -0.5 * u)
            Text("1")
                .font(.system(size: 5 * u, weight: .semibold))
                .offset(x: 4.5 * u, y: 4 * u)
        }
    }

    /// Dominos — une tuile et ses points.
    private var dominoTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2 * u)
                .stroke(tint, lineWidth: 1.5 * u)
                .frame(width: 12 * u, height: 18 * u)
            Rectangle()
                .fill(tint)
                .frame(width: 9 * u, height: 1.2 * u)
            VStack(spacing: 3.4 * u) {
                HStack(spacing: 2.4 * u) { pip; pip }
                HStack(spacing: 2.4 * u) { pip; pip }
            }
        }
    }

    /// Mille Bornes — une borne kilométrique.
    private var milestone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4 * u)
                .stroke(tint, lineWidth: 1.5 * u)
                .frame(width: 12 * u, height: 17 * u)
            Rectangle()
                .fill(tint)
                .frame(width: 10.5 * u, height: 1.4 * u)
                .offset(y: -2.5 * u)
            Text("1000")
                .font(.system(size: 4.2 * u, weight: .semibold))
                .offset(y: 2.6 * u)
        }
    }

    // MARK: Briques de dessin

    private var pip: some View {
        Circle().fill(tint).frame(width: 2.4 * u, height: 2.4 * u)
    }

    private func card(w: CGFloat, h: CGFloat, filled: Bool = false) -> some View {
        Group {
            if filled {
                RoundedRectangle(cornerRadius: 1.8 * u)
                    .fill(tint)
                    .frame(width: w * u, height: h * u)
            } else {
                RoundedRectangle(cornerRadius: 1.8 * u)
                    .stroke(tint, lineWidth: 1.5 * u)
                    .frame(width: w * u, height: h * u)
            }
        }
    }
}
