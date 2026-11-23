# Recette MAHAVEL — à effectuer avant production

Ce fichier est une **checklist**, pas un rapport de tests déjà réussis.

- [ ] Exécution intégrale de 001_initial.sql sur Supabase neuf, sans erreur
- [ ] Compte administrateur ajouté manuellement à l'espace
- [ ] Deux comptes distincts : connexion, déconnexion, persistance de session
- [ ] Compte sans membership : refus d'accès
- [ ] Compte appartenant à un autre workspace : aucune donnée lisible ou modifiable (test SQL/API)
- [ ] Création/modification de tâche et propagation en temps réel sur deux appareils
- [ ] Réaffectation d'une tâche visible par son responsable
- [ ] Événement : ajout, modification, navigation décembre → janvier, fuseau Réunion
- [ ] Messages : transmission en direct, horodatage serveur, invisibilité après 7 jours
- [ ] Fichier privé : upload, téléchargement signé, refus sans membership
- [ ] Fichier normal : disparaît de l'interface après 6 jours, supprimé du stockage après exécution du job
- [ ] Fichier « À conserver » : survit au nettoyage, accessible via Documents
- [ ] Message supprimé : fichier conservé reste accessible via Documents
- [ ] Nettoyage avec objet de stockage absent : erreur journalisée, pas de faux succès
- [ ] Cas hors ligne, retour en ligne, erreurs d'enregistrement
- [ ] Installation Safari iPhone et Android Chrome
- [ ] Modification de la version cache, bouton Rechercher les mises à jour et activation
- [ ] Vérifier affichage mobile, desktop, petits écrans et zones sécurisées iOS
- [ ] Tentative d'accès sans autorisation par appel direct à Supabase, pas seulement via l'UI

Non implémenté / donc non testable en l'état : messages individuels privés, validations workflow, notifications automatiques, conflits de calendrier, permissions fines par projet, pagination et recherches complètes, mises à jour de ligne concurrentes, audit journalisé, sauvegardes/restaurations.
