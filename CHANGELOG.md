# MAHAVEL Studio — historique

## 0.4.0 candidate — 24 novembre 2026
- Proposition d'appels privés WebRTC audio/vidéo avec signalisation Supabase ; STUN uniquement, TURN non fourni et tests multi-appareils requis.
- Messages non lus par conversation avec accusé d'ouverture, alertes internes consultables.
- Import JSON avec filtrage des doublons et clés de déduplication en base (migration 004 requise).
- Workflow de validation par manager : validation ou corrections commentées, enregistrement atomique en base.
- Notifications automatiques après affectation ou changement de statut de tâche.
- Edge Function de nettoyage des documents expirés au bout de 6 jours, à déployer et planifier séparément ; n'efface pas les orphelins.
- Renforcement des accès SQL pour les nouvelles tables et restrictions des RPC SECURITY DEFINER existantes.
- Direction visuelle plus éditoriale, responsive, interactions clavier et tactiles.
- Pas encore testée de bout en bout en conditions de production : voir INSTALLATION_V040.md.

## 0.3.1
- Recherche de conversations, messages sauvegardés, renommage de calendriers, corrections du chargement et des fuseaux.
