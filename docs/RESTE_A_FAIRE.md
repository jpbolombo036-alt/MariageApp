# MariagePlus — reste à faire

Client Flutter (`mariageplus_app`) du backend Spring Boot `com.mariageplus`.  
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

| # | Tâche | Pourquoi |
|---|--------|----------|
| 1 | Brancher un backend réel + `API_BASE_URL` en debug si besoin | Sans API sur `:8000`, listes / login échouent |
| 2 | Permissions depuis `/auth/me` (codes API) au lieu de `permissionsForRoles` | La matrice locale peut diverger du RBAC backend |
| 3 | Deep link RSVP (`mariageplus://…` ou HTTPS universel) | Aujourd’hui l’invité doit coller le jeton à la main |
| 4 | Rafraîchir les listes après création (invité, invitation) | `pop` sans résultat → liste parent stale |
| 5 | Pagination UI (`page` / `size` > 25) | Les listes API s’arrêtent à la 1ʳᵉ page |

## Priorité moyenne — produit

| # | Tâche | Fichiers / zone |
|---|--------|-----------------|
| 6 | CRUD événements : update, delete, publish, archive | `wedding_*` — API absente côté client |
| 7 | CRUD invités : update, delete | `guest_*` |
| 8 | Envoi / renvoi d’invitation | `invitation_*` |
| 9 | Afficher `Dashboard.categories` | `dashboard_page.dart` (DTO déjà parsé) |
| 10 | Tables : déplacer / retirer une affectation | `TableApi.move` / `remove` existent, pas d’UI |
| 11 | Admin : créer / modifier users, rôles, orgs | `admin_*` lecture seule |
| 12 | Check-in : effectif > 1 par scan | Aujourd’hui toujours `numberOfAttendees: 1` |

## Priorité basse — technique & qualité

| # | Tâche | Note |
|---|--------|------|
| 13 | Remplacer `_loading` / `_error` manuels par `AsyncNotifier` Riverpod | Moins de duplication |
| 14 | `go_router` + deep links | Remplace `Navigator.push` impératif |
| 15 | File d’attente refresh 401 (au lieu d’un bool `_refreshing`) | Évite de perdre des requêtes concurrentes |
| 16 | Tests : API client, auth, widgets métier | 1 seul test widget aujourd’hui |
| 17 | Design system / thème (hors Material seed violet) | Revue visuelle produit |
| 18 | Icônes / nom d’app store (`mariageplus_app` → MariagePlus) | Manifests Android / iOS |

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
