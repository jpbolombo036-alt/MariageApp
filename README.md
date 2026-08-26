# MariagePlus (Flutter)

Client mobile **MariagePlus** pour le backend Spring Boot `com.mariageplus`.

## Prérequis

- Flutter SDK (Dart ^3.12)
- Backend MariagePlus joignable (port **8000** en local)

## Lancer

```bash
flutter pub get
flutter run
```

- Émulateur Android : API `http://10.0.2.2:8000`
- Simulateur iOS / desktop : `http://localhost:8000`

Release :

```bash
flutter build apk --dart-define=API_BASE_URL=https://votre-api
```

## Documentation

- **[Reste à faire](docs/RESTE_A_FAIRE.md)** — backlog produit et technique

## Structure

```
lib/
  main.dart
  src/
    api/          # Dio, config URL
    auth/         # login, session, permissions UI
    wedding/      # événements
    weddingevent/  # événements de mariage (cérémonies, réception, ...)
    guest/        # invités + catégories
    invitation/   # invitations + QR
    table/        # plan de table
    checkin/      # RSVP public + scan entrée
    dashboard/
    admin/
    home/
```
