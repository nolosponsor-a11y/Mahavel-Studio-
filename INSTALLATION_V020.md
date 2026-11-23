# MAHAVEL Studio — Passage de V0.1.0 à V0.2.0

## Important : ne perdez pas vos données

Cette mise à jour ne remplace pas votre projet Supabase. **Ne rejouez surtout pas `001_initial.sql`** et ne supprimez aucune table. Les anciens projets, tâches, événements, messages, documents et comptes sont conservés.

La V0.2.0 n'a **pas été testée contre votre projet Supabase réel** : effectuez les tests ci-dessous avant de l'utiliser en production. **Ne confiez pas encore de documents professionnels sensibles à la version de test.** Une sauvegarde de la base avant migration est fortement recommandée.

## 1. Faire une sauvegarde

Dans Supabase, exportez vos tables importantes (Table Editor → table → Export, si disponible) ou effectuez une sauvegarde SQL complète selon votre formule. Conservez cette copie en lieu sûr, hors du dépôt GitHub. Notez que les exports des tables ne sauvegardent pas le contenu binaire des fichiers Storage.

## 2. Installer la nouvelle migration SQL

- Ouvrez Supabase → SQL Editor → New query.
- Ouvrez le **nouveau** fichier `supabase/migrations/002_collaboration.sql` dans le Bloc-notes.
- Copiez tout le texte, collez-le dans SQL Editor, puis exécutez **Run** une seule fois.
- En cas d'erreur, conservez la capture complète et n'exécutez pas à nouveau la requête au hasard. La migration est encapsulée dans une transaction pour éviter un déploiement partiel.
- **Ne lancez pas `001_initial.sql` à nouveau.**

La migration ajoute les champs de profils et de documents, les participants aux conversations, les destinataires de fichiers, des fonctions contrôlées côté serveur, des politiques RLS et des notifications de base. Les couleurs des personnes nommées Loan, Muriel et Nicolas sont initialisées uniquement si leur `display_name` correspond exactement ; elles restent modifiables.

## 3. Récupérer et configurer les fichiers de l'application

- Le ZIP contient `js/config.js` avec des valeurs **placeholders** pour ne pas divulguer les clés de votre projet.
- Sur votre PC, **conservez votre `js/config.js` existant** (déjà configuré pour Supabase) et changez uniquement `VERSION` en `'0.2.0'`.
- Remplacez sur GitHub les autres fichiers à la racine : `index.html`, `style.css`, `sw.js`, `manifest.webmanifest`, le dossier `js` **sauf `js/config.js`**, et `assets`.
- Vous pouvez aussi publier le nouveau `js/config.js` **après avoir remis votre URL de projet et votre clé publique**. **Ne publiez jamais une clé `service_role` ou une clé secrète.**
- Les dossiers `supabase` et les fichiers Markdown peuvent être ajoutés au dépôt : ils ne contiennent pas de secrets dans ce ZIP.
- Attendez le succès de la publication dans GitHub → Actions / Settings → Pages, puis ouvrez le site et choisissez **Paramètres → Rechercher les mises à jour**. Rechargez éventuellement la page.

## 4. Tests avec deux comptes

1. Connexion administrateur (ancien compte).
2. Les anciens projets, tâches et documents sont toujours visibles.
3. Modifier votre pseudo, votre couleur et éventuellement votre photo ; recharger.
4. Créer une tâche attribuée à un autre membre rattaché au même workspace.
5. Créer une conversation **Privée**, puis vérifier depuis un troisième compte qu'elle n'est pas visible.
6. Partager un document uniquement à un destinataire, vérifier qu'il reçoit un message privé contenant le lien, puis vérifier qu'un troisième compte **ne peut pas** lire/télécharger le fichier.
7. Supprimer une tâche dont vous êtes le créateur ; un autre membre ne doit pas pouvoir supprimer une tâche hors de ses droits.
8. Vérifier la création d'événements et les créneaux d'emploi du temps.
9. Vérifier les états de réseau et les mises à jour PWA sur iPhone, Android et Windows.
10. Vérifier que Cron et la fonction `cleanup-files` sont réellement actifs pour les règles des 6/7 jours (c'est une **étape séparée**).

## Fonctionnalités / limites de cette livraison

**Implémenté dans ce ZIP, à tester contre Supabase** : nouvelle navigation, logo cliquable, icônes en haut, typographie, couleurs personnalisées, profil avec photo/pseudo/fonction/lien, tâches affectables, suppression sous RLS de tâches/projets/événements/messages de l'auteur, choix des destinataires de documents, messagerie privée et groupes, notifications automatiques de tâches et de messages privés, création rapide, horaires saisis à la main.

**Non terminé** : extraction fiable des horaires depuis les PDF (PDF à conserver comme document source, retranscription manuelle), mentions `@` déclenchant une notification ciblée, accusés de lecture, historique complet des modifications, validations avancées et calendriers jour/semaine, synchronisation hors ligne. La V0.2.0 ne doit pas être présentée comme complète pour ces fonctions.

**Sécurité et autorisations** : les nouveaux chats et fichiers privés sont protégés par RLS et par une nouvelle restriction du Storage, mais **les tests réels multi-comptes restent obligatoires**. L'ancien chat de groupe est converti en conversation générale pour conserver l'accès aux messages historiques. Les fichiers V0.1.0 restent visibles à l'ensemble du workspace, comme auparavant.

**Suppression fichiers** : l'auteur peut supprimer les fichiers qu'il a déposés ; la fonction serveur de nettoyage reste nécessaire et doit être testée séparément. Les messages supprimés après 7 jours le sont par le Cron existant. Un message associé à un document protégé n'entraîne pas la suppression du document.

## En cas de problème

Ne supprimez pas les anciennes tables. Notez la requête ou l'action en échec et le message exact. Si l'application affiche un refus RLS, vérifiez les politiques de la migration et le rattachement des comptes au bon workspace. Ne désactivez pas RLS pour faire disparaître l'erreur.
