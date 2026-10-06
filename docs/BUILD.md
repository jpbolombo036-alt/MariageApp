# Build & run — EventiaEasy

Guide pratique pour `flutter run` et la génération d'APK **sans se battre avec
Gradle**. Machine de référence : Windows, 8 Go de RAM, Flutter 3.44 / Gradle 9.1.

---

## 1. En une commande

```powershell
# APK release (API de production) -> build\app\outputs\flutter-apk\
.\tools\flutter_build.ps1 -Task apk

# APK release plus léger (un APK par architecture)
.\tools\flutter_build.ps1 -Task apk -SplitPerAbi

# App Bundle pour le Play Store
.\tools\flutter_build.ps1 -Task aab

# Lancer en debug sur un appareil (API locale)
.\tools\flutter_build.ps1 -Task run
```

> Le script lance le build dans un **processus séparé** et écrit toute la sortie
> dans `build_logs\<tache>-<horodatage>.log`.
> C'est volontaire : voir section 3.

---

## 2. Quelle API pour quel mode ?

`lib/src/api/api_config.dart` résout l'URL dans cet ordre :

| Priorité | Source | Valeur |
|---|---|---|
| 1 | `--dart-define=API_BASE_URL=…` | valeur fournie |
| 2 | `--dart-define=API_ENV=prod` | production (Railway) |
| 2 | `--dart-define=API_ENV=local` | backend local |
| 3 | build **release** | production (Railway) |
| 4 | build **debug** (`flutter run`) | `http://10.0.2.2:8000` (Android) / `http://localhost:8000` |

Conséquence : **`flutter run` tape sur votre backend local et
`flutter build apk` sur la production, sans modifier une ligne de code.**

```powershell
# Backend local
flutter run
.\tools\flutter_build.ps1 -Task run -DartDefine API_ENV=local

# Production
.\tools\flutter_build.ps1 -Task apk -DartDefine API_ENV=prod

# Serveur de test sur le réseau local
.\tools\flutter_build.ps1 -Task apk -DartDefine API_BASE_URL=http://192.168.1.10:8000
```

> ⚠️ **Émulateur vs téléphone réel**
> `http://10.0.2.2:8000` est l'alias du `localhost` de votre PC : il ne fonctionne
> **que sur l'émulateur Android**. Sur un **téléphone réel**, précisez l'IP de
> votre PC sur le réseau local (et pensez à ouvrir le port 8000 dans le
> pare-feu Windows) :
>
> ```powershell
> flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
> ```

Backend attendu : Spring Boot sur le port **8000** (`/auth/*`, `/api/...`).

---

## 3. Pourquoi les builds cassaient (et comment l'éviter)

Symptôme observé :

```
Execution failed for task ':app:mergeReleaseNativeLibs'.
> Multiple build operations failed.
  Unexpected lock protocol found in lock file. Expected 3, found 0.
```

**Cause** : `flutter` est un `.bat`. Un `Ctrl+C` (ou une fermeture de fenêtre)
pendant le build laisse des fichiers de verrou Gradle à l'état invalide, ainsi
que des entrées corrompues dans le cache de transformations
(`~/.gradle/caches/<version>/transforms`).

**Prévention**

1. Ne pas interrompre un build en cours (utiliser le script §1 : il est isolé).
2. Si un build doit être arrêté : enchaîner avec `-Task repair`.

**Réparation** (sans re-télécharger les dépendances)

```powershell
.\tools\flutter_build.ps1 -Task repair
```

Ce que fait `repair` :

1. arrête les daemons Gradle/Kotlin (les autres applis Java ne sont pas touchées) ;
2. supprime les `*.lock` de 0 octet sous `~/.gradle` ;
3. purge `~/.gradle/caches/<version>`, `journal-1`, `jars-9` et `android\.gradle`
   (suppression compatible chemins > 260 caractères) ;
4. conserve `~/.gradle/caches/modules-2` → **pas de re-téléchargement**.

Si l'erreur persiste :

```powershell
.\tools\flutter_build.ps1 -Task clean   # flutter clean + pub get
```

---

## 4. Signature de l'APK

Par défaut, la release est signée avec la **clé debug** : l'APK s'installe
partout mais n'est **pas publiable** sur le Play Store.

Pour activer la vraie signature, sans toucher au code :

```powershell
copy android\key.properties.example android\key.properties
# renseigner storePassword / keyPassword / keyAlias / storeFile
```

`android/app/build.gradle.kts` détecte le fichier et bascule automatiquement sur
la clé de release. `android/.gitignore` exclut déjà `key.properties`.

---

## 5. VS Code

- `Ctrl+Shift+P → Tasks: Run Task` :
  `APK release (robuste, script)`, `App Bundle AAB`, `REPARER cache Gradle`,
  `Flutter: run (backend local)`, `Flutter: analyze`…
- `F5` : profils `Local (défaut dev)`, `Production`, `API personnalisée`,
  `Profil (perf)`, `Release (device réel)` (`.vscode/launch.json`).

---

## 6. Optimisations en place

`android/gradle.properties` :

| Clé | Effet |
|---|---|
| `org.gradle.jvmargs=-Xmx2G` | évite le swap (7,9 Go de RAM) |
| `org.gradle.daemon=true` | pas de redémarrage JVM à chaque build |
| `org.gradle.caching=true` | cache de tâches → builds suivants plus rapides |
| `org.gradle.parallel=false` | la RAM est le goulot d'étranglement |
| `org.gradle.configureondemand=false` | configurations partielles évitées |

Pour aller encore plus vite : `-SplitPerAbi` (un APK par architecture) et
`flutter build apk --target-platform android-arm64` si un seul type
d'appareil est ciblé.
