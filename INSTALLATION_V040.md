# MAHAVEL Studio — V0.4.0 candidate (24 novembre 2026)

## Statut réel

Cette livraison **n'est pas une version de production validée** : la syntaxe du code est vérifiée, mais l'authentification, la messagerie, les appels et la RLS demandent un essai avec au moins deux vrais utilisateurs sur deux appareils. **Ne déployez pas sans une recette sur environnement de test.** Aucun changement serveur n'a été appliqué au projet de production pour la V0.4.0.

## Contenu

- `SITE_GITHUB` dans l'archive de mise à jour : remplacer à la racine du dépôt, sans sous-dossier supplémentaire.
- **Ne jamais écraser `js/config.js`** du GitHub actuel. Il est exclu du pack de mise à jour.
- `supabase/migrations/004_quality_calls_read_receipts.sql` : migration additive à vérifier avant exécution, ajoute lecture des messages, clés d'import, appels, notifications de tâches, validation atomique et durcissement de fonctions.
- `supabase/functions/cleanup-expired-files/index.ts` : fonction serveur de nettoyage des fichiers à installer séparément (ne s'exécute pas avec le simple dépôt GitHub).

## Ordre d'installation après validation

1. Garder les copies SQL et ZIP de sauvegarde existantes, ainsi que le ZIP de l'ancienne version de GitHub.
2. Tester la migration 004 sur un **projet de test** issu d'une copie pertinente de la base. Les exports ne constituent pas une restauration éprouvée.
3. Appliquer 004 à Supabase puis vérifier RLS avec deux utilisateurs authentifiés distincts.
4. Déployer les fichiers du site sur une branche de prévisualisation, puis tester sur PC/iPhone.
5. Configurer `cleanup-expired-files` côté Supabase Edge Functions avec une variable secrète `MAHAVEL_CLEANUP_SECRET` (long secret aléatoire), **jamais dans GitHub ni dans une page publique**. Prévoir une invocation planifiée authentifiée via `x-mahavel-cron-secret`. `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` restent des variables serveur uniquement. Sans cette étape, le nettoyage après 6 jours **n'est pas actif**.
6. Confirmer les tests avant remplacement du site principal.

## Appels audio et vidéo

Les appels WebRTC sont prévus **uniquement dans les conversations privées à deux personnes**. Ils nécessitent l'autorisation micro/caméra, HTTPS et la migration 004. Le signal est échangé dans Supabase, mais le flux audio/vidéo utilise une liaison directe WebRTC. **Pas de serveur TURN fourni** : certains réseaux mobiles, VPN ou pare-feu empêcheront les appels de se connecter. Les appels de groupe ne sont pas fournis.

## Limites connues

- Les notifications sont **internes à l'application**, pas des notifications push iOS/Android ni des appels entrants quand l'application est fermée.
- Le compteur des messages non lus porte sur les messages récemment chargés dans l'application ; les conversations historiques extrêmement longues nécessiteraient une agrégation serveur.
- La déduplication des imports se fonde sur des champs métier (tâches : titre, responsable, date ; événements : calendrier, titre, dates ; horaires : personne, date/jour, horaires, libellé) et une clé unique. Deux éléments volontairement identiques seront traités comme doublons.
- Le nettoyage ne supprime que les documents répertoriés comme expirés dans `public.documents`. Les **fichiers orphelins** sont conservés pour éviter de supprimer d'anciens fichiers qui ne seraient plus reliés à une ligne de table.
- Les imports directs PDF et le mode hors ligne avancé sont exclus à la demande.

## Recette minimale avant production

- [ ] Connexion de deux comptes différents et contrôle de leurs permissions
- [ ] Conversation privée : réception, réponse, réaction, lecture/non-lu, suppression autorisée
- [ ] Conversation de groupe : isolation, destinataires et permissions
- [ ] Appels audio et vidéo en Wi-Fi, puis réseau mobile (tester TURN si échec)
- [ ] Création, affectation, validation et corrections demandées pour une tâche
- [ ] Import JSON deux fois : aucun doublon
- [ ] Fichier privé ciblé : inaccessible à une tierce personne non autorisée
- [ ] Fichier marqué « À conserver » : intact à l'expiration
- [ ] Fichier expiré sur un projet de test : supprimé de `documents` ET `storage.objects`
- [ ] Affichage PC, iPhone Safari, Android Chrome et PWA installée
- [ ] Mise à jour SW sans effacement de données ni autres caches
