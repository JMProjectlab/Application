import Foundation

// How scores evolve during a game.
enum ScoreDirection: String, Codable {
    case accumulate   // start at 0, add points, reach a target
    case countdown    // start at target, subtract, reach 0
}

// Maps to the "scoring engines" from the design. Simplified for the MVP.
enum ScoringEngine: String, Codable {
    case cumulativePoints   // Scrabble, Uno, Skyjo, Farkle...
    case contractPoints     // Belote, Coinche, Tarot, Payoo
    case mancheWinner       // Petanque, 8 pool, Backgammon
    case countdown          // Darts 301/501
    case gridScore          // Yam's, Bowling

    var direction: ScoreDirection {
        self == .countdown ? .countdown : .accumulate
    }
}

struct Player: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorIndex: Int
    var email: String? = nil
}

struct Game: Identifiable, Hashable {
    var id: String          // slug, e.g. "belote"
    var name: String
    var category: String    // cartes / societe / sport / des
    var symbol: String      // SF Symbol name
    var engine: ScoringEngine
    var isTeamGame: Bool
    var defaultTarget: Int
    var higherWins: Bool    // true: highest total wins; false: lowest wins
    var rules: String = ""  // rappel rapide des règles, affiché depuis NewGameView
}

// A team or a solo player taking part in a session.
struct Entrant: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String        // "Jimmy" or "Jimmy + Paul"
    var colorIndex: Int
    var playerIds: [UUID]
}

struct ScoreSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var gameId: String
    var gameName: String
    var symbol: String
    var date = Date()
    var target: Int
    var higherWins: Bool
    var direction: ScoreDirection
    var entrants: [Entrant]
    var rounds: [[Int]] = []   // each round holds one delta per entrant index
    var manuallyFinished = false
    var beloteRounds: [BeloteRound]? = nil
    var firstDealerSeat: Int? = nil
    var seriesWins: [Int]? = nil
    var tarotRounds: [TarotRound]? = nil
    var coincheRounds: [CoincheRound]? = nil
    var yamsGrid: [[Int]]? = nil   // [joueur][catégorie], -1 = vide
    var pot: Int? = nil           // 421 : jetons restant dans la cave
    var jetons: [Int]? = nil      // 421 : jetons par joueur

    func total(_ i: Int) -> Int {
        let sum = rounds.reduce(0) { acc, round in
            acc + (round.indices.contains(i) ? round[i] : 0)
        }
        return direction == .countdown ? max(0, target - sum) : sum
    }

    var reachedEnd: Bool {
        switch direction {
        case .countdown:
            return entrants.indices.contains { total($0) <= 0 }
        case .accumulate:
            return target > 0 && entrants.indices.contains { total($0) >= target }
        }
    }

    var isFinished: Bool { manuallyFinished || reachedEnd }

    /// Cette manche a-t-elle un enregistrement détaillé derrière elle ?
    ///
    /// Aux jeux à contrat, les points ne sont pas saisis : ils découlent de la
    /// donne. Corriger les points à la main revient donc à jeter ce détail, et
    /// l'interface doit le dire avant, pas après.
    func hasStructuredRound(at index: Int) -> Bool {
        (beloteRounds?.indices.contains(index) ?? false)
            || (tarotRounds?.indices.contains(index) ?? false)
            || (coincheRounds?.indices.contains(index) ?? false)
    }

    // Index of the winning entrant once the game has ended.
    var winnerIndex: Int? {
        guard isFinished, !entrants.isEmpty else { return nil }
        let totals = entrants.indices.map { total($0) }
        switch direction {
        case .countdown:
            return totals.firstIndex(of: totals.min() ?? 0)
        case .accumulate:
            if higherWins {
                return totals.firstIndex(of: totals.max() ?? 0)
            } else {
                return totals.firstIndex(of: totals.min() ?? 0)
            }
        }
    }
}


// Détail d'une donne de belote (moteur "contrat").
struct BeloteRound: Codable, Hashable {
    var takerTeam: Int        // 0 ou 1 : l'équipe qui prend
    var suit: String          // atout : "♠" "♥" "♦" "♣"
    var cardPoints: [Int]     // points aux cartes [équipe0, équipe1], somme = 162
    var belote: [Bool]        // belote/rebelote +20 [équipe0, équipe1]
    var capotTeam: Int?       // équipe ayant fait capot, sinon nil

    var contractMade: Bool {
        if capotTeam != nil { return true }
        return cardPoints[takerTeam] >= 82
    }

    func deltas() -> [Int] {
        var s = [0, 0]
        if let c = capotTeam {
            s[c] = 252 + (belote[c] ? 20 : 0)
            let o = 1 - c
            s[o] = belote[o] ? 20 : 0
            return s
        }
        if cardPoints[takerTeam] >= 82 {
            for t in 0..<2 { s[t] = cardPoints[t] + (belote[t] ? 20 : 0) }
        } else {
            // Le preneur est "dedans" : les 162 points vont à la défense
            let def = 1 - takerTeam
            s[def] = 162 + (belote[def] ? 20 : 0)
            s[takerTeam] = belote[takerTeam] ? 20 : 0
        }
        return s
    }
}


enum AuthMode: String, Codable {
    case apple, google
}

struct UserAccount: Codable, Equatable {
    var id: String
    var name: String
    var email: String?
    var mode: AuthMode
}


// Détail d'une donne de tarot (3 ou 4 joueurs). Total de la donne = 0.
struct TarotRound: Codable, Hashable {
    var takerIndex: Int
    var contract: Int   // 0 Prise · 1 Garde · 2 Garde sans · 3 Garde contre
    var bouts: Int      // 0..3 oudlers
    var points: Int     // points aux cartes du preneur (0..91)
    var petit: Int      // 0 aucun · 1 preneur · 2 défense (petit au bout)
    var poignee: Int    // 0 · 20 · 30 · 40

    private var multiplier: Int { [1, 2, 4, 6][min(max(contract, 0), 3)] }
    var target: Int { [56, 51, 41, 36][min(max(bouts, 0), 3)] }
    var ecart: Int { points - target }
    var contractMade: Bool { ecart >= 0 }

    private var unit: Int {
        let base = 25 + abs(ecart)
        var u = (contractMade ? 1 : -1) * base * multiplier
        let petitSign = petit == 1 ? 1 : (petit == 2 ? -1 : 0)
        u += petitSign * 10 * multiplier
        u += (contractMade ? 1 : -1) * poignee
        return u
    }

    func deltas(players n: Int) -> [Int] {
        guard n > 1, takerIndex >= 0, takerIndex < n else {
            return Array(repeating: 0, count: max(n, 0))
        }
        var d = Array(repeating: -unit, count: n)
        d[takerIndex] = unit * (n - 1)
        return d
    }
}


// Détail d'une donne de coinche (belote coinchée). Barème standard (proche FFBelote).
struct CoincheRound: Codable, Hashable {
    var takerTeam: Int        // 0 ou 1 : l'équipe qui prend
    var suit: String          // ♠ ♥ ♦ ♣ · TA (tout atout) · SA (sans atout)
    var contract: Int         // valeur annoncée : 80,90,...,160
    var capot: Bool           // capot demandé
    var coinche: Int          // 0 normal · 1 coinché (×2) · 2 surcoinché (×4)
    var cardPoints: [Int]     // points aux plis [équipe0, équipe1], somme = 162
    var belote: [Bool]        // belote/rebelote +20 [équipe0, équipe1]

    var value: Int { capot ? 250 : contract }
    var mult: Int { coinche == 1 ? 2 : (coinche == 2 ? 4 : 1) }

    var contractMade: Bool {
        if capot { return cardPoints[takerTeam] >= 162 }
        return cardPoints[takerTeam] >= value
    }

    func deltas() -> [Int] {
        var s = [0, 0]
        let t = takerTeam, d = 1 - takerTeam
        let bt = belote[t] ? 20 : 0
        let bd = belote[d] ? 20 : 0
        if contractMade {
            if capot {
                s[t] = 250 * mult + bt
                s[d] = bd
            } else {
                s[t] = (value + cardPoints[t]) * mult + bt
                s[d] = cardPoints[d] + bd
            }
        } else {
            s[t] = bt
            s[d] = (162 + value) * mult + bd
        }
        return s
    }
}
