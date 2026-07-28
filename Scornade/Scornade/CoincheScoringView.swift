import SwiftUI

struct CoincheScoringView: View {
    @EnvironmentObject var store: Store
    let sessionID: UUID

    @State private var taker: Int?
    @State private var suit = "♠"
    @State private var contractIdx = 0
    @State private var capot = false
    @State private var coinche = 0
    @State private var takerPointsStr = "0"
    @State private var belote0 = false
    @State private var belote1 = false

    private let suits = ["♠", "♥", "♦", "♣", "TA", "SA"]
    private let values = [80, 90, 100, 110, 120, 130, 140, 150, 160]

    private var session: ScoreSession? { store.session(id: sessionID) }
    private var takerPoints: Int { min(162, max(0, Int(takerPointsStr) ?? 0)) }

    var body: some View {
        Group {
            if let session {
                content(session)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle").font(.largeTitle)
                    Text("Partie introuvable")
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func content(_ session: ScoreSession) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                if let series = session.seriesWins, series.count >= 2 {
                    Text("Manches gagnées · É1 \(series[0]) – \(series[1]) É2")
                        .font(.caption.weight(.medium)).foregroundStyle(Color.brand)
                }
                scoreboard(session)

                if session.isFinished, let w = session.winnerIndex {
                    WinnerBanner(name: session.entrants[w].name,
                                 detail: "\(session.total(w)) – \(session.total(1 - w)) · \(session.rounds.count) donnes")
                    endGameButtons()
                } else {
                    donneCard(session)
                }

                if let rounds = session.coincheRounds, !rounds.isEmpty {
                    history(session, rounds: rounds)
                }
            }
            .padding()
        }
        .navigationTitle(session.gameName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !session.isFinished {
                        Button {
                            store.finish(sessionID: sessionID)
                        } label: {
                            Label("Terminer la partie", systemImage: "flag.checkered")
                        }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    // MARK: Scoreboard

    private func scoreboard(_ session: ScoreSession) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { i in
                let pair = Palette.pair(session.entrants[i].colorIndex)
                VStack(spacing: 4) {
                    Text(session.entrants[i].name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Text("\(session.total(i))").font(.system(size: 30, weight: .semibold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(pair.bg.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                if i == 0 {
                    VStack(spacing: 2) {
                        Text("\(session.target)").font(.headline)
                        Text("objectif").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Donne

    private var canValidate: Bool { taker != nil }

    private func donneCard(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            takerSection(session)
            contractSection()
            atoutSection()
            pointsSection(session)
            bonusSection()
            if taker != nil {
                resultPreview(session)
            }
            Button(action: { validate(session) }) {
                Label("Valider la donne", systemImage: "checkmark").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .disabled(!canValidate)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func takerSection(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Qui prend ?").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    chip(session.entrants[i].name, selected: taker == i) { taker = i }
                }
            }
        }
    }

    private func contractSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contrat annoncé").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(values.indices, id: \.self) { i in
                    chip("\(values[i])", selected: !capot && contractIdx == i) { capot = false; contractIdx = i }
                }
                chip("Capot", selected: capot) { capot.toggle(); if capot { takerPointsStr = "162" } }
            }
            HStack(spacing: 8) {
                chip("Normal", selected: coinche == 0) { coinche = 0 }
                chip("Coinché ×2", selected: coinche == 1) { coinche = 1 }
                chip("Surcoinché ×4", selected: coinche == 2) { coinche = 2 }
            }
        }
    }

    private func atoutSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Atout").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(suits, id: \.self) { sym in
                    Button { suit = sym } label: {
                        Text(sym)
                            .font(sym.count > 1 ? .subheadline.weight(.semibold) : .title3)
                            .foregroundStyle(sym == "♥" || sym == "♦" ? Color(hex: "A32D2D") : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(suit == sym ? Color.brandLight : Color(.secondarySystemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(suit == sym ? Color.brand : Color.clear, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pointsSection(_ session: ScoreSession) -> some View {
        let t = taker ?? 0
        let defenderPts = 162 - takerPoints
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Points du preneur (\(session.entrants[t].name))")
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text(capot ? "Capot" : "objectif \(values[contractIdx])").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Button { setPoints(takerPoints - 10) } label: { Image(systemName: "minus") }.buttonStyle(.bordered)
                TextField("0", text: $takerPointsStr).keyboardType(.numberPad)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                Button { setPoints(takerPoints + 10) } label: { Image(systemName: "plus") }.buttonStyle(.bordered)
            }
            Text("Défense : \(defenderPts) points").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func bonusSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Belote / Rebelote (+20)").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                chip("Belote É1", selected: belote0) { belote0.toggle() }
                chip("Belote É2", selected: belote1) { belote1.toggle() }
            }
        }
    }

    private func resultPreview(_ session: ScoreSession) -> some View {
        let round = buildRound()
        let made = round.contractMade
        let d = round.deltas()
        return VStack(alignment: .leading, spacing: 4) {
            Text(made ? "Contrat réussi" : "Contrat chuté")
                .font(.caption.weight(.semibold))
            ForEach(0..<2, id: \.self) { i in
                HStack {
                    Text(session.entrants[i].name).font(.caption)
                    Spacer()
                    Text("+\(d[i])").font(.caption.weight(.medium))
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(made ? Color(hex: "E1F5EE") : Color(hex: "FCEBEB"))
        .foregroundStyle(made ? Color(hex: "085041") : Color(hex: "791F1F"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Historique

    private func history(_ session: ScoreSession, rounds: [CoincheRound]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DONNES JOUÉES").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(Array(rounds.enumerated().reversed()), id: \.offset) { idx, r in
                let name = session.entrants.indices.contains(r.takerTeam) ? session.entrants[r.takerTeam].name : "?"
                let coincheTag = r.coinche == 1 ? " ×2" : (r.coinche == 2 ? " ×4" : "")
                HStack(spacing: 8) {
                    Text("D\(idx + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 28, alignment: .leading)
                    Text("\(name) · \(r.capot ? "Capot" : "\(r.contract)")\(r.suit)\(coincheTag)").font(.caption).lineLimit(1)
                    Text(r.contractMade ? "✓" : "chute")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(r.contractMade ? Color(hex: "0F6E56") : Color(hex: "A32D2D"))
                    Spacer()
                    Button { loadForEdit(idx) } label: { Image(systemName: "pencil").font(.caption) }.buttonStyle(.borderless)
                    Button(role: .destructive) { store.deleteRound(sessionID: sessionID, at: idx) } label: {
                        Image(systemName: "trash").font(.caption)
                    }.buttonStyle(.borderless)
                }
                Divider()
            }
        }
        .padding(.top, 8)
    }

    private func endGameButtons() -> some View {
        VStack(spacing: 8) {
            Button { store.resetSession(sessionID: sessionID, keepSeries: true) } label: {
                Label("La belle (rejouer en cumulant)", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Button { store.resetSession(sessionID: sessionID, keepSeries: false) } label: {
                Label("Revanche (0 – 0)", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Button { store.popToRoot() } label: {
                Label("Changer de jeu", systemImage: "house").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: Helpers

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.subheadline).lineLimit(1)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(selected ? Color.brandLight : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? Color.brandDark : Color.secondary)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? Color.brand : Color.clear, lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func setPoints(_ v: Int) { takerPointsStr = String(min(162, max(0, v))) }

    private func buildRound() -> CoincheRound {
        let t = taker ?? 0
        var cp = [0, 0]
        cp[t] = takerPoints
        cp[1 - t] = 162 - takerPoints
        return CoincheRound(takerTeam: t, suit: suit, contract: values[contractIdx],
                            capot: capot, coinche: coinche, cardPoints: cp,
                            belote: [belote0, belote1])
    }

    private func validate(_ session: ScoreSession) {
        store.addCoincheRound(sessionID: sessionID, round: buildRound())
        resetForm()
    }

    private func resetForm() {
        taker = nil; suit = "♠"; contractIdx = 0; capot = false; coinche = 0
        takerPointsStr = "0"; belote0 = false; belote1 = false
    }

    private func loadForEdit(_ index: Int) {
        guard let rounds = session?.coincheRounds, rounds.indices.contains(index) else { return }
        let r = rounds[index]
        taker = r.takerTeam; suit = r.suit; capot = r.capot; coinche = r.coinche
        contractIdx = values.firstIndex(of: r.contract) ?? 0
        takerPointsStr = String(r.cardPoints[r.takerTeam])
        belote0 = r.belote[0]; belote1 = r.belote[1]
        store.deleteRound(sessionID: sessionID, at: index)
    }
}
