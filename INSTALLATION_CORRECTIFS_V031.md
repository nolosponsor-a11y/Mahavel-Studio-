# MAHAVEL Studio 0.3.1 — Correctifs de mise à jour

## Pourquoi cette version
La base de données V0.3.0 a déjà été mise à jour sur Supabase. **N'exécutez aucun nouveau script SQL**, et ne réinstallez ni Docker ni Node.js.

## IMPORTANT — Ne pas perdre la connexion Supabase
Le fichier `js/config.js` est **volontairement absent** de ce ZIP de mise à jour. Il doit rester inchangé dans votre dépôt GitHub existant. Ne remplacez jamais votre clé publique par des valeurs d'exemple et n'utilisez jamais de clé service_role sur GitHub.

## Sur GitHub Pages
Dépôt : https://github.com/nolosponsor-a11y/Mahavel-Studio-

1. Décompressez le ZIP sur votre PC. La racine du dépôt contient `index.html` et `style.css` : ne téléversez pas le dossier parent comme nouveau répertoire.
2. À la racine du dépôt, remplacez `index.html`, `style.css`, `sw.js`, `manifest.webmanifest`, et `assets/icon.svg`.
3. Dans `js/`, remplacez `app.js`, `service.js`, `icons.js`.
4. Ne changez **pas** `js/config.js`. L'interface affiche 0.3.1 sans le modifier.
5. Attendez la publication GitHub Pages puis, dans MAHAVEL Studio → Paramètres → Rechercher les mises à jour, chargez la mise à jour. Fermez les formulaires avant de recharger.

## Modifications réalisées
- Nouvelle interface 0.3.x et suppression du menu Projets (données conservées en base)
- Messagerie : recherche d'une conversation et consultation des messages enregistrés ; menu contextuel, réponse, like, partage et suppression conditionnelle préexistants dans le code 0.3.0
- Planning : création, sélection, **renommage/description** des calendriers secondaires, import JSON, double confirmation pour suppression
- Emplois du temps individuels par profil, import JSON
- Tâches : import JSON et formulaire complet
- Fichiers : partage à des destinataires précis et transferts jusqu'à 50 Mio si autorisés par les limites du projet Supabase
- Correction du fuseau horaire La Réunion pour les indisponibilités
- Chargement de 1000 lignes au lieu de 150 par table et signalement des erreurs plutôt qu'un écran vide silencieux
- Correction pour ne pas réaffecter le créateur d'une tâche ou d'un événement au cours de sa modification
- Version de cache PWA actualisée

## Limitations honnêtes
- **Appels audio et vidéo** : non implémentés. Il faut un véritable WebRTC, un système de signalisation, et souvent un relais TURN pour des appels fiables.
- **Import automatique de PDF d'horaires** : non implémenté. Utilisez un JSON préparé à partir de votre PDF.
- **Nettoyage automatique Storage après 6 jours** : dépend du déploiement de la fonction serveur `supabase/functions/cleanup-files` et de son ordonnanceur ; le fichier de fonction seul ne déclenche pas le nettoyage.
- Les tests effectués sont statiques (syntaxe et contrôles du paquet) ; les parcours connectés en production et le rendu navigateur complet restent à valider après publication.
- Le ZIP ne contient aucune sauvegarde privée : gardez vos fichiers SQL/Auth/Storage hors GitHub.
