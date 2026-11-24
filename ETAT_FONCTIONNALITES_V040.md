# État factuel — MAHAVEL Studio V0.4.0 (candidate)

Ceci décrit du code **préparé, pas une production éprouvée**.

| Demande retenue | Implémentation | À faire avant de déclarer terminé |
|---|---|---|
| Audio/vidéo | WebRTC 1:1 + table de signalisation sécurisée | Migration 004, deux appareils, TURN si réseaux difficiles, essais de réception |
| Fichiers à 6 jours | Edge Function vérifiant `keep=false` et supprimant objet + ligne | Déployer, protéger par secret, planifier, tester expirations dans un projet de test |
| Synchronisation/confidentialité | RLS nouvelles tables; correction des règles Storage erronées | Tests RLS avec profils distincts, audit existant complet |
| Non lus et notifications | Table `conversation_reads`, badges, notifications de tâche | Test réel messages/affectations, compteurs historiques, aucune push native |
| Imports sans doublons | SHA-256 métier, UNIQUE `(workspace_id, import_key)`; détection sur lignes existantes chargées | Test double import et imports concurrents avec comptes réels |
| Validation contenus | RPC atomique manager : approuver/demander correction + traçabilité | Circuit spécifique Muriel/Hugo/Romain et validation multi-niveaux **non automatisés** |
| Direction artistique | Palette bordeaux/gris nuit, typographie et écrans revisités | Validation de la charte réelle MAHAVEL par l'équipe |
| PC/mobile | CSS responsive, tactile 44px, clavier, réduction d'animations | Tests visuels réels impossibles dans cet environnement |
| Recette complète | Tests de syntaxe, cohérence de fichiers/archives, contrôle live des politiques existantes | Parcours end-to-end connecté et validation à plusieurs utilisateurs non réalisés |

Les fonctionnalités **PDF direct** et **hors ligne avancé** sont exclues conformément au choix de l'utilisateur.

**Ne pas considérer cette version comme terminée ni remplacer la production avant la recette.**
