// Copiez ce fichier en `firebase-config.js` (même dossier) et remplissez-le avec
// les valeurs de votre application web Firebase :
//   console Firebase → Paramètres du projet → Vos applications → Web → Configuration
//
// Tant que `firebase-config.js` n'existe pas, le site fonctionne en local :
// les parties sont conservées dans le navigateur, sans compte ni synchronisation.
//
// Ces clés ne sont pas des secrets — elles partent dans le navigateur de chaque
// visiteur. Ce qui protège les données, ce sont les règles Firestore
// (`firestore.rules` à la racine du dépôt), qui n'autorisent chaque compte que
// sur ses propres documents.

export const firebaseConfig = {
  apiKey: "REMPLACER",
  authDomain: "REMPLACER.firebaseapp.com",
  projectId: "REMPLACER",
  storageBucket: "REMPLACER.appspot.com",
  messagingSenderId: "REMPLACER",
  appId: "REMPLACER",
};
