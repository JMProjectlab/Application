# Scornade — projet SwiftUI (MVP)

Compteur universel de jeux de cartes, société, dés et adresse. Ce dossier contient
le code source SwiftUI prêt à ouvrir dans Xcode.

## Lancer le projet (5 minutes)

1. Ouvrez Xcode (15 ou plus récent).
2. `File > New > Project…` → onglet **iOS** → **App**.
   - Product Name : `Scornade`
   - Interface : **SwiftUI**
   - Language : **Swift**
   - Storage : **None**
3. Xcode crée un fichier `ScornadeApp.swift` et un `ContentView.swift` :
   - **Supprimez** `ContentView.swift`.
   - **Supprimez** le `ScornadeApp.swift` généré.
4. Glissez-déposez **tous les fichiers `.swift` de ce dossier** dans le navigateur de
   projet Xcode (cochez « Copy items if needed »).
5. Cible de déploiement : **iOS 16.0** minimum (réglable dans les réglages du projet).
6. Choisissez un simulateur (ex. iPhone 15) et appuyez sur **⌘R**.

## Ce qui fonctionne

- Bibliothèque de jeux filtrable (Accueil) avec votre charte violette.
- Configuration d'une partie : sélection des joueurs, assignation en 2 équipes
  pour les jeux d'équipe, choix de l'objectif de points.
- Comptage en direct : saisie des points par manche, totaux, barres de
  progression, détection automatique du vainqueur, historique, annulation de manche.
- Trois directions de score gérées : points cumulés (le + haut ou le + bas gagne)
  et compte à rebours (fléchettes 501 → 0).
- Gestion des joueurs (avec e-mail optionnel, prévu pour la future synchro).
- Statistiques : classement par taux de victoire calculé sur les parties terminées.
- Persistance locale automatique via UserDefaults (vos données restent entre deux
  lancements).

## Architecture

| Fichier              | Rôle                                                        |
|----------------------|-------------------------------------------------------------|
| `ScornadeApp`     | Point d'entrée, injecte le `Store`.                         |
| `Theme`              | Couleurs de marque, palette joueurs, init `Color(hex:)`.    |
| `Models`             | `Player`, `Game`, `ScoreSession`, moteur et direction.      |
| `GameCatalog`        | Liste statique des jeux + leur moteur/config.               |
| `Store`              | État global observable + persistance.                       |
| `HomeView`           | Accueil : bibliothèque + partie en cours.                   |
| `NewGameView`        | Configuration d'une partie.                                 |
| `ScoringView`        | Écran de comptage en direct.                                |
| `PlayersView`        | Gestion des joueurs.                                         |
| `StatsView`          | Statistiques.                                               |

## Prochaines étapes (extensions prévues par l'architecture)

- **Moteur contrat (Belote/Coinche/Tarot)** : ajouter une saisie de manche dédiée
  qui répartit 162 points et vérifie le contrat (réussi / dedans). Le modèle
  `ScoreSession.rounds` peut déjà stocker ces deltas ; il reste à écrire l'écran de
  saisie spécifique et le calcul.
- **Donneur tournant** : ajouter `seatOrder` et `firstDealer` à la session, calcul
  du donneur par modulo sur le numéro de manche.
- **Synchro par e-mail** : le champ `email` du joueur est déjà là ; côté serveur,
  prévoir les profils fantômes + invitations comme discuté.
- **Stats détaillées** : filtre par jeu, coéquipiers (le champ équipe est déjà
  présent dans les entrants), graphiques d'évolution.
