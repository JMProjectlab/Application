import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class Store: ObservableObject {
    @Published var players: [Player] = []
    @Published var sessions: [ScoreSession] = []
    @Published var path = NavigationPath()
    @Published var currentUser: UserAccount?

    private let playersKey = "sm.players"
    private let sessionsKey = "sm.sessions"
    private let userKey = "sm.user"

    // MARK: Firestore
    //
    // Arborescence : users/{uid}/players/{id} et users/{uid}/sessions/{id}.
    // Chaque document porte le modèle sérialisé en JSON dans un champ `payload`,
    // plus un `updatedAt` pour l'ordonnancement. Firestore n'accepte pas les
    // tableaux de tableaux, or `rounds` et `yamsGrid` en sont : le JSON évite
    // d'avoir à les envelopper, et donne au futur client web exactement la même
    // forme de données qu'ici.
    //
    // Conséquence assumée : la réconciliation se fait au document entier, pas au
    // champ. Deux appareils qui modifient la même partie en même temps s'écrasent
    // (le dernier écrit gagne). C'est acceptable tant qu'une partie est tenue par
    // un seul appareil à la fois ; le partage à plusieurs demandera un vrai
    // découpage en sous-collection de manches.

    private static let payloadField = "payload"
    private static let updatedAtField = "updatedAt"

    private lazy var db = Firestore.firestore()
    private var playersListener: ListenerRegistration?
    private var sessionsListener: ListenerRegistration?

    /// Dernier JSON réellement envoyé pour chaque document, pour ne pousser que
    /// ce qui a changé plutôt que la collection entière à chaque sauvegarde.
    private var pushedPlayers: [String: String] = [:]
    private var pushedSessions: [String: String] = [:]

    /// La connexion est obligatoire : sans compte Firebase authentifié, il n'y a
    /// rien à synchroniser. Le cache local sert alors de secours hors-ligne.
    private var syncEnabled: Bool {
        FirebaseSupport.isAvailable && Auth.auth().currentUser != nil && currentUser != nil
    }

    private var uid: String? { Auth.auth().currentUser?.uid }

    init() {
        load()
        if players.isEmpty {
            players = [
                Player(name: "Jimmy", colorIndex: 0),
                Player(name: "Marie", colorIndex: 2),
                Player(name: "Paul", colorIndex: 1),
                Player(name: "Sophie", colorIndex: 3),
            ]
            saveLocalCacheOnly()
        }
        startSyncIfSignedIn()
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
        if !players.contains(where: { $0.name == name }) {
            addPlayer(name: name, email: email)
        }
        startSyncIfSignedIn()
    }

    func signOut() {
        stopSync()
        try? Auth.auth().signOut()
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    /// Efface toutes les données de l'utilisateur : joueurs, parties et compte,
    /// en local ET côté serveur. Action irréversible (exigée par Apple).
    func deleteAllData() {
        let ids = (players.map(\.id.uuidString), sessions.map(\.id.uuidString))
        let wasSyncing = syncEnabled
        let user = Auth.auth().currentUser

        stopSync()
        players = []
        sessions = []
        currentUser = nil
        path = NavigationPath()
        pushedPlayers = [:]
        pushedSessions = [:]
        for key in [playersKey, sessionsKey, userKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }

        guard wasSyncing, let uid = user?.uid else { return }
        let root = db.collection("users").document(uid)
        Task {
            let batch = db.batch()
            for id in ids.0 { batch.deleteDocument(root.collection("players").document(id)) }
            for id in ids.1 { batch.deleteDocument(root.collection("sessions").document(id)) }
            try? await batch.commit()
            // Le compte lui-même part avec les données : c'est ce qu'exige la
            // règle 5.1.1(v) d'Apple sur la suppression de compte depuis l'app.
            try? await user?.delete()
        }
    }

    private func saveUser() {
        if let u = currentUser, let d = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(d, forKey: userKey)
        }
    }

    // MARK: Persistance locale (chargement instantané, hors-ligne)

    func reloadFromCloud() { startSyncIfSignedIn() }

    private func save() {
        saveLocalCacheOnly()
        pushChanges()
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

    // MARK: Synchronisation Firestore

    private func startSyncIfSignedIn() {
        stopSync()
        guard syncEnabled, let uid else { return }
        let root = db.collection("users").document(uid)

        playersListener = root.collection("players").addSnapshotListener { [weak self] snap, _ in
            guard let snap else { return }
            let remote = Self.decodeAll(Player.self, from: snap.documents)
            Task { @MainActor in self?.mergePlayers(remote) }
        }
        sessionsListener = root.collection("sessions").addSnapshotListener { [weak self] snap, _ in
            guard let snap else { return }
            let remote = Self.decodeAll(ScoreSession.self, from: snap.documents)
            Task { @MainActor in self?.mergeSessions(remote) }
        }

        // Ce qui existe déjà en local et pas encore côté serveur part au premier envoi.
        pushChanges()
    }

    private func stopSync() {
        playersListener?.remove(); playersListener = nil
        sessionsListener?.remove(); sessionsListener = nil
    }

    private nonisolated static func decodeAll<T: Decodable>(_ type: T.Type,
                                                            from docs: [QueryDocumentSnapshot]) -> [T] {
        let dec = JSONDecoder()
        return docs.compactMap { doc in
            guard let json = doc[payloadField] as? String,
                  let data = json.data(using: .utf8) else { return nil }
            return try? dec.decode(T.self, from: data)
        }
    }

    /// N'envoie que les documents dont le JSON a changé, et supprime ceux qui ont
    /// disparu localement.
    private func pushChanges() {
        guard syncEnabled, let uid else { return }
        let root = db.collection("users").document(uid)
        let enc = JSONEncoder()

        let batch = db.batch()
        var writes = 0

        func stage<T: Encodable & Identifiable>(_ items: [T],
                                                into collection: String,
                                                cache: inout [String: String]) where T.ID == UUID {
            let current = Set(items.map(\.id.uuidString))
            for item in items {
                let key = item.id.uuidString
                guard let data = try? enc.encode(item),
                      let json = String(data: data, encoding: .utf8),
                      cache[key] != json else { continue }
                batch.setData([Self.payloadField: json,
                               Self.updatedAtField: FieldValue.serverTimestamp()],
                              forDocument: root.collection(collection).document(key))
                cache[key] = json
                writes += 1
            }
            // Les clés sont relevées d'abord : on ne mute pas le dictionnaire
            // pendant qu'on le parcourt.
            let removed = cache.keys.filter { !current.contains($0) }
            for gone in removed {
                batch.deleteDocument(root.collection(collection).document(gone))
                cache[gone] = nil
                writes += 1
            }
        }

        stage(players, into: "players", cache: &pushedPlayers)
        stage(sessions, into: "sessions", cache: &pushedSessions)

        guard writes > 0 else { return }
        batch.commit { _ in /* Firestore rejoue l'écriture au retour du réseau. */ }
    }

    /// Fusionne sans jamais supprimer localement : une absence côté serveur peut
    /// simplement signifier que l'entrée locale n'a pas encore été poussée.
    private func mergePlayers(_ remote: [Player]) {
        guard !remote.isEmpty else { return }
        var byID = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        for p in remote { byID[p.id] = p }
        players = Array(byID.values).sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        saveLocalCacheOnly()
    }

    private func mergeSessions(_ remote: [ScoreSession]) {
        guard !remote.isEmpty else { return }
        var byID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        for s in remote { byID[s.id] = s }
        sessions = Array(byID.values).sorted { $0.date > $1.date }
        saveLocalCacheOnly()
    }
}
