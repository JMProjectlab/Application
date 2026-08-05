// Catalogue des jeux — miroir de GameCatalog.swift.
// Les identifiants doivent rester identiques à ceux de l'app iOS : ce sont eux
// qui figurent dans les documents Firestore partagés entre les deux clients.

export const GAMES = [
  { id: "belote", name: "Belote", cat: "cartes", engine: "belote", team: true, target: 501, high: true,
    rules: "Le camp qui prend s'engage à faire au moins 82 des 162 points en jeu (100 en cas de belote annoncée). S'il échoue, tous les points vont à la défense. Premier camp à l'objectif gagne." },
  { id: "coinche", name: "Coinche", cat: "cartes", engine: "cumul", team: true, target: 1000, high: true,
    rules: "Comme la belote, mais l'annonce est un contrat chiffré (80 à 160, ou capot) que l'adversaire peut coincher (×2) voire surcoincher (×4). Le camp qui prend doit atteindre son contrat aux points, sous peine de tout perdre." },
  { id: "tarot", name: "Tarot", cat: "cartes", engine: "cumul", team: false, target: 500, high: true,
    rules: "Le preneur annonce prise, garde, garde sans ou garde contre et doit réunir un nombre de points dépendant de ses bouts (oudlers). Poignée et petit au bout apportent des bonus. Le total d'une donne est toujours nul." },
  { id: "papayoo", name: "Papayoo", cat: "societe", engine: "payoo", team: false, target: 1000, high: false,
    rules: "Jeu à levées où chaque carte négative (dames, valets de cœur, 8 de trèfle...) rapporte des points de pénalité au joueur qui la remporte. Le moins de points possible gagne." },
  { id: "rami", name: "Rami", cat: "cartes", engine: "cumul", team: false, target: 500, high: false,
    rules: "À chaque manche, les joueurs qui n'ont pas gagné comptent les points des cartes qu'il leur reste en main. Le score cumulé le plus bas à l'objectif gagne." },
  { id: "uno", name: "Uno", cat: "societe", engine: "cumul", team: false, target: 500, high: true,
    rules: "Le gagnant d'une manche marque les points des cartes restées en main de ses adversaires. Premier à l'objectif, le score cumulé le plus haut gagne." },
  { id: "skyjo", name: "Skyjo", cat: "societe", engine: "cumul", team: false, target: 100, high: false,
    rules: "Additionnez les valeurs de vos cartes visibles à la fin de chaque manche. Le joueur avec le score cumulé le plus bas à l'objectif remporte la partie." },
  { id: "scrabble", name: "Scrabble", cat: "societe", engine: "cumul", team: false, target: 0, high: true,
    rules: "Notez le score de chaque joueur à la fin de chaque tour. Le total le plus élevé en fin de partie gagne." },
  { id: "flechettes", name: "Fléchettes", cat: "sport", engine: "countdown", team: false, target: 501, high: false,
    rules: "Chaque joueur part de 501 et retire les points marqués à chaque volée. Interdit de finir sur 1 ; une volée qui dépasse ou laisse 1 point est annulée (bust). Premier à 0 gagne." },
  { id: "petanque", name: "Pétanque", cat: "sport", engine: "cumul", team: true, target: 13, high: true,
    rules: "Chaque mène rapporte des points à l'équipe la plus proche du cochonnet. Première équipe à 13 points gagne la partie." },
  { id: "billard", name: "Billard", cat: "sport", engine: "cumul", team: false, target: 5, high: true,
    rules: "Comptez les manches remportées. Premier joueur à 5 manches gagne le match." },
  { id: "yams", name: "Yam's", cat: "des", engine: "grid", team: false, target: 0, high: true,
    rules: "Remplissez les 13 catégories de la grille au fil des lancers de dés. Un bonus de 35 points est offert si la partie supérieure atteint 63. Le plus gros total gagne." },
  { id: "421", name: "421", cat: "des", engine: "cumul", team: false, target: 0, high: false,
    rules: "Chaque perdant charge des jetons dans la cave selon sa combinaison de dés. Une fois la cave vide, les jetons circulent entre joueurs : le premier à s'en délester gagne." },
  { id: "manille", name: "Manille", cat: "cartes", engine: "cumul", team: true, target: 500, high: true,
    rules: "Jeu de plis par équipes de deux où la manille (le 10) et l'as valent le plus de points. Comptez les points remportés à chaque donne ; premier camp à l'objectif gagne." },
  { id: "backgammon", name: "Backgammon", cat: "des", engine: "cumul", team: false, target: 7, high: true,
    rules: "Comptez les parties gagnées, en tenant compte du cube de doublement le cas échéant. Premier joueur à 7 points de match gagne." },
  { id: "bowling", name: "Bowling", cat: "sport", engine: "cumul", team: false, target: 0, high: true,
    rules: "Notez le score final affiché par la piste (ou calculé manuellement) après les 10 frames de chaque partie. Le plus haut score gagne." },
  { id: "poker", name: "Poker", cat: "cartes", engine: "cumul", team: false, target: 0, high: true,
    rules: "Suivez l'évolution du tapis de jetons de chaque joueur au fil des mains (entrez la variation à chaque étape). Le plus gros tapis à la fin de la session gagne." },
  { id: "dominos", name: "Dominos", cat: "societe", engine: "cumul", team: false, target: 100, high: false,
    rules: "À chaque manche, les joueurs qui n'ont pas gagné comptent les points des dominos qu'il leur reste en main. Le score cumulé le plus bas à l'objectif gagne." },
  { id: "millebornes", name: "Mille Bornes", cat: "cartes", engine: "cumul", team: false, target: 5000, high: true,
    rules: "Notez le total de points (bornes parcourues, primes et coups fourrés) marqué par chaque joueur à la fin de chaque manche. Premier à l'objectif gagne." },
  { id: "molkky", name: "Mölkky", cat: "sport", engine: "molkky", team: false, target: 50, high: true,
    rules: "Lancez le mölkky pour faire tomber les quilles : une seule quille abattue rapporte son numéro, plusieurs quilles rapportent leur nombre. Il faut atteindre exactement 50 ; un dépassement fait retomber le score à 25." },
];

export const CATEGORIES = [
  ["all", "Tous"], ["cartes", "Cartes"], ["societe", "Société"],
  ["sport", "Sport"], ["des", "Dés"],
];

export const gameById = (id) => GAMES.find((g) => g.id === id);

// Teintes des avatars — mêmes couleurs système qu'iOS (Palette dans Theme.swift).
export const HUES = ["#0a84ff", "#30b0c7", "#ff9500", "#5e5ce6", "#ff2d55", "#af52de"];

// Pictogrammes des jeux édités : on redessine le matériel plutôt que de
// reproduire des logos déposés. Mêmes tracés que GameGlyph.swift, boîte de 22.
const GLYPHS = {
  uno: `<g transform="translate(11,11)">
      <g transform="translate(-4,0) rotate(-16)"><rect x="-4.5" y="-6.5" width="9" height="13" rx="1.8" fill="none" stroke="currentColor" stroke-width="1.5"/></g>
      <g transform="translate(4,0) rotate(16)"><rect x="-4.5" y="-6.5" width="9" height="13" rx="1.8" fill="none" stroke="currentColor" stroke-width="1.5"/></g>
      <rect x="-4.5" y="-6.5" width="9" height="13" rx="1.8" fill="currentColor"/></g>`,
  skyjo: Array.from({ length: 12 }, (_, i) => {
    const row = Math.floor(i / 4), col = i % 4;
    return `<rect x="${1.4 + col * 5.2}" y="${2.8 + row * 6}" width="3.6" height="4.4" rx="0.8" fill="currentColor"/>`;
  }).join(""),
  papayoo: `<rect x="4.5" y="2.5" width="13" height="17" rx="1.8" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="11" cy="8.8" r="1.2" fill="currentColor"/>
      <circle cx="8.8" cy="13.2" r="1.2" fill="currentColor"/>
      <circle cx="13.2" cy="13.2" r="1.2" fill="currentColor"/>`,
  scrabble: `<rect x="2.5" y="2.5" width="17" height="17" rx="2.4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <text x="10" y="10.5" font-size="9.5" font-weight="600" fill="currentColor" text-anchor="middle" dominant-baseline="central">A</text>
      <text x="15.5" y="15" font-size="5" font-weight="600" fill="currentColor" text-anchor="middle" dominant-baseline="central">1</text>`,
  dominos: `<rect x="5" y="2" width="12" height="18" rx="2" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <rect x="6.5" y="10.4" width="9" height="1.2" fill="currentColor"/>
      <circle cx="8.6" cy="8.1" r="1.2" fill="currentColor"/><circle cx="13.4" cy="8.1" r="1.2" fill="currentColor"/>
      <circle cx="8.6" cy="13.9" r="1.2" fill="currentColor"/><circle cx="13.4" cy="13.9" r="1.2" fill="currentColor"/>`,
  millebornes: `<rect x="5" y="2.5" width="12" height="17" rx="4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <rect x="5.75" y="7.8" width="10.5" height="1.4" fill="currentColor"/>
      <text x="11" y="13.6" font-size="4.2" font-weight="600" fill="currentColor" text-anchor="middle" dominant-baseline="central">1000</text>`,
  // Les autres jeux : un tracé simple mais propre à chacun.
  // Trèfle pour la belote, pique pour la coinche — comme les SF Symbols côté iOS.
  belote: `<circle cx="11" cy="7.6" r="3.2" fill="currentColor"/>
      <circle cx="7.5" cy="12.7" r="3.2" fill="currentColor"/>
      <circle cx="14.5" cy="12.7" r="3.2" fill="currentColor"/>
      <path d="M11.9 13.2l1.2 5.2H8.9l1.2-5.2z" fill="currentColor"/>`,
  coinche: `<path d="M11 3.6l5.6 6.2c1.7 2 .4 5-2.2 5a3 3 0 0 1-2.2-1l.7 4.6H9.1l.7-4.6a3 3 0 0 1-2.2 1c-2.6 0-3.9-3-2.2-5L11 3.6z" fill="currentColor"/>`,
  tarot: `<path d="M11 3l1.9 5.4L18.5 9l-4.3 3.6 1.4 5.4L11 15l-4.6 3 1.4-5.4L3.5 9l5.6-.6z" fill="currentColor"/>`,
  rami: `<rect x="3" y="6" width="10" height="14" rx="1.8" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <rect x="9" y="2" width="10" height="14" rx="1.8" fill="currentColor"/>`,
  manille: `<path d="M11 3.5l5.5 7.5-5.5 7.5L5.5 11z" fill="currentColor"/>`,
  poker: `<circle cx="11" cy="11" r="7.6" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="11" cy="11" r="3" fill="currentColor"/>
      <rect x="10.2" y="1.8" width="1.6" height="3" fill="currentColor"/>
      <rect x="10.2" y="17.2" width="1.6" height="3" fill="currentColor"/>
      <rect x="1.8" y="10.2" width="3" height="1.6" fill="currentColor"/>
      <rect x="17.2" y="10.2" width="3" height="1.6" fill="currentColor"/>`,
  flechettes: `<circle cx="11" cy="11" r="8" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="11" cy="11" r="4.4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="11" cy="11" r="1.6" fill="currentColor"/>`,
  petanque: `<circle cx="7.6" cy="13" r="4.4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="15.4" cy="14.6" r="2.8" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="14.4" cy="6.4" r="1.5" fill="currentColor"/>`,
  billard: `<circle cx="11" cy="11" r="7.6" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="11" cy="11" r="3.4" fill="currentColor"/>`,
  molkky: `<rect x="8" y="5" width="6" height="13" rx="2.4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <rect x="8" y="9" width="6" height="1.3" fill="currentColor"/>`,
  yams: `<rect x="3" y="3" width="16" height="16" rx="3.2" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="7.4" cy="7.4" r="1.3" fill="currentColor"/><circle cx="14.6" cy="7.4" r="1.3" fill="currentColor"/>
      <circle cx="11" cy="11" r="1.3" fill="currentColor"/>
      <circle cx="7.4" cy="14.6" r="1.3" fill="currentColor"/><circle cx="14.6" cy="14.6" r="1.3" fill="currentColor"/>`,
  421: `<rect x="3" y="3" width="16" height="16" rx="3.2" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <circle cx="7.4" cy="7.4" r="1.3" fill="currentColor"/><circle cx="14.6" cy="14.6" r="1.3" fill="currentColor"/>
      <circle cx="11" cy="11" r="1.3" fill="currentColor"/>`,
  backgammon: `<rect x="3" y="3" width="16" height="16" rx="2.4" fill="none" stroke="currentColor" stroke-width="1.5"/>
      <path d="M6 4.5l2.4 6L10.8 4.5z" fill="currentColor"/>
      <path d="M11.2 17.5l2.4-6 2.4 6z" fill="currentColor"/>`,
  bowling: `<path d="M11 3.4c2.4 0 3.6 2.6 3.4 6-.2 2.6-.6 4.4-.6 6.4 0 1.8-1.2 2.8-2.8 2.8s-2.8-1-2.8-2.8c0-2-.4-3.8-.6-6.4-.2-3.4 1-6 3.4-6z"
      fill="none" stroke="currentColor" stroke-width="1.5"/><circle cx="11" cy="6.6" r="1.1" fill="currentColor"/>`,
};

export function glyph(gameId, size = 24) {
  const d = GLYPHS[gameId];
  if (!d) return `<svg viewBox="0 0 22 22" width="${size}" height="${size}" aria-hidden="true"></svg>`;
  return `<svg viewBox="0 0 22 22" width="${size}" height="${size}" aria-hidden="true" focusable="false">${d}</svg>`;
}
