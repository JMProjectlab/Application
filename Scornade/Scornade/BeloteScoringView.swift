import SwiftUI

struct BeloteScoringView: View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) private var locale
    let sessionID: UUID

    @State private var taker: Int? = nil
    @State private var suit: String? = nil
    @State private var p0Str = ""
    @State private var p1Str = ""
    @State private var belote0 = false
    @State private var belote1 = false
    @State private var capot: Int? = nil

    private let total = 162
    private let suits = ["♠", "♥", "♦", "♣"]

    private var session: ScoreSession? { store.session(id: sessionID) }
    private var p0: Int { Int(p0Str) ?? 0 }
    private var p1: Int { Int(p1Str) ?? 0 }

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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.brand)
                }
                scoreboard(session)

                if session.isFinished, let w = session.winnerIndex {
                    WinnerBanner(name: session.entrants[w].name,
                                 detail: String(localized: "\(session.total(w)) – \(session.total(1 - w)) · \(session.rounds.count) donnes", locale: locale),
                                 shareText: String(localized: "🃏 \(session.entrants[w].name) remporte la Belote \(session.total(w)) – \(session.total(1 - w)) en \(session.rounds.count) donnes ! Compté avec Scornade.", locale: locale))
                    endGameButtons()
                } else {
                    dealerRow(session)
                    donneCard(session)
                }

                if let rounds = session.beloteRounds, !rounds.isEmpty {
                    historySection(session, rounds: rounds)
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

    private func scoreboard(_ session: ScoreSession) -> some View {
        HStack(spacing: 10) {
            teamScore(session, team: 0, bg: Color.brandLight, fg: Color.brandDark, bar: Color.brand)
            VStack { Text("\(session.target)").font(.headline); Text("objectif").font(.caption2).foregroundStyle(.secondary) }
            teamScore(session, team: 1, bg: Color(hex: "FAEEDA"), fg: Color(hex: "633806"), bar: Color(hex: "BA7517"))
        }
    }

    private func teamScore(_ session: ScoreSession, team: Int, bg: Color, fg: Color, bar: Color) -> some View {
        let totalPts = session.total(team)
        let prog = session.target > 0 ? min(1, Double(totalPts) / Double(session.target)) : 0
        return VStack(alignment: .leading, spacing: 4) {
            Text(team == 0 ? "Équipe 1" : "Équipe 2").font(.caption.weight(.medium)).foregroundStyle(fg)
            Text(session.entrants.indices.contains(team) ? session.entrants[team].name : "—")
                .font(.caption2).foregroundStyle(fg.opacity(0.8)).lineLimit(1)
            Text("\(totalPts)").font(.system(size: 28, weight: .medium)).foregroundStyle(fg)
            ProgressView(value: prog).tint(bar)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Dealer

    private var seats: [Player] {
        guard let s = session, s.entrants.count >= 2 else { return [] }
        let t0 = s.entrants[0].playerIds.compactMap { store.player(id: $0) }
        let t1 = s.entrants[1].playerIds.compactMap { store.player(id: $0) }
        var out: [Player] = []
        for k in 0..<max(t0.count, t1.count) {
            if k < t0.count { out.append(t0[k]) }
            if k < t1.count { out.append(t1[k]) }
        }
        return out
    }

    private func dealerRow(_ session: ScoreSession) -> some View {
        let s = seats
        let donneIndex = session.rounds.count
        let first = session.firstDealerSeat ?? 0
        let dealerName = s.isEmpty ? "—" : s[(first + donneIndex) % s.count].name
        let speakerName = s.isEmpty ? "—" : s[(first + donneIndex + 1) % s.count].name
        return Button {
            if !s.isEmpty { store.setFirstDealer(sessionID: sessionID, seat: (first + 1) % s.count) }
        } label: {
            HStack {
                Image(systemName: "person.wave.2")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Donne \(donneIndex + 1) · Donneur : \(dealerName)").font(.subheadline.weight(.medium))
                    Text("À \(speakerName) de parler · touchez pour changer").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: Donne entry

    private var sum: Int { p0 + p1 }
    private var canValidate: Bool {
        taker != nil && suit != nil && (capot != nil || sum == total)
    }

    private func donneCard(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            takerSection(session)
            atoutSection()
            pointsSection()
            bonusSection()
            if let t = taker, capot != nil || sum == total {
                resultPreview(takerName: session.entrants[t].name)
            }
            Button(action: validate) {
                Label("Valider la donne", systemImage: "checkmark").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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
                takerButton(0, label: session.entrants[0].name)
                takerButton(1, label: session.entrants[1].name)
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
                            .font(.title3)
                            .foregroundStyle(sym == "♥" || sym == "♦" ? Color(hex: "A32D2D") : Color.primary)
                            .frame(width: 44, height: 38)
                            .background(suit == sym ? Color.brandLight : Color(.secondarySystemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(suit == sym ? Color.brand : Color.clear, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pointsSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Points aux cartes").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                pointsBox(team: 0)
                pointsBox(team: 1)
            }
            Text(capot != nil ? "Capot — points automatiques"
                 : (sum == total ? "\(p0) + \(p1) = 162 ✓" : "\(p0) + \(p1) = \(sum) (doit faire 162)"))
                .font(.caption)
                .foregroundStyle(capot != nil || sum == total ? Color(hex: "0F6E56") : Color(hex: "A32D2D"))
        }
    }

    private func bonusSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Annonces & bonus").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                bonusToggle("Belote É1", on: belote0) { belote0.toggle() }
                bonusToggle("Belote É2", on: belote1) { belote1.toggle() }
            }
            HStack(spacing: 8) {
                bonusToggle("Capot É1", on: capot == 0) { toggleCapot(0) }
                bonusToggle("Capot É2", on: capot == 1) { toggleCapot(1) }
            }
        }
    }

    private func takerButton(_ team: Int, label: String) -> some View {
        Button { taker = team } label: {
            Text(label).font(.subheadline.weight(.medium)).lineLimit(1)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(taker == team ? (team == 0 ? Color.brandLight : Color(hex: "FAEEDA")) : Color(.secondarySystemBackground))
                .foregroundStyle(taker == team ? (team == 0 ? Color.brandDark : Color(hex: "633806")) : Color.secondary)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(taker == team ? Color.brand : Color.clear, lineWidth: 2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func pointsBox(team: Int) -> some View {
        let value = team == 0 ? p0 : p1
        return VStack(spacing: 6) {
            Text(team == 0 ? "Équipe 1" : "Équipe 2").font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Button { setTeam(team, to: value - 10) } label: { Image(systemName: "minus") }
                    .buttonStyle(.bordered).disabled(capot != nil)
                TextField("0", text: team == 0 ? $p0Str : $p1Str)
                    .keyboardType(.numberPad).multilineTextAlignment(.center)
                    .frame(width: 44).disabled(capot != nil)
                    .onSubmit { setTeam(team, to: team == 0 ? p0 : p1) }
                Button { setTeam(team, to: value + 10) } label: { Image(systemName: "plus") }
                    .buttonStyle(.bordered).disabled(capot != nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(team == 0 ? Color.brandLight : Color(hex: "FAEEDA"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func bonusToggle(_ label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text(on ? "Oui" : "Non").font(.caption2.weight(.medium))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(on ? Color.brandLight : Color(.tertiarySystemBackground))
                    .foregroundStyle(on ? Color.brandDark : Color.secondary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 11).padding(.vertical, 9)
            .background(Color(.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? Color.brand : Color.clear, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func resultPreview(takerName: String) -> some View {
        let round = buildRound()
        let d = round.deltas()
        let made = round.contractMade
        return VStack(alignment: .leading, spacing: 3) {
            Text(made ? "\(takerName) réussit son contrat \(suit ?? "")" : "\(takerName) est dedans — chute !")
                .font(.caption.weight(.semibold))
            HStack { Text("Équipe 1"); Spacer(); Text("+\(d[0]) pts") }.font(.caption)
            HStack { Text("Équipe 2"); Spacer(); Text("+\(d[1]) pts") }.font(.caption)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(made ? Color(hex: "E1F5EE") : Color(hex: "FCEBEB"))
        .foregroundStyle(made ? Color(hex: "085041") : Color(hex: "791F1F"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: History

    private func historySection(_ session: ScoreSession, rounds: [BeloteRound]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DONNES JOUÉES").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(Array(rounds.enumerated().reversed()), id: \.offset) { idx, r in
                let d = r.deltas()
                HStack(spacing: 8) {
                    Text("D\(idx + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 28, alignment: .leading)
                    Text("É\(r.takerTeam + 1) prend \(r.suit)").font(.caption)
                    Text(r.contractMade ? "✓" : "chute")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(r.contractMade ? Color(hex: "0F6E56") : Color(hex: "A32D2D"))
                    Spacer()
                    Text("\(d[0]) – \(d[1])").font(.caption.weight(.medium))
                    Button { loadForEdit(idx) } label: { Image(systemName: "pencil").font(.caption) }
                        .buttonStyle(.borderless)
                    Button(role: .destructive) { store.deleteRound(sessionID: sessionID, at: idx) } label: {
                        Image(systemName: "trash").font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                Divider()
            }
        }
        .padding(.top, 8)
    }

    // MARK: Actions

    private func setTeam(_ team: Int, to raw: Int) {
        let n = min(total, max(0, raw))
        if team == 0 { p0Str = String(n); if capot == nil { p1Str = String(total - n) } }
        else { p1Str = String(n); if capot == nil { p0Str = String(total - n) } }
    }

    private func toggleCapot(_ team: Int) {
        if capot == team {
            capot = nil
            p0Str = ""; p1Str = ""
        } else {
            capot = team
            // points aux cartes non pertinents en capot
            p0Str = "0"; p1Str = "0"
        }
    }

    private func buildRound() -> BeloteRound {
        BeloteRound(takerTeam: taker ?? 0, suit: suit ?? "♠",
                    cardPoints: [p0, p1], belote: [belote0, belote1], capotTeam: capot)
    }

    private func validate() {
        store.addBeloteRound(sessionID: sessionID, round: buildRound())
        resetForm()
    }

    private func resetForm() {
        taker = nil; suit = nil; p0Str = ""; p1Str = ""
        belote0 = false; belote1 = false; capot = nil
    }

    private func loadForEdit(_ index: Int) {
        guard let rounds = session?.beloteRounds, rounds.indices.contains(index) else { return }
        let r = rounds[index]
        taker = r.takerTeam
        suit = r.suit
        capot = r.capotTeam
        belote0 = r.belote[0]; belote1 = r.belote[1]
        p0Str = String(r.cardPoints[0]); p1Str = String(r.cardPoints[1])
        store.deleteRound(sessionID: sessionID, at: index) // retirée pour ré-enregistrement
    }
}
