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
- **Build → Authentication → Get started** — activer les fournisseurs **Apple**
  *et* **Google**. Les deux sont obligatoires : l'application n'a plus de mode
  invité, et la règle 4.8 d'Apple impose « Se connecter avec Apple » dès lors
  qu'un autre service de connexion tiers est proposé.

> **Le fournisseur Apple demande deux niveaux d'effort selon la cible.**
>
> Pour l'**app iOS**, il suffit de l'activer : rien d'autre à renseigner, Apple
> et Firebase s'entendent via le bundle identifier.
>
> Pour le **site web**, Firebase réclame en plus un **Services ID**, ton **Team
> ID**, un **Key ID** et une **clé privée `.p8`**, tous à créer côté
> <https://developer.apple.com> (Certificates, Identifiers & Profiles). C'est
> une demi-heure de manipulations, et la clé privée ne se télécharge qu'une
> seule fois.
>
> Rien n'oblige à tout faire d'un coup : le site peut très bien sortir avec la
> **connexion Google seule** — la règle 4.8 d'Apple encadre l'App Store, pas un
> site web. Il suffit alors de masquer le bouton Apple dans `docs/assets/ui.js`
> en attendant. L'app iOS, elle, a besoin des deux, mais sans cette paperasse.

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

Puis un **second paquet**, pour la connexion Google :

- URL : `https://github.com/google/GoogleSignIn-iOS`
- Produit : `GoogleSignIn`

> Je n'ai pas fait cette étape à ta place volontairement : ajouter une
> référence de paquet en modifiant `project.pbxproj` à la main, sans pouvoir
> ouvrir Xcode pour vérifier, risque de produire un projet qui refuse de
> s'ouvrir. Trente secondes dans l'interface, et c'est fiable.

## 3 bis. Déclarer le schéma d'URL de Google

Sans cette étape, la feuille de connexion Google s'ouvre mais ne revient jamais
dans l'application.

1. Ouvre `GoogleService-Info.plist` et copie la valeur de **`REVERSED_CLIENT_ID`**
   (elle ressemble à `com.googleusercontent.apps.1234567890-abcdef`).
2. Dans Xcode, cible Scornade → onglet **Info** → **URL Types** → **+**
3. Colle cette valeur dans le champ **URL Schemes**.

Je ne peux pas préparer ce réglage : la valeur est propre à ton projet Firebase
et n'existe que dans le fichier que tu vas télécharger.

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

## La connexion est obligatoire

Il n'y a plus de mode invité : on entre dans l'application par Apple ou par
Google, sans autre porte. Deux conséquences à garder en tête.

**Au tout premier lancement, le réseau est indispensable.** Une fois connecté,
Firebase conserve la session et l'application se relance et fonctionne hors
ligne sans problème — mais quelqu'un qui installe Scornade dans un endroit sans
réseau ne pourra pas s'en servir. C'est le prix d'un compte obligatoire.

**Prévois un compte de test pour la revue Apple.** Les relecteurs refusent
régulièrement les applications dont ils ne peuvent pas franchir l'écran de
connexion. Renseigne des identifiants de démonstration dans App Store Connect,
rubrique « Informations de connexion ».
