// Graphiques — SVG écrit à la main, sans bibliothèque.
//
// Trois formes seulement, chacune choisie pour le travail qu'elle fait :
//   • l'anneau, pour une répartition — au coup d'œil, six parts au maximum ;
//   • les barres horizontales, pour comparer des grandeurs ;
//   • la jauge, pour un taux face à son plafond.
//
// Ce qu'on ne fait pas, et pourquoi : pas de camembert à deux parts pour
// « gagnées / perdues » — deux nombres se lisent mieux écrits que découpés — et
// pas de couleur par rang, sinon filtrer repeindrait les survivants et le
// lecteur qui avait retenu « la belote est en bleu » serait trompé.

/** Échappe le texte destiné au balisage. Les noms de joueurs viennent de la
 *  saisie : ils ne sont pas de confiance. */
const esc = (s) => String(s).replace(/[&<>"']/g,
  (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

/** Les six créneaux, dans l'ordre validé. Au-delà, on replie sur « Autres » —
 *  jamais une septième teinte générée, indistinguable des autres en vision
 *  daltonienne. */
export const SLOTS = ["var(--s1)", "var(--s2)", "var(--s3)", "var(--s4)", "var(--s5)", "var(--s6)"];
export const MAX_SLICES = 6;

/**
 * Replie une série trop longue sur « Autres ».
 * Renvoie au plus MAX_SLICES entrées, la dernière cumulant la queue.
 */
export function foldTail(entries, max = MAX_SLICES) {
  if (entries.length <= max) return entries;
  const head = entries.slice(0, max - 1);
  const tail = entries.slice(max - 1);
  return [...head, {
    key: "__autres__",
    label: "Autres",
    value: tail.reduce((n, e) => n + e.value, 0),
    count: tail.length,
  }];
}

/**
 * Anneau de répartition.
 *
 * Les parts sont tracées au trait sur un cercle : un `stroke-dasharray` par
 * segment, raccourci de 2 px pour laisser respirer le fond entre deux parts.
 * C'est le fond qui sépare, pas un contour — un contour ajouterait de l'encre
 * qui ne porte aucune donnée.
 */
export function donut(entries, { size = 168, thickness = 26, centerValue, centerLabel } = {}) {
  const total = entries.reduce((n, e) => n + e.value, 0);
  if (!total) return "";

  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const GAP = 2;

  let offset = 0;
  const arcs = entries.map((e, i) => {
    const len = (e.value / total) * c;
    // Une part minuscule ne doit pas disparaître sous l'écart : on la garde
    // visible plutôt que de la faire mentir par absence.
    const drawn = Math.max(1, len - GAP);
    const arc = `<circle class="arc" r="${r}" cx="${size / 2}" cy="${size / 2}"
        fill="none" stroke="${SLOTS[i % SLOTS.length]}" stroke-width="${thickness}"
        stroke-dasharray="${drawn.toFixed(2)} ${(c - drawn).toFixed(2)}"
        stroke-dashoffset="${(-offset).toFixed(2)}"
        data-slice="${i}" tabindex="0" role="listitem"
        aria-label="${esc(e.label)} : ${e.value}">
        <title>${esc(e.label)} — ${e.value}</title></circle>`;
    offset += len;
    return arc;
  }).join("");

  const middle = centerValue === undefined ? "" :
    `<text x="${size / 2}" y="${size / 2 - 2}" class="donut-v" text-anchor="middle">${esc(centerValue)}</text>
     <text x="${size / 2}" y="${size / 2 + 16}" class="donut-k" text-anchor="middle">${esc(centerLabel ?? "")}</text>`;

  // Rotation d'un quart de tour : la première part démarre en haut, là où l'œil
  // commence.
  return `<svg class="donut" viewBox="0 0 ${size} ${size}" width="${size}" height="${size}"
      role="list" aria-label="Répartition">
      <g transform="rotate(-90 ${size / 2} ${size / 2})">${arcs}</g>${middle}</svg>`;
}

/**
 * Légende de l'anneau.
 *
 * Elle porte toujours la valeur écrite. Ce n'est pas un ornement : en mode
 * clair, deux des six teintes passent sous 3:1 face au fond, et la règle est
 * alors que la valeur soit lisible autrement que par la couleur.
 */
export function donutLegend(entries) {
  const total = entries.reduce((n, e) => n + e.value, 0) || 1;
  return `<ul class="legend">` + entries.map((e, i) =>
    `<li><span class="key" style="background:${SLOTS[i % SLOTS.length]}"></span>
      <span class="lb">${esc(e.label)}</span>
      <span class="lv tab">${e.value} · ${Math.round((e.value / total) * 100)} %</span></li>`).join("")
    + `</ul>`;
}

/**
 * Barres horizontales, une seule teinte.
 *
 * Comparer des grandeurs est le travail d'une longueur, pas d'une couleur :
 * colorier chaque barre selon sa valeur dépenserait le canal identité à
 * réécrire ce que la longueur montre déjà.
 */
export function bars(entries, { max, unit = "" } = {}) {
  if (!entries.length) return "";
  const top = max ?? Math.max(...entries.map((e) => e.value), 1);
  return `<div class="bars">` + entries.map((e) => {
    const pct = top ? Math.max(0, Math.min(100, (e.value / top) * 100)) : 0;
    return `<div class="bar-row" tabindex="0" title="${esc(e.label)} — ${esc(e.hint ?? (e.value + unit))}">
      <span class="bar-lb">${e.lead ?? ""}<span class="nm">${esc(e.label)}</span></span>
      <span class="bar-track"><span class="bar-fill" style="width:${pct.toFixed(1)}%"></span></span>
      <span class="bar-v tab">${esc(e.display ?? (e.value + unit))}</span></div>`;
  }).join("") + `</div>`;
}

/**
 * Jauge — un taux face à son plafond.
 *
 * C'est la forme juste pour « x % de victoires » : un camembert à deux parts
 * dirait la même chose en moins lisible.
 */
export function meter(pct, label) {
  const v = Math.max(0, Math.min(100, pct));
  return `<div class="meter" role="img" aria-label="${esc(label)} : ${v} %">
      <span class="meter-fill" style="width:${v}%"></span></div>`;
}
