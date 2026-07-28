import Foundation
import Combine
import SwiftUI

@MainActor
final class Store: ObservableObject {
    @Published var players: [Player] = []
    @Published var sessions: [ScoreSession] = []
    @Published var path = NavigationPath()
    @Published var currentUser: UserAccount?

    private let playersKey = "sm.players"
    private let sessionsKey = "sm.sessions"
    private let userKey = "sm.user"
    private let kvs = NSUbiquitousKeyValueStore.default

    init() {
        load()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
        kvs.synchronize()
        if players.isEmpty {
            players = [
                Player(name: "Jimmy", colorIndex: 0),
                Player(name: "Marie", colorIndex: 2),
                Player(name: "Paul", colorIndex: 1),
                Player(name: "Sophie", colorIndex: 3),
            ]
            save()
        }
    }

    // MARK: Players

    func addPlayer(name: String, email: String?) {
        let used = Set(players.map(\.colorIndex))
        let free = (0..<Palette.pairs.count).first { !used.contains($0) } ?? players.count
        players.append(Player(name: name, colorIndex: free, email: email))
        save()
    }

    func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
        save()
    }

    // MARK: Sessions

    @discardableResult
    func createSession(game: Game, entrants: [Entrant], target: Int) -> ScoreSession {
        let session = ScoreSession(
            gameId: game.id,
            gameName: game.name,
            symbol: game.symbol,
            target: target,
            higherWins: game.higherWins,
            direction: game.engine.direction,
            entrants: entrants
        )
        sessions.insert(session, at: 0)
        save()
        return session
    }

    func session(id: UUID) -> ScoreSession? { sessions.first { $0.id == id } }

    func player(id: UUID) -> Player? { players.first { $0.id == id } }

    func addRound(sessionID: UUID, deltas: [Int]) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].rounds.append(deltas)
        save()
    }

    func addBeloteRound(sessionID: UUID, round: BeloteRound) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].beloteRounds = (sessions[i].beloteRounds ?? []) + [round]
        sessions[i].rounds.append(round.deltas())
        save()
    }

    func addTarotRound(sessionID: UUID, round: TarotRound) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].tarotRounds = (sessions[i].tarotRounds ?? []) + [round]
        sessions[i].rounds.append(round.deltas(players: sessions[i].entrants.count))
        save()
    }

    func addCoincheRound(sessionID: UUID, round: CoincheRound) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].coincheRounds = (sessions[i].coincheRounds ?? []) + [round]
        sessions[i].rounds.append(round.deltas())
        save()
    }

    func init421(sessionID: UUID, pot: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].pot = pot
        sessions[i].jetons = Array(repeating: 0, count: sessions[i].entrants.count)
        save()
    }

    func charge421(sessionID: UUID, loser: Int, amount: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }),
              var pot = sessions[i].pot, var j = sessions[i].jetons,
              j.indices.contains(loser) else { return }
        let move = min(amount, pot)
        pot -= move
        j[loser] += move
        sessions[i].pot = pot
        sessions[i].jetons = j
        save()
    }

    func decharge421(sessionID: UUID, winner: Int, loser: Int, amount: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }),
              var j = sessions[i].jetons,
              j.indices.contains(winner), j.indices.contains(loser) else { return }
        let move = min(amount, j[winner])
        j[winner] -= move
        j[loser] += move
        sessions[i].jetons = j
        save()
    }

    func setYamsCell(sessionID: UUID, player: Int, category: Int, value: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        let n = sessions[i].entrants.count
        var grid = sessions[i].yamsGrid ?? Array(repeating: Array(repeating: -1, count: 13), count: n)
        if grid.count != n { grid = Array(repeating: Array(repeating: -1, count: 13), count: n) }
        if grid.indices.contains(player), grid[player].indices.contains(category) {
            grid[player][category] = value
        }
        sessions[i].yamsGrid = grid
        save()
    }

    func deleteRound(sessionID: UUID, at index: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }),
              sessions[i].rounds.indices.contains(index) else { return }
        sessions[i].rounds.remove(at: index)
        if var br = sessions[i].beloteRounds, br.indices.contains(index) {
            br.remove(at: index)
            sessions[i].beloteRounds = br
        }
        if var tr = sessions[i].tarotRounds, tr.indices.contains(index) {
            tr.remove(at: index)
            sessions[i].tarotRounds = tr
        }
        if var cr = sessions[i].coincheRounds, cr.indices.contains(index) {
            cr.remove(at: index)
            sessions[i].coincheRounds = cr
        }
        sessions[i].manuallyFinished = false
        save()
    }

    func setFirstDealer(sessionID: UUID, seat: Int) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].firstDealerSeat = seat
        save()
    }

    func popToRoot() { path = NavigationPath() }

    /// Rejoue une partie : remet les scores à zéro. keepSeries=true cumule les manches gagnées (la belle).
    func resetSession(sessionID: UUID, keepSeries: Bool) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        var s = sessions[i]
        if keepSeries {
            if let w = s.winnerIndex {
                var series = s.seriesWins ?? Array(repeating: 0, count: s.entrants.count)
                if series.count < s.entrants.count { series = Array(repeating: 0, count: s.entrants.count) }
                series[w] += 1
                s.seriesWins = series
            }
        } else {
            s.seriesWins = nil
        }
        s.rounds = []
        s.beloteRounds = nil
        s.tarotRounds = nil
        s.coincheRounds = nil
        s.yamsGrid = nil
        s.pot = nil
        s.jetons = nil
        s.manuallyFinished = false
        sessions[i] = s
        save()
    }

    func undoLastRound(sessionID: UUID) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }),
              !sessions[i].rounds.isEmpty else { return }
        sessions[i].rounds.removeLast()
        sessions[i].manuallyFinished = false
        save()
    }

    func finish(sessionID: UUID) {
        guard let i = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[i].manuallyFinished = true
        save()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    var activeSession: ScoreSession? { sessions.first { !$0.isFinished } }

    // MARK: Auth

    func signIn(id: String, name: String, email: String?, mode: AuthMode) {
        currentUser = UserAccount(id: id, name: name, email: email, mode: mode)
        saveUser()
        if mode != .guest, !players.contains(where: { $0.name == name }) {
            addPlayer(name: name, email: email)
        }
    }

    func signInGuest() {
        currentUser = UserAccount(id: UUID().uuidString, name: "Invité", email: nil, mode: .guest)
        saveUser()
    }

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    /// Efface toutes les données de l'utilisateur : joueurs, parties et compte,
    /// en local ET dans iCloud. Action irréversible (exigée par Apple).
    func deleteAllData() {
        players = []
        sessions = []
        currentUser = nil
        path = NavigationPath()
        for key in [playersKey, sessionsKey, userKey] {
            UserDefaults.standard.removeObject(forKey: key)
            kvs.removeObject(forKey: key)
        }
        kvs.synchronize()
    }

    private func saveUser() {
        if let u = currentUser, let d = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(d, forKey: userKey)
        }
    }

    // MARK: Persistence

    @objc private func cloudChanged() {
        load()
    }

    func reloadFromCloud() { load() }

    private func cloudOrLocal(_ key: String) -> Data? {
        kvs.data(forKey: key) ?? UserDefaults.standard.data(forKey: key)
    }

    private func save() {
        let enc = JSONEncoder()
        if let p = try? enc.encode(players) {
            kvs.set(p, forKey: playersKey)
            UserDefaults.standard.set(p, forKey: playersKey)
        }
        if let s = try? enc.encode(sessions) {
            kvs.set(s, forKey: sessionsKey)
            UserDefaults.standard.set(s, forKey: sessionsKey)
        }
        kvs.synchronize()
    }

    private func load() {
        let dec = JSONDecoder()
        if let p = cloudOrLocal(playersKey),
           let decoded = try? dec.decode([Player].self, from: p) {
            players = decoded
        }
        if let s = cloudOrLocal(sessionsKey),
           let decoded = try? dec.decode([ScoreSession].self, from: s) {
            sessions = decoded
        }
        if let u = UserDefaults.standard.data(forKey: userKey),
           let decoded = try? dec.decode(UserAccount.self, from: u) {
            currentUser = decoded
        }
    }
}
