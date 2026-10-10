# Kassouwata

Plateforme e-commerce couplée à la gestion de tontines, développée par BEIT NIGER.

Les clients achètent des produits (paiement en une fois ou par tranches), les vendeurs publient leurs produits et traitent les commandes, et chacun peut créer ou rejoindre des tontines. Les paiements en ligne passent par l'agrégateur **KomiPay** (Mobile Money, sociétés de transfert d'argent, cartes VISA / Mastercard).

## Structure du dépôt

| Dossier | Rôle | Technologie |
|---|---|---|
| [`kassouwata-back/`](kassouwata-back) | API REST, paiements, tâches planifiées | Spring Boot 4 · Java 17 · PostgreSQL |
| [`Kassouwata-front/`](Kassouwata-front) | Back office d'administration (profil ADMIN) | Angular 21 · Tailwind CSS |
| [`kassouwata_client/`](kassouwata_client) | Application mobile client (profil CLIENT) | Flutter |
| [`vendor_app/`](vendor_app) | Application mobile vendeur (profil VENDEUR) | Flutter |
| `deploy-vps.sh` | Script de déploiement du backend (Docker) sur le VPS | Bash |
| `GUIDE_BUILD_APK.md` | Signature et génération des APK Android | — |

Profils : **ADMIN**, **VENDEUR**, **CLIENT**. Toute utilisation nécessite un compte et une authentification (JWT).

## Démarrage en local

### 1. Backend

Prérequis : JDK 17, PostgreSQL (base `kassouwata_db`, utilisateur `kassouwa_user`).

```bash
cd kassouwata-back
cp .env.example .env        # puis renseigner les valeurs (voir ci-dessous)
./mvnw spring-boot:run      # Windows : mvnw.cmd spring-boot:run
```

L'API écoute sur `http://localhost:8082`. Le schéma est créé automatiquement (`ddl-auto=update`).

Variables du fichier `.env` :

| Variable | Description |
|---|---|
| `DB_PASSWORD` | Mot de passe PostgreSQL |
| `PAYMENT_BASE_URL` | Base KomiPay pour le jeton (`/generateToken`) |
| `PAYMENT_TRANSACTION_BASE_URL` | Facultatif — base des transactions (par défaut `PAYMENT_BASE_URL/customers-api-kp/v1`) |
| `PAYMENT_LOGIN`, `PAYMENT_PASSWORD`, `PAYMENT_API_KEY` | Identifiants KomiPay |
| `PAYMENT_KEYPASS` | En-tête `keypass` des paiements par carte |

### 2. Back office

Prérequis : Node.js 20+.

```bash
cd Kassouwata-front
npm install
npm start                   # http://localhost:4200, /api redirigé vers le backend (proxy.conf.json)
```

### 3. Applications mobiles

Prérequis : Flutter (Dart ≥ 3.3), Android SDK.

```bash
cd kassouwata_client        # ou vendor_app
flutter pub get
flutter run
```

L'URL de l'API est lue dans `.env.development` / `.env.production` (`BASE_URL`). En développement, mettre l'adresse IP locale du PC qui fait tourner le backend.

> Ne pas lancer `build_runner` dans `kassouwata_client` : `lib/core/di/injection.config.dart` est maintenu à la main.

Pour les APK signés, voir [`GUIDE_BUILD_APK.md`](GUIDE_BUILD_APK.md) (fichier `android/key.properties` et keystore, jamais versionnés).

## Paiements (KomiPay)

- Catégories : **Mobile Money** (Airtel Money…), **STA** — sociétés de transfert (MyNita, Amana), **Carte** (VISA, Mastercard avec 3-D Secure).
- Le référentiel des moyens de paiement (libellés, logos, activation) se gère dans le back office, menu *Moyens de paiement*.
- Les transactions sont enregistrées dans la table `transaction` puis vérifiées automatiquement (tâche planifiée toutes les minutes) jusqu'au statut final `REUSSIE` / `ECHOUEE`.
- Les données de carte (numéro complet, CVV) ne sont jamais stockées ni journalisées.

## Déploiement

- Backend : `deploy-vps.sh` (Docker Compose) ou service systemd (`kassouwata-back/kassouwata.service.txt`). Sur le serveur, créer le fichier `.env` à partir de `kassouwata-back/.env.docker.example` et de `kassouwata-back/.env.example`.
- Production : `https://kassouwata.beit.ne`.

## Sécurité

Ne jamais versionner : fichiers `.env`, `key.properties`, keystores (`*.jks`), sauvegardes de base (`*.sql`), images envoyées par les utilisateurs (`kassouwata-back/images/`). Ces chemins sont exclus par les `.gitignore`.
