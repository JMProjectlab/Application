// Configuration de l'application web Firebase du projet `scorenade-d6ced`.
// Source : console Firebase → Paramètres du projet → Vos applications → Web.
//
// Tant que `apiKey` vaut « REMPLACER », le site fonctionne en local : les parties
// sont conservées dans le navigateur, sans compte ni synchronisation, et l'écran
// de connexion ne s'affiche pas. C'est le repli voulu, pas une panne.
//
// Ces clés ne sont pas des secrets — elles partent dans le navigateur de chaque
// visiteur. Ce qui protège les données, ce sont les règles Firestore
// (`firestore.rules` à la racine du dépôt), qui n'autorisent chaque compte que
// sur ses propres documents.

export const firebaseConfig = {
  apiKey: "AIzaSyAwV1xPFIbhB5PQZDeKW9_o2fHmneSdXDU",
  authDomain: "scorenade-d6ced.firebaseapp.com",
  projectId: "scorenade-d6ced",
  storageBucket: "scorenade-d6ced.firebasestorage.app",
  messagingSenderId: "863817285373",
  appId: "1:863817285373:web:8f640306916e1a4ac18894",
  measurementId: "G-DX49YMYQ57",
};
