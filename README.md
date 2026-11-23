# MAHAVEL Studio V0.2.0 — mise à jour de la V0.1.0

**Pour mettre à jour votre application existante, suivez d’abord `INSTALLATION_V020.md`.**
Ne rejouez pas `001_initial.sql` : exécutez uniquement `002_collaboration.sql` après avoir sauvegardé votre base.
Le ZIP contient une configuration Supabase volontairement vide ; conservez la vôtre.
Les nouvelles fonctionnalités sont **à tester sur votre Supabase réel** ; cette livraison n’a pas été validée par un test multi-comptes ni sur des appareils physiques.
L’import automatique d’emplois du temps PDF, les confirmations de lecture, les mentions @ et l’historique exhaustif restent à réaliser.

---

## Documentation initiale V0.1.0 (conservée pour référence)

# MAHAVEL STUDIO — version de base 0.1.0

Application PWA collaborative **en développement**, conçue pour GitHub Pages + Supabase. Le code comporte de vraies requêtes Supabase, mais **n'a pas été testé sur un projet Supabase réel ni sur des téléphones**. Ne pas considérer cette version comme prête pour des documents confidentiels avant les tests de sécurité.

## Ce qui est codé

- Écran de connexion e-mail/mot de passe Supabase, session persistante, réinitialisation par e-mail.
- Un espace de travail avec comptes rattachés et RLS, rôles administrateur/responsable/collaborateur.
- Accueil connecté aux données, calendrier mensuel avec navigation (y compris changement d'année), ajout/modification d'événements.
- Tâches : création, affectation, changement de statut, priorité, échéance ; projets : création et édition.
- Chat de groupe d'espace ; messages envoyés au serveur et diffusés via Supabase Realtime.
- Fichiers privés Supabase : transfert (limite 10 Mo), téléchargement par lien signé, protection « À conserver », suppression.
- Liens externes HTTPS (WeTransfer notamment), indisponibilités de collaborateurs, panneau notifications en lecture.
- PWA installable (sous réserve du support navigateur) avec bouton de recherche de mise à jour.
- SQL de création, RLS et expiration des messages après 7 jours (Cron SQL).
- Fonction Edge pour nettoyage des documents expirés après 6 jours, **à déployer et planifier séparément**.

## Ce qui reste à développer ou vérifier

Ce n'est **pas encore** l'application complète du cahier des charges. Manquent : invitations administrées dans l'interface, conversations privées et membres par conversation, vue calendrier jour/semaine/liste, filtres avancés, édition des participants, conflits d'horaires, liens entre tâches et projets dans les formulaires, checklist, commentaires et pièces jointes des tâches, validation de contenu réellement exploitable, notifications automatiques, protection contre modification concurrente, recherches et pagination avancées, audit automatique, dossier détaillé par projet, sélecteur d'emploi du temps par collègue, tests multi-comptes et tests physiques. Le mode hors ligne ne synchronise pas les modifications. Les couleurs utilisées sont **provisoires**, pas présentées comme la charte officielle MAHAVEL ; le logo est un monogramme provisoire.

## Configuration, étape par étape

1. Ouvrez https://supabase.com et créez un projet (choisissez un mot de passe de base de données solide). Conservez la région proposée ; configurez le projet pour le traitement des données de votre entreprise.
2. Dans **SQL Editor**, collez le contenu de `supabase/migrations/001_initial.sql` et exécutez-le **une fois**, sur un projet neuf. En cas d'erreur, n'insistez pas : vérifiez la ligne SQL signalée avant toute opération.
3. Dans **Authentication > Users**, créez le premier utilisateur (le vôtre) et confirmez son e-mail. Désactivez les inscriptions publiques si le studio veut fonctionner uniquement sur invitation. Configurez les URL de redirection dans **Authentication > URL Configuration** après avoir obtenu l'adresse GitHub Pages.
4. Dans SQL Editor, exécutez ce SQL en **remplaçant les deux valeurs** par l'e-mail exact de votre compte et le nom d'espace souhaité :

```sql
insert into public.workspaces(name) values ('MAHAVEL Studio');
insert into public.memberships(workspace_id,user_id,role)
select w.id,u.id,'admin'
from public.workspaces w cross join auth.users u
where w.name='MAHAVEL Studio' and u.email='VOTRE_EMAIL_ICI';
```

5. Pour créer les autres comptes, utilisez **Authentication > Users > Add user**, puis rattachez chaque compte. Exemple SQL (exécutez pour chaque e-mail) :

```sql
insert into public.memberships(workspace_id,user_id,role)
select w.id,u.id,'member'
from public.workspaces w cross join auth.users u
where w.name='MAHAVEL Studio' and u.email='COLLABORATEUR@EXEMPLE.FR';
```

6. Dans **Project Settings > API / Data API**, récupérez l'URL du projet et sa **clé publishable** ou **anon** (publique). Dans `js/config.js` renseignez ces deux valeurs. **N'utilisez jamais la clé service_role.** La clé publique est prévue pour le navigateur ; la sécurité est assurée par les règles RLS.
7. Sur GitHub, créez un dépôt distinct. Importez **le contenu du dossier** `mahavel-studio` à la racine du dépôt, pas le ZIP non extrait. Dans **Settings > Pages**, choisissez « Deploy from a branch », branche `main`, dossier `/ (root)` ; attendez l'URL de l'application. N'envoyez pas d'identifiants privés sur GitHub.
8. Sur iPhone, ouvrez l'URL dans Safari, puis **Partager > Sur l'écran d'accueil**. Sur Android, ouvrez-la dans Chrome et choisissez **Installer** / **Ajouter à l'écran d'accueil**. Sur Windows, un navigateur compatible peut proposer l'installation.
9. Testez avec deux comptes différents sur deux appareils, et les autorisations d'accès, avant toute utilisation en production.

### Nettoyage automatique des fichiers (obligatoire en production)

La fonction serveur `supabase/functions/cleanup-files/index.ts` doit être déployée avec Supabase CLI :

```bash
supabase login
supabase link --project-ref VOTRE_REFERENCE_PROJET
supabase secrets set CRON_SECRET=UNE_VALEUR_LONGUE_ALEATOIRE
supabase functions deploy cleanup-files --no-verify-jwt
```

La fonction attend la requête `POST https://VOTRE_REFERENCE_PROJET.supabase.co/functions/v1/cleanup-files` avec l'en-tête `Authorization: Bearer VOTRE_CRON_SECRET`. **Ne mettez pas ce secret dans GitHub Pages ou JavaScript.** Dans Supabase, configurez un job Cron HTTP vers cette fonction (p. ex. toutes les heures) et utilisez **Supabase Vault** ou un mécanisme sécurisé équivalent pour stocker le secret d'appel. Le service role de la fonction est fourni uniquement dans l'environnement sécurisé Edge Functions. Surveillez les erreurs et les résultats dans les logs de la fonction. **Sans ce job, les fichiers expirés restent physiquement stockés** bien qu'ils soient masqués par RLS. Les messages sont éliminés par le Cron SQL toutes les 15 minutes et cachés par RLS dès expiration.

Pour une planification fiable du nettoyage des fichiers, consultez la documentation officielle : https://supabase.com/docs/guides/cron et https://supabase.com/docs/guides/functions/schedule-functions

### Mises à jour

Modifiez les fichiers du dépôt, incrémentez `VERSION` dans `js/config.js` et le nom `CACHE` dans `sw.js`, puis publiez. Le bouton **Rechercher les mises à jour** demande au navigateur de vérifier la nouvelle version du service worker. L'application ne redémarre pas automatiquement si une saisie est active. **Attention** : les mises à jour CSS/JS peuvent nécessiter un rechargement manuel selon le navigateur et les caches.

### Confidentialité, restrictions et conservation

- Ne déposez pas de documents confidentiels tant que les scénarios d'accès non autorisé, les liens signés, les journaux et le nettoyage ne sont pas vérifiés.
- **Fichiers :** 6 jours à compter de la création serveur, sauf « À conserver ». **Chat :** 7 jours à compter de la création serveur. Les pièces jointes de chat ne sont pas encore proposées.
- Les fichiers protégés restent dans Documents ; ils ne sont pas éliminés par le job d'expiration.
- Le stockage confidentiel ne doit pas être ajouté à la mise en cache PWA.
- Les conversations de cette V0.1 sont communes aux membres de l'espace, et non privées.
- Le rôle administrateur n'est pas attribué par le nom ; il est affecté explicitement en base.
- Ne communiquez jamais la clé `service_role` ou le secret Cron dans les captures ou dépôts GitHub.

### Offre Supabase

Les quotas du Free Plan changent. Vérifiez à la date de déploiement https://supabase.com/pricing ; le service gratuit indiquait notamment 500 Mo de base de données et 1 Go de stockage lors de la préparation, sans garantie qu'ils restent identiques. Le projet peut être mis en veille en cas d'inactivité. Les vidéos volumineuses doivent être partagées par lien externe plutôt que stockées directement.

## Arborescence

- `index.html`, `style.css` : point d'entrée / design system
- `js/app.js` : navigation et modules fonctionnels de l'interface (à découper davantage ensuite)
- `js/service.js` : accès Supabase
- `js/config.js` : URL + clé publique et version
- `js/icons.js` : icônes vectorielles
- `manifest.webmanifest`, `sw.js`, `assets/icon.svg` : PWA
- `supabase/migrations/001_initial.sql` : tables, sécurité RLS, tâches d'expiration
- `supabase/functions/cleanup-files/index.ts` : nettoyage serveur du stockage
- `TESTS.md` : scénario de recette et limites

## Choix de style

Interface dense, presque carrée, fond charbon et accent minéral neutre **provisoire**. Typographie système condensée (Arial Narrow selon appareil), sans police externe obligatoire. L'identité et les vrais éléments de marque doivent être intégrés après obtention de la charte MAHAVEL. Cette version n'utilise pas de blocs de statistiques fictifs.
