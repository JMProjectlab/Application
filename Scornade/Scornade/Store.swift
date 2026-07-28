import Foundation
import Combine
import SwiftUI
import CloudKit

@MainActor
final class Store: ObservableObject {
    @Published var players: [Player] = []
    @Published var sessions: [ScoreSession] = []
    @Published var path = NavigationPath()
    @Published var currentUser: UserAccount?

    private let playersKey = "sm.players"
    private let sessionsKey = "sm.sessions"
    private let userKey = "sm.user"

    // MARK: CloudKit

    // Doit correspondre à com.apple.developer.icloud-container-identifiers
    // dans Scornade.entitlements (iCloud.<bundle identifier>).
    private let container = CKContainer(identifier: "iCloud.JMProject.Scornade")
    private lazy var privateDB = container.privateCloudDatabase

    private static let playerRecordType = "Player"
    private static let sessionRecordType = "ScoreSession"
    private static let payloadKey = "payload"

    private let knownPlayerIDsKey = "sm.cloudKnownPlayerIDs"
    private let knownSessionIDsKey = "sm.cloudKnownSessionIDs"
    private var knownPlayerRecordIDs: Set<String> = []
    private var knownSessionRecordIDs: Set<String> = []

    // Le mode invité reste strictement local : on ne touche jamais CloudKit.
    private var syncEnabled: Bool {
        guard let mode = currentUser?.mode else { return false }
        return mode != .guest
    }

    init() {
        loadKnownRecordIDs()
        load()
        Task {
            await pullFromCloud()
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
        Task { await pullFromCloud() }
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
        let wasSyncing = syncEnabled
        players = []
        sessions = []
        currentUser = nil
        path = NavigationPath()
        for key in [playersKey, sessionsKey, userKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        Task { await wipeCloudData(wasSyncing: wasSyncing) }
    }

    private func saveUser() {
        if let u = currentUser, let d = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(d, forKey: userKey)
        }
    }

    // MARK: Local persistence (cache instantané, hors-ligne)

    func reloadFromCloud() { Task { await pullFromCloud() } }

    private func save() {
        saveLocalCacheOnly()
        Task { await pushToCloud() }
    }

    private func saveLocalCacheOnly() {
        let enc = JSONEncoder()
        if let p = try? enc.encode(players) {
            UserDefaults.standard.set(p, forKey: playersKey)
        }
        if let s = try? enc.encode(sessions) {
            UserDefaults.standard.set(s, forKey: sessionsKey)
        }
    }

    private func load() {
        let dec = JSONDecoder()
        if let p = UserDefaults.standard.data(forKey: playersKey),
           let decoded = try? dec.decode([Player].self, from: p) {
            players = decoded
        }
        if let s = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? dec.decode([ScoreSession].self, from: s) {
            sessions = decoded
        }
        if let u = UserDefaults.standard.data(forKey: userKey),
           let decoded = try? dec.decode(UserAccount.self, from: u) {
            currentUser = decoded
        }
    }

    private func loadKnownRecordIDs() {
        knownPlayerRecordIDs = Set(UserDefaults.standard.stringArray(forKey: knownPlayerIDsKey) ?? [])
        knownSessionRecordIDs = Set(UserDefaults.standard.stringArray(forKey: knownSessionIDsKey) ?? [])
    }

    private func persistKnownRecordIDs() {
        UserDefaults.standard.set(Array(knownPlayerRecordIDs), forKey: knownPlayerIDsKey)
        UserDefaults.standard.set(Array(knownSessionRecordIDs), forKey: knownSessionIDsKey)
    }

    // MARK: CloudKit sync
    //
    // Base privée CloudKit (zone par défaut) : chaque joueur et chaque partie sont
    // sérialisés en JSON dans un unique champ "payload". On pousse l'état complet à
    // chaque `save()` et on tire les données au lancement / retour au premier plan.
    // Le mode invité ne déclenche jamais de synchro (promesse de confidentialité).

    private func makeRecord<T: Encodable>(id: UUID, type: String, value: T) -> CKRecord? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        let record = CKRecord(recordType: type, recordID: CKRecord.ID(recordName: id.uuidString))
        record[Self.payloadKey] = data as CKRecordValue
        return record
    }

    private func fetchAllRecords(type: String) async throws -> [CKRecord] {
        var all: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)]
            let nextCursor: CKQueryOperation.Cursor?
            if let cursor {
                (matchResults, nextCursor) = try await privateDB.records(continuingMatchFrom: cursor)
            } else {
                let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
                (matchResults, nextCursor) = try await privateDB.records(matching: query)
            }
            all += matchResults.compactMap { try? $0.1.get() }
            cursor = nextCursor
        } while cursor != nil
        return all
    }

    private func pushToCloud() async {
        guard syncEnabled else { return }
        guard (try? await container.accountStatus()) == .available else { return }

        let currentPlayerIDs = Set(players.map(\.id.uuidString))
        let currentSessionIDs = Set(sessions.map(\.id.uuidString))
        let deletedIDs = knownPlayerRecordIDs.subtracting(currentPlayerIDs)
            .union(knownSessionRecordIDs.subtracting(currentSessionIDs))

        let recordsToSave =
            players.compactMap { makeRecord(id: $0.id, type: Self.playerRecordType, value: $0) } +
            sessions.compactMap { makeRecord(id: $0.id, type: Self.sessionRecordType, value: $0) }
        let recordIDsToDelete = deletedIDs.map { CKRecord.ID(recordName: $0) }

        guard !recordsToSave.isEmpty || !recordIDsToDelete.isEmpty else { return }

        do {
            _ = try await privateDB.modifyRecords(saving: recordsToSave,
                                                   deleting: recordIDsToDelete,
                                                   savePolicy: .changedKeys)
            knownPlayerRecordIDs = currentPlayerIDs
            knownSessionRecordIDs = currentSessionIDs
            persistKnownRecordIDs()
        } catch {
            // Pas de réseau / iCloud momentanément indisponible : on réessaiera
            // au prochain save() ou reloadFromCloud().
        }
    }

    private func pullFromCloud() async {
        guard syncEnabled else { return }
        do {
            guard try await container.accountStatus() == .available else { return }
            let playerRecords = try await fetchAllRecords(type: Self.playerRecordType)
            let sessionRecords = try await fetchAllRecords(type: Self.sessionRecordType)

            let decoder = JSONDecoder()
            let remotePlayers = playerRecords.compactMap { record -> Player? in
                guard let data = record[Self.payloadKey] as? Data else { return nil }
                return try? decoder.decode(Player.self, from: data)
            }
            let remoteSessions = sessionRecords.compactMap { record -> ScoreSession? in
                guard let data = record[Self.payloadKey] as? Data else { return nil }
                return try? decoder.decode(ScoreSession.self, from: data)
            }

            mergePlayers(remotePlayers)
            mergeSessions(remoteSessions)
            knownPlayerRecordIDs.formUnion(playerRecords.map(\.recordID.recordName))
            knownSessionRecordIDs.formUnion(sessionRecords.map(\.recordID.recordName))
            persistKnownRecordIDs()
            saveLocalCacheOnly()
        } catch {
            // Hors-ligne, ou conteneur pas encore provisionné : on garde les données locales.
        }
    }

    /// Fusionne sans jamais supprimer localement : une absence côté serveur peut
    /// simplement signifier que l'entrée locale n'a pas encore été poussée.
    private func mergePlayers(_ remote: [Player]) {
        guard !remote.isEmpty else { return }
        var byID = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        for p in remote { byID[p.id] = p }
        players = Array(byID.values)
    }

    private func mergeSessions(_ remote: [ScoreSession]) {
        guard !remote.isEmpty else { return }
        var byID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        for s in remote { byID[s.id] = s }
        sessions = Array(byID.values).sorted { $0.date > $1.date }
    }

    private func wipeCloudData(wasSyncing: Bool) async {
        guard wasSyncing else { return }
        guard (try? await container.accountStatus()) == .available else { return }
        let idsToDelete = knownPlayerRecordIDs.union(knownSessionRecordIDs).map { CKRecord.ID(recordName: $0) }
        guard !idsToDelete.isEmpty else { return }
        do {
            _ = try await privateDB.modifyRecords(saving: [], deleting: idsToDelete)
            knownPlayerRecordIDs = []
            knownSessionRecordIDs = []
            persistKnownRecordIDs()
        } catch {
            // best-effort : les données locales sont déjà effacées.
        }
    }
}
