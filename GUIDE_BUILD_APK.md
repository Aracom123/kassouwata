# Guide de build APK — Kassouwata (Android Release)

Ce guide couvre la génération des APKs de release pour les deux applications mobiles :
- **vendor_app** — Application Vendeur (`com.example.vendor_app`)
- **kassouwata_client** — Application Client (`com.techinnov.kassouwata_client`)

---

## Prérequis

- Flutter SDK installé et dans le PATH (`flutter --version` pour vérifier)
- Java JDK 17 installé (`java -version` pour vérifier)
- Android SDK installé (via Android Studio ou sdkmanager)
- Les dépendances Flutter installées (`flutter pub get` dans chaque projet)

---

## Étape 1 — Changer les Application IDs (recommandé)

Les Application IDs actuels utilisent le préfixe `com.example.*` par défaut. Pour publier sur le Play Store, il faut des identifiants uniques.

Ouvrez chaque fichier `android/app/build.gradle.kts` et remplacez :

**vendor_app/android/app/build.gradle.kts**
```
namespace = "com.kassouwata.vendor"
applicationId = "com.kassouwata.vendor"
```

**kassouwata_client/android/app/build.gradle.kts**
```
namespace = "com.techinnov.kassouwata_client"
applicationId = "com.techinnov.kassouwata_client"
```

> Le client garde déjà un bon identifiant. Seul le vendeur est à corriger si vous souhaitez publier.

---

## Étape 2 — Créer un Keystore de signature

Un keystore est un fichier contenant votre clé privée. Il est nécessaire une seule fois ; **conservez-le précieusement avec son mot de passe** — sans lui vous ne pourrez plus mettre à jour vos apps sur le Play Store.

Ouvrez un terminal et exécutez :

```bash
keytool -genkey -v \
  -keystore ~/kassouwata-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias kassouwata
```

Répondez aux questions (nom, organisation, pays…). Notez bien :
- **Chemin du keystore** : `~/kassouwata-release.jks`
- **Mot de passe du keystore** (storePassword)
- **Alias** : `kassouwata`
- **Mot de passe de la clé** (keyPassword) — peut être identique au storePassword

---

## Étape 3 — Créer le fichier key.properties

Dans le dossier `android/` de **chaque application**, créez un fichier `key.properties` (ne jamais committer ce fichier dans Git) :

```
storePassword=VOTRE_STORE_PASSWORD
keyPassword=VOTRE_KEY_PASSWORD
keyAlias=kassouwata
storeFile=C:/Users/hp/kassouwata-release.jks
```

> Sur Windows, utilisez des slashes `/` ou `\\` dans le chemin. Sur Mac/Linux, utilisez le chemin absolu (ex. `/home/user/kassouwata-release.jks`).

---

## Étape 4 — Configurer build.gradle.kts pour la signature

Ouvrez `android/app/build.gradle.kts` dans **chaque application** et remplacez le contenu par :

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    // vendor_app : "com.kassouwata.vendor"
    // kassouwata_client : "com.techinnov.kassouwata_client"
    namespace = "VOTRE_NAMESPACE"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "VOTRE_APPLICATION_ID"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
```

Remplacez `VOTRE_NAMESPACE` et `VOTRE_APPLICATION_ID` par les valeurs correspondantes à chaque app.

---

## Étape 5 — Ajouter key.properties au .gitignore

Dans `android/.gitignore` de chaque app, ajoutez :

```
key.properties
*.jks
*.keystore
```

---

## Étape 6 — Générer les APKs de release

### Application Vendeur

```bash
cd C:\Users\hp\Desktop\DevProjects\Kassouwata\vendor_app

# Nettoyer le build précédent
flutter clean

# Récupérer les dépendances
flutter pub get

# Générer l'APK release
flutter build apk --release
```

L'APK sera généré ici :
```
vendor_app/build/app/outputs/flutter-apk/app-release.apk
```

### Application Client

```bash
cd C:\Users\hp\Desktop\DevProjects\Kassouwata\kassouwata_client

flutter clean
flutter pub get
flutter build apk --release
```

L'APK sera généré ici :
```
kassouwata_client/build/app/outputs/flutter-apk/app-release.apk
```

---

## Étape 7 — Vérifier la signature de l'APK (optionnel)

Pour confirmer que l'APK est bien signé avec votre clé de release :

```bash
# vendor_app
keytool -printcert -jarfile vendor_app/build/app/outputs/flutter-apk/app-release.apk

# kassouwata_client
keytool -printcert -jarfile kassouwata_client/build/app/outputs/flutter-apk/app-release.apk
```

---

## Récapitulatif des APKs générés

| Application    | APK                                                               | URL backend                        |
|----------------|-------------------------------------------------------------------|------------------------------------|
| Vendeur        | `vendor_app/build/app/outputs/flutter-apk/app-release.apk`       | http://kassouwata.beit.ne:8082     |
| Client         | `kassouwata_client/build/app/outputs/flutter-apk/app-release.apk`| http://kassouwata.beit.ne:8082     |

Le chargement du bon fichier `.env.production` est automatique en mode release grâce à la condition `kReleaseMode` ajoutée dans les deux `main.dart`.

---

## Dépannage courant

**`Keystore file not found`**  
Vérifiez que le chemin dans `key.properties` est correct et absolu.

**`flutter build apk` échoue avec une erreur Gradle**  
Essayez de supprimer les caches : `flutter clean` puis relancez.

**L'APK s'installe mais ne se connecte pas au backend**  
Vérifiez que le VPS est démarré (`docker compose ps` sur le serveur) et que le port 8082 est ouvert dans le firewall.

**`INSTALL_FAILED_UPDATE_INCOMPATIBLE` sur le téléphone**  
Désinstallez d'abord la version debug avant d'installer la release (elles ont des signatures différentes).
