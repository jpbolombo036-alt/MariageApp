# EventiaEasy — reste à faire

Client Flutter EventiaEasy (`mariageplus_app`) du backend Spring Boot.  
Document à jour au 20 août 2026. Le **mode démo a été retiré** : l’app parle uniquement à l’API.

## Déjà en place (ne pas refaire)

- Auth JWT : login / inscription / logout, tokens Keychain/Keystore
- Refresh 401 + `onSessionExpired` → retour login
- `API_BASE_URL` obligatoire en **release** (`--dart-define=…`)
- Android : `INTERNET`, `CAMERA`, cleartext limité à localhost / `10.0.2.2`
- RSVP public accessible depuis l’écran de connexion
- Scan QR caméra (`mobile_scanner`) + collage de jeton
- Détail événement : actions filtrées par permissions UI
- Modules : événements, dashboard, invités, catégories, invitations/QR, tables, check-in, admin (listes)

## Priorité haute

| # | Tâche | État |
|---|--------|------|
| 1 | Brancher un backend réel + `API_BASE_URL` en debug si besoin | Toujours requis pour exécuter l’app (défaut localhost / `10.0.2.2:8000`) |
| 2 | Permissions depuis `/auth/me` | Fait : codes API si présents, sinon matrice de rôles. Alias `EVENT_*` / `WEDDING_*` |
| 3 | Deep link RSVP `mariageplus://rsvp?token=` | Fait (schéma applicatif). Lien HTTPS universel encore à configurer côté domaine |
| 4 | Rafraîchir les listes après création | Fait pour événements, invités et invitations |
| 5 | Pagination | Fait : les listes enchaînent les pages Spring jusqu’à `last` |

## Priorité moyenne — produit

| # | Tâche | Fichiers / zone |
|---|--------|-----------------|
| 6 | CRUD événements : update, delete, publish, archive | Fait dans l’espace organisateur (`updateStatus`, `delete`) |
| 7 | CRUD invités : update, delete | Fait sur la liste invités |
| 8 | Envoi / renvoi d’invitation | Déjà présent sur le détail d’invitation |
| 9 | Afficher `Dashboard.categories` | Fait |
| 10 | Tables : déplacer / retirer une affectation | Fait sur l’écran d’affectation |
| 11 | Admin : créer / modifier users, rôles, orgs | Lecture + ajout de membre. Édition des rôles et organisations encore absente de l’API client |
| 12 | Check-in : effectif > 1 par scan | Fait (agent et écran jeton) |

## Priorité basse — technique & qualité

| # | Tâche | Note |
|---|--------|------|
| 13 | Remplacer `_loading` / `_error` manuels par `AsyncNotifier` Riverpod | Moins de duplication |
| 14 | `go_router` + deep links | Remplace `Navigator.push` impératif |
| 15 | File d’attente refresh 401 | Fait : un seul refresh partagé, les requêtes concurrentes attendent |
| 16 | Tests : API client, auth, widgets métier | 1 seul test widget aujourd’hui |
| 17 | Design system / thème | Thème clair et sombre branché (mode système + choix dans Profil) |
| 18 | Nom d’app (`EventiaEasy`) | Libellé Android / iOS mis à jour |

## Build & run

```bash
# Debug (API locale)
# Android émulateur → http://10.0.2.2:8000
# iOS / desktop → http://localhost:8000
flutter run

# Release (HTTPS obligatoire)
flutter build apk --dart-define=API_BASE_URL=https://api.exemple.com
flutter build ios --dart-define=API_BASE_URL=https://api.exemple.com
```

Backend attendu : Spring Boot sur le port **8000** (auth `/auth/*`, métier `/api/...`).

## Parcours de vérification manuelle (avec backend)

1. Inscription ou login → accueil
2. Créer un événement → liste → détail
3. Invités + catégories → invitation + QR
4. Tables + affectation
5. Check-in (caméra ou jeton)
6. RSVP depuis « Répondre à une invitation » (login)
7. SUPER_ADMIN → Administration
8. Attendre expiration token / forcer 401 → retour login
