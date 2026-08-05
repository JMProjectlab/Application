// État de l'application et persistance.
//
// Deux couches, comme côté iOS :
//   • localStorage : lecture instantanée et fonctionnement hors ligne ;
//   • Firestore : synchronisation entre appareils, activée seulement si une
//     configuration Firebase est fournie.
//
// Sans configuration, le site reste pleinement utilisable en local. C'est ce qui
// permet de le déployer et de l'essayer avant d'avoir créé le projet Firebase.

import { HUES } from "./data.js";
import { isFinished, winnerIndex } from "./engine.js";

const KEY_PLAYERS = "sm.players";
const KEY_SESSIONS = "sm.sessions";
const KEY_USER = "sm.user";
const KEY_LANG = "sm.languagePreference";
const KEY_THEME = "sm.theme";

export const state = {
  players: [],
  sessions: [],
  user: null,
  filter: "all",
  /** Renseigné par firebase.js quand la synchronisation est active. */
  sync: null,
};

const listeners = new Set();
export const onChange = (fn) => { listeners.add(fn); return () => listeners.delete(fn); };
function emit() { listeners.forEach((fn) => fn()); }

export const uid = () =>
  (crypto.randomUUID ? crypto.randomUUID() : `id-${Date.now()}-${Math.random().toString(16).slice(2)}`);

// --- Persistance locale ---------------------------------------------------

function readJSON(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}

function writeJSON(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* quota ou navigation privée */ }
}

export function load() {
  state.players = readJSON(KEY_PLAYERS, []);
  state.sessions = readJSON(KEY_SESSIONS, []);
  state.user = readJSON(KEY_USER, null);
}

function persistLocal() {
  writeJSON(KEY_PLAYERS, state.players);
  writeJSON(KEY_SESSIONS, state.sessions);
}

/** Enregistre, pousse vers Firestore si branché, puis redessine. */
export function commit() {
  persistLocal();
  state.sync?.push(state);
  emit();
}

// --- Préférences ----------------------------------------------------------

export const getLanguage = () => localStorage.getItem(KEY_LANG) || "system";
export const setLanguage = (v) => { localStorage.setItem(KEY_LANG, v); emit(); };
export const getTheme = () => localStorage.getItem(KEY_THEME) || "system";
export function setTheme(v) {
  localStorage.setItem(KEY_THEME, v);
  applyTheme();
  emit();
}
export function applyTheme() {
  const t = getTheme();
  if (t === "system") document.documentElement.removeAttribute("data-theme");
  else document.documentElement.setAttribute("data-theme", t);
}

// --- Compte ---------------------------------------------------------------

export function setUser(user) {
  state.user = user;
  if (user) writeJSON(KEY_USER, user);
  else localStorage.removeItem(KEY_USER);
  emit();
}

export function signOut() {
  state.sync?.stop();
  state.sync = null;
  setUser(null);
}

/** Efface tout, localement et côté serveur. Irréversible. */
export async function deleteEverything() {
  const sync = state.sync;
  state.players = [];
  state.sessions = [];
  state.sync = null;
  [KEY_PLAYERS, KEY_SESSIONS, KEY_USER].forEach((k) => localStorage.removeItem(k));
  state.user = null;
  emit();
  await sync?.deleteAll();
}

// --- Joueurs --------------------------------------------------------------

export function addPlayer(name, email = null) {
  const used = new Set(state.players.map((p) => p.colorIndex));
  let free = 0;
  while (free < HUES.length && used.has(free)) free++;
  if (free >= HUES.length) free = state.players.length % HUES.length;
  state.players.push({ id: uid(), name, colorIndex: free, email });
  commit();
}

export function removePlayer(id) {
  state.players = state.players.filter((p) => p.id !== id);
  commit();
}

export const playerById = (id) => state.players.find((p) => p.id === id);

// --- Parties --------------------------------------------------------------

export function createSession(game, entrants, target) {
  const session = {
    id: uid(),
    gameId: game.id,
    gameName: game.name,
    date: new Date().toISOString(),
    target,
    higherWins: game.high,
    direction: game.engine === "countdown" ? "countdown" : "accumulate",
    entrants,
    rounds: [],
    manuallyFinished: false,
    seriesWins: null,
    beloteRounds: game.id === "belote" ? [] : null,
    yamsGrid: game.engine === "grid"
      ? entrants.map(() => Array(13).fill(-1))
      : null,
    molkkyMisses: game.engine === "molkky" ? entrants.map(() => 0) : null,
    molkkyOut: game.engine === "molkky" ? entrants.map(() => false) : null,
  };
  state.sessions.unshift(session);
  commit();
  return session;
}

export const sessionById = (id) => state.sessions.find((s) => s.id === id);
export const activeSession = () => state.sessions.find((s) => !isFinished(s));

export function addRound(session, deltas) {
  session.rounds.push(deltas);
  commit();
}

export function undoRound(session) {
  if (!session.rounds.length) return;
  session.rounds.pop();
  session.manuallyFinished = false;
  commit();
}

export function deleteRound(session, index) {
  if (index < 0 || index >= session.rounds.length) return;
  session.rounds.splice(index, 1);
  if (session.beloteRounds && index < session.beloteRounds.length) {
    session.beloteRounds.splice(index, 1);
  }
  session.manuallyFinished = false;
  commit();
}

export function resetSession(session, keepSeries) {
  if (keepSeries) {
    // Le vainqueur se lit avant la remise à zéro, sinon il n'y en a plus.
    const w = winnerIndex(session);
    if (w !== null) {
      const series = session.seriesWins ?? session.entrants.map(() => 0);
      series[w] += 1;
      session.seriesWins = series;
    }
  } else {
    session.seriesWins = null;
  }
  session.rounds = [];
  if (session.beloteRounds) session.beloteRounds = [];
  if (session.yamsGrid) session.yamsGrid = session.entrants.map(() => Array(13).fill(-1));
  if (session.molkkyMisses) {
    session.molkkyMisses = session.entrants.map(() => 0);
    session.molkkyOut = session.entrants.map(() => false);
  }
  session.manuallyFinished = false;
  commit();
}

export function finishSession(session) {
  session.manuallyFinished = true;
  commit();
}

export function deleteSession(id) {
  state.sessions = state.sessions.filter((s) => s.id !== id);
  commit();
}

// --- Fusion avec le serveur ----------------------------------------------

/**
 * Applique ce qui vient de Firestore. Comme sur iOS, une absence côté serveur
 * ne supprime rien : elle peut simplement signifier que l'entrée locale n'a pas
 * encore été poussée.
 */
export function mergeRemote({ players, sessions }) {
  if (players?.length) {
    const byId = new Map(state.players.map((p) => [p.id, p]));
    players.forEach((p) => byId.set(p.id, p));
    state.players = [...byId.values()].sort((a, b) => a.name.localeCompare(b.name));
  }
  if (sessions?.length) {
    const byId = new Map(state.sessions.map((s) => [s.id, s]));
    sessions.forEach((s) => byId.set(s.id, s));
    state.sessions = [...byId.values()].sort((a, b) => (a.date < b.date ? 1 : -1));
  }
  persistLocal();
  emit();
}
