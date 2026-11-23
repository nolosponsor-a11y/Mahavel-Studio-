# Recette V0.2.0 — à réaliser sur Supabase et appareils réels

- [ ] Migration 002 appliquée une seule fois, sans erreur
- [ ] Les données de V0.1.0 sont toujours présentes
- [ ] Connexion, déconnexion, reconnexion
- [ ] Profil : modifier nom, couleur, fonction, photo, lien et recharger
- [ ] Tâche : affecter à un collaborateur, vérifier sa couleur et sa réception
- [ ] Tâche, projet, événement : supprimer comme auteur ; refus depuis un compte non autorisé
- [ ] Planning : couleur du responsable et navigation mensuelle
- [ ] Conversation Direct : visibilité pour les deux seuls participants (tester avec 3 comptes)
- [ ] Conversation Groupe : visible uniquement aux membres invités
- [ ] Message : ajout, suppression par l'auteur et actualisation temps réel entre deux appareils
- [ ] Fichier ciblé : destinataire autorisé et troisième compte refusé sur les données **et** Storage
- [ ] Fichier à conserver : non supprimé par nettoyage automatique
- [ ] Fichier temporaire : suppression réelle à 6 jours par Cron/Edge Function
- [ ] Message : expiration réelle à 7 jours par Cron
- [ ] Horaires : ajout et modification manuelle, droits manager
- [ ] Notification de tâche et nouveau message
- [ ] PWA : actualisation sans effacement Supabase, essai sur iPhone/Android
- [ ] Écran mobile : pas de débordement, boutons accessibles, navigation basse

**Tests automatisés réalisés lors de la création du ZIP :** contrôle de syntaxe JavaScript (`node --check`), inspection de fichiers, contrôle de présence des ressources. Aucun test de base Supabase, du stockage réel, de la sécurité RLS en situation ou d'appareils physiques n'a pu être effectué.
