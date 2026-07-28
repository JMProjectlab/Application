import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: Store
    @State private var selected: UUID?

    // MARK: Données calculées

    private struct GameStat: Identifiable {
        let id = UUID(); let name: String; let played: Int; let won: Int
    }
    private struct PeerStat: Identifiable {
        let id = UUID(); let name: String; let colorIndex: Int; let total: Int; let wins: Int
    }
    private struct PlayerStats {
        var played = 0, won = 0
        var perGame: [GameStat] = []
        var teammates: [PeerStat] = []
        var opponents: [PeerStat] = []
        var belotePlayed = false
        var prises = 0, reussies = 0, belotePoints = 0
        var lost: Int { max(0, played - won) }
        var rate: Int { played == 0 ? 0 : Int(Double(won) / Double(played) * 100) }
        var priseRate: Int { prises == 0 ? 0 : Int(Double(reussies) / Double(prises) * 100) }
    }

    private var currentPlayer: Player? {
        if let id = selected { return store.players.first { $0.id == id } }
        return store.players.first
    }

    private func computeStats(for p: Player) -> PlayerStats {
        var st = PlayerStats()
        var perGame: [String: (name: String, played: Int, won: Int)] = [:]
        var tm: [UUID: (Int, Int)] = [:]
        var op: [UUID: (Int, Int)] = [:]

        for s in store.sessions where s.isFinished {
            guard let ti = s.entrants.firstIndex(where: { $0.playerIds.contains(p.id) }) else { continue }
            let won = (s.winnerIndex == ti)
            st.played += 1; if won { st.won += 1 }

            var g = perGame[s.gameId] ?? (s.gameName, 0, 0)
            g.played += 1; if won { g.won += 1 }; perGame[s.gameId] = g

            for pid in s.entrants[ti].playerIds where pid != p.id {
                var t = tm[pid] ?? (0, 0); t.0 += 1; if won { t.1 += 1 }; tm[pid] = t
            }
            for (idx, e) in s.entrants.enumerated() where idx != ti {
                for pid in e.playerIds {
                    var o = op[pid] ?? (0, 0); o.0 += 1; if won { o.1 += 1 }; op[pid] = o
                }
            }

            if s.gameId == "belote", let rounds = s.beloteRounds {
                st.belotePlayed = true
                for r in rounds where r.takerTeam == ti {
                    st.prises += 1; if r.contractMade { st.reussies += 1 }
                }
                for round in s.rounds where round.indices.contains(ti) {
                    st.belotePoints += round[ti]
                }
            }
        }

        func player(_ id: UUID) -> Player? { store.players.first { $0.id == id } }
        st.perGame = perGame.values
            .map { GameStat(name: $0.name, played: $0.played, won: $0.won) }
            .sorted { $0.played > $1.played }
        st.teammates = tm.compactMap { id, v in
            player(id).map { PeerStat(name: $0.name, colorIndex: $0.colorIndex, total: v.0, wins: v.1) }
        }.sorted { $0.total > $1.total }
        st.opponents = op.compactMap { id, v in
            player(id).map { PeerStat(name: $0.name, colorIndex: $0.colorIndex, total: v.0, wins: v.1) }
        }.sorted { $0.total > $1.total }
        return st
    }

    // MARK: Vue

    var body: some View {
        List {
            if store.players.isEmpty {
                Text("Ajoutez des joueurs et terminez une partie pour voir les statistiques apparaître ici.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Section {
                    Picker("Joueur", selection: Binding(
                        get: { selected ?? store.players.first?.id },
                        set: { selected = $0 }
                    )) {
                        ForEach(store.players) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .pickerStyle(.menu)
                }

                if let p = currentPlayer {
                    let s = computeStats(for: p)
                    recordSection(p, s)
                    if !s.perGame.isEmpty { perGameSection(s) }
                    if !s.teammates.isEmpty { teammatesSection(s) }
                    if !s.opponents.isEmpty { opponentsSection(s) }
                    if s.belotePlayed { beloteSection(s) }
                    if s.played == 0 {
                        Text("Ce joueur n'a pas encore de partie terminée.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Statistiques")
        .onAppear {
            if selected == nil {
                let name = store.currentUser?.name
                selected = store.players.first(where: { $0.name == name })?.id ?? store.players.first?.id
            }
        }
    }

    private func recordSection(_ p: Player, _ s: PlayerStats) -> some View {
        Section("Bilan") {
            HStack {
                statBlock("\(s.played)", "Jouées")
                statBlock("\(s.won)", "Gagnées")
                statBlock("\(s.lost)", "Perdues")
                statBlock("\(s.rate)%", "Victoires")
            }
        }
    }

    private func perGameSection(_ s: PlayerStats) -> some View {
        Section("Par jeu") {
            ForEach(s.perGame) { g in
                HStack {
                    Text(g.name)
                    Spacer()
                    Text("\(g.won) V / \(g.played)").foregroundStyle(.secondary)
                }
            }
        }
    }

    private func teammatesSection(_ s: PlayerStats) -> some View {
        Section("Avec qui (coéquipiers)") {
            ForEach(s.teammates) { t in
                HStack(spacing: 10) {
                    Avatar(name: t.name, colorIndex: t.colorIndex, size: 28)
                    Text(t.name)
                    Spacer()
                    Text("\(t.wins) V / \(t.total)").foregroundStyle(.secondary)
                }
            }
        }
    }

    private func opponentsSection(_ s: PlayerStats) -> some View {
        Section("Contre qui (adversaires)") {
            ForEach(s.opponents) { o in
                HStack(spacing: 10) {
                    Avatar(name: o.name, colorIndex: o.colorIndex, size: 28)
                    Text(o.name)
                    Spacer()
                    Text("\(o.wins) V / \(o.total)").foregroundStyle(.secondary)
                }
            }
        }
    }

    private func beloteSection(_ s: PlayerStats) -> some View {
        Section("Belote — mes prises") {
            HStack {
                statBlock("\(s.prises)", "Prises")
                statBlock("\(s.reussies)", "Réussies")
                statBlock("\(s.priseRate)%", "Réussite")
            }
            HStack {
                Text("Points marqués")
                Spacer()
                Text("\(s.belotePoints)").foregroundStyle(.secondary)
            }
        }
    }

    private func statBlock(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(LocalizedStringKey(label)).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
