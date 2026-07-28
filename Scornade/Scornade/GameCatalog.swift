import Foundation

enum GameCatalog {
    static let all: [Game] = [
        Game(id: "belote", name: "Belote", category: "cartes", symbol: "suit.club.fill",
             engine: .contractPoints, isTeamGame: true, defaultTarget: 501, higherWins: true),
        Game(id: "coinche", name: "Coinche", category: "cartes", symbol: "suit.spade.fill",
             engine: .contractPoints, isTeamGame: true, defaultTarget: 1000, higherWins: true),
        Game(id: "tarot", name: "Tarot", category: "cartes", symbol: "wand.and.stars",
             engine: .contractPoints, isTeamGame: false, defaultTarget: 500, higherWins: true),
        Game(id: "papayoo", name: "Papayoo", category: "societe", symbol: "die.face.5.fill",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 1000, higherWins: false),
        Game(id: "rami", name: "Rami", category: "cartes", symbol: "rectangle.on.rectangle",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 500, higherWins: false),
        Game(id: "uno", name: "Uno", category: "societe", symbol: "square.stack.3d.up.fill",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 500, higherWins: true),
        Game(id: "skyjo", name: "Skyjo", category: "societe", symbol: "star.fill",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 100, higherWins: false),
        Game(id: "scrabble", name: "Scrabble", category: "societe", symbol: "textformat.abc",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 0, higherWins: true),
        Game(id: "flechettes", name: "Fléchettes", category: "sport", symbol: "target",
             engine: .countdown, isTeamGame: false, defaultTarget: 501, higherWins: false),
        Game(id: "petanque", name: "Pétanque", category: "sport", symbol: "circle.circle",
             engine: .mancheWinner, isTeamGame: true, defaultTarget: 13, higherWins: true),
        Game(id: "billard", name: "Billard", category: "sport", symbol: "circle.grid.cross.fill",
             engine: .mancheWinner, isTeamGame: false, defaultTarget: 5, higherWins: true),
        Game(id: "yams", name: "Yam's", category: "des", symbol: "dice.fill",
             engine: .gridScore, isTeamGame: false, defaultTarget: 0, higherWins: true),
        Game(id: "421", name: "421", category: "des", symbol: "dice",
             engine: .cumulativePoints, isTeamGame: false, defaultTarget: 0, higherWins: false),
    ]

    static func game(id: String) -> Game? { all.first { $0.id == id } }

    static let categories: [(key: String, label: String)] = [
        ("all", "Tous"), ("cartes", "Cartes"), ("societe", "Société"),
        ("sport", "Sport"), ("des", "Dés"),
    ]
}
