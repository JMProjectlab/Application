import SwiftUI

struct PayooScoringView: View {
    @EnvironmentObject var store: Store
    let sessionID: UUID

    @State private var inputs: [String] = []

    private let roundTotal = 250
    private var session: ScoreSession? { store.session(id: sessionID) }
    private var sum: Int { inputs.compactMap { Int($0) }.reduce(0, +) }

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
        let _ = ensureInputs(count: session.entrants.count)
        ScrollView {
            VStack(spacing: 14) {
                scoreboard(session)

                if session.isFinished, let w = session.winnerIndex {
                    WinnerBanner(name: session.entrants[w].name,
                                 detail: "\(session.total(w)) pts · \(session.rounds.count) manches",
                                 shareText: "🏆 \(session.entrants[w].name) remporte \(session.gameName) avec \(session.total(w)) points en \(session.rounds.count) manches ! Compté avec Scornade.")
                    endButtons()
                } else {
                    entryCard(session)
                }

                if !session.rounds.isEmpty {
                    history(session)
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

    // MARK: Scoreboard (le plus bas est en tête)

    private func scoreboard(_ session: ScoreSession) -> some View {
        let leader = session.entrants.indices.min(by: { session.total($0) < session.total($1) })
        return VStack(spacing: 8) {
            ForEach(session.entrants.indices, id: \.self) { i in
                let pair = Palette.pair(session.entrants[i].colorIndex)
                HStack(spacing: 10) {
                    Avatar(name: session.entrants[i].name, colorIndex: session.entrants[i].colorIndex, size: 30)
                    Text(session.entrants[i].name).font(.subheadline)
                    if i == leader, session.rounds.count > 0 {
                        Image(systemName: "crown.fill").font(.caption2).foregroundStyle(Color(hex: "C99A2E"))
                    }
                    Spacer()
                    Text("\(session.total(i))").font(.system(size: 20, weight: .medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(pair.bg.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: Saisie d'une manche

    private func entryCard(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points ramassés cette manche").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            ForEach(session.entrants.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    Avatar(name: session.entrants[i].name, colorIndex: session.entrants[i].colorIndex, size: 28)
                    Text(session.entrants[i].name).font(.subheadline)
                    Spacer()
                    TextField("0", text: binding(for: i))
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .frame(width: 70).textFieldStyle(.roundedBorder)
                }
            }
            HStack {
                Button { autoComplete(session) } label: {
                    Label("Compléter à 250", systemImage: "wand.and.stars").font(.caption)
                }
                .buttonStyle(.bordered)
                Spacer()
                Text("\(sum) / 250")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(sum == roundTotal ? Color(hex: "0F6E56") : Color(hex: "A32D2D"))
            }
            Button { validate(session) } label: {
                Label("Valider la manche", systemImage: "checkmark").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .disabled(sum != roundTotal)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Historique

    private func history(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MANCHES JOUÉES").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(Array(session.rounds.enumerated().reversed()), id: \.offset) { idx, round in
                HStack(spacing: 8) {
                    Text("M\(idx + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 30, alignment: .leading)
                    Text(roundSummary(session, round)).font(.caption).lineLimit(1)
                    Spacer()
                    Button(role: .destructive) {
                        store.deleteRound(sessionID: sessionID, at: idx)
                    } label: { Image(systemName: "trash").font(.caption) }
                    .buttonStyle(.borderless)
                }
                Divider()
            }
        }
        .padding(.top, 8)
    }

    private func endButtons() -> some View {
        VStack(spacing: 8) {
            Button { store.resetSession(sessionID: sessionID, keepSeries: false) } label: {
                Label("Rejouer (0 – 0)", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Button { store.popToRoot() } label: {
                Label("Changer de jeu", systemImage: "house").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: Helpers

    private func roundSummary(_ session: ScoreSession, _ round: [Int]) -> String {
        session.entrants.indices.map { i in
            "\(session.entrants[i].name.prefix(3)) \(round.indices.contains(i) ? round[i] : 0)"
        }.joined(separator: " · ")
    }

    private func ensureInputs(count: Int) {
        if inputs.count != count {
            DispatchQueue.main.async {
                if inputs.count != count {
                    inputs = Array(repeating: "", count: count)
                }
            }
        }
    }

    private func binding(for i: Int) -> Binding<String> {
        Binding(
            get: { i < inputs.count ? inputs[i] : "" },
            set: { v in if i < inputs.count { inputs[i] = v } }
        )
    }

    private func autoComplete(_ session: ScoreSession) {
        let n = session.entrants.count
        guard n > 0 else { return }
        ensureInputs(count: n)
        let others = (0..<(n - 1)).reduce(0) { $0 + (Int(inputs[$1]) ?? 0) }
        inputs[n - 1] = String(max(0, roundTotal - others))
    }

    private func validate(_ session: ScoreSession) {
        let deltas = (0..<session.entrants.count).map { Int(inputs[$0]) ?? 0 }
        store.addRound(sessionID: sessionID, deltas: deltas)
        inputs = Array(repeating: "", count: session.entrants.count)
    }
}
