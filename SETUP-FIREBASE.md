# Mise en place de Firebase

Le code est prêt : il ne reste que les étapes qui demandent ton compte Google et
Xcode. Tant qu'elles ne sont pas faites, **l'application démarre et fonctionne
normalement en local** — `FirebaseSupport` détecte l'absence de configuration et
désactive simplement la synchronisation.

## 1. Créer le projet Firebase

Sur <https://console.firebase.google.com> → **Ajouter un projet**.

> **Choix irréversible :** à la création de la base Firestore, sélectionne
> l'emplacement **`eur3` (europe-west)**. On ne peut pas en changer ensuite sans
> recréer le projet, et la politique de confidentialité annonce un hébergement
> dans l'Union européenne.

Puis :

- **Build → Firestore Database → Créer une base** — mode production, région `eur3`.
- **Build → Authentication → Get started** — activer le fournisseur **Apple**.

## 2. Enregistrer l'application iOS

Dans les réglages du projet → **Ajouter une application** → iOS.

- Identifiant du bundle : `JMProject.Scornade`
- Télécharger **`GoogleService-Info.plist`**
- Le glisser dans Xcode, dans le dossier `Scornade/Scornade/`, en cochant
  « Copy items if needed » et en visant la cible **Scornade**

Ce fichier contient des identifiants propres à ton projet. Il n'est pas secret au
sens d'un mot de passe (il part dans chaque copie de l'app), mais il n'a rien à
faire dans un dépôt public : `.gitignore` l'exclut déjà.

## 3. Ajouter le SDK Firebase

Dans Xcode : **File → Add Package Dependencies…**

- URL : `https://github.com/firebase/firebase-ios-sdk`
- Règle de version : « Up to Next Major »
- Cocher uniquement ces trois produits, pour ne pas alourdir l'app :
  - `FirebaseAuth`
  - `FirebaseFirestore`
  - `FirebaseCore` *(ajouté automatiquement par les deux précédents)*

> Je n'ai pas fait cette étape à ta place volontairement : ajouter une
> référence de paquet en modifiant `project.pbxproj` à la main, sans pouvoir
> ouvrir Xcode pour vérifier, risque de produire un projet qui refuse de
> s'ouvrir. Trente secondes dans l'interface, et c'est fiable.

## 4. Publier les règles de sécurité

Le fichier `firestore.rules` à la racine du dépôt contient les règles à appliquer.
Copie son contenu dans **Firestore Database → Règles**, puis **Publier**.

Sans cette étape, la base reste soit fermée à tout le monde, soit — pire —
ouverte à tous si tu as choisi le mode test à la création.

## 5. Capacités Xcode

Dans **Signing & Capabilities** de la cible Scornade :

- **Sign in with Apple** doit être présent (le fichier d'entitlements le déclare déjà)
- **iCloud / CloudKit n'est plus utilisé** : si la capacité est encore là, retire-la

## 6. Vérifier

1. Lancer l'app, se connecter avec Apple, créer une partie.
2. Dans la console Firebase → Firestore, la partie doit apparaître sous
   `users/{ton-uid}/sessions/{id}`.
3. Passer l'appareil en mode avion, saisir des manches, revenir en ligne :
   Firestore rejoue les écritures en attente tout seul.
4. Tester « Supprimer mes données » : les documents **et** le compte
   Authentication doivent disparaître (c'est ce qu'exige la règle 5.1.1(v)
   d'Apple sur la suppression de compte).

## Ce que le mode invité ne fait pas

Le mode invité ne contacte jamais Firebase : aucun compte anonyme n'est créé,
rien ne part sur le réseau. C'est ce que promet l'écran de connexion, et la
politique de confidentialité le reprend. Si tu veux un jour que les invités
soient synchronisés aussi, il faudra activer l'authentification anonyme **et**
corriger ces deux textes.
