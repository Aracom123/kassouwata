#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Script de déploiement Kassouwata — Backend Spring Boot via Docker
#  VPS : Ubuntu 20.04 | Domaine : kassouwata.beit.ne | Port : 8082
#
#  Usage :
#    1. Copiez ce script sur votre VPS :
#       scp deploy-vps.sh user@kassouwata.beit.ne:~/
#    2. Rendez-le exécutable et lancez-le :
#       chmod +x deploy-vps.sh && ./deploy-vps.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success(){ echo -e "${GREEN}[OK]${NC}   $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }

APP_DIR="/opt/kassouwata"
REPO_URL="https://github.com/VOTRE_ORG/kassouwata-back.git"   # À modifier
DOMAIN="kassouwata.beit.ne"
API_PORT=8082

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Déploiement Kassouwata Backend — VPS       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Installer Docker si absent ─────────────────────────────────────────────
log "Vérification de Docker..."
if ! command -v docker &>/dev/null; then
    log "Installation de Docker..."
    apt-get update -qq
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    success "Docker installé"
else
    success "Docker déjà présent ($(docker --version))"
fi

# ── 2. Installer git si absent ────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
    log "Installation de git..."
    apt-get install -y git
fi

# ── 3. Préparer le répertoire de l'application ───────────────────────────────
log "Préparation du répertoire $APP_DIR..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# ── 4. Récupérer / mettre à jour les sources ─────────────────────────────────
if [ -d "$APP_DIR/.git" ]; then
    log "Mise à jour du code source..."
    git pull origin main
    success "Code mis à jour"
else
    log "Clonage du dépôt..."
    warn "Si vous n'utilisez pas Git, copiez manuellement le dossier kassouwata-back ici : $APP_DIR"
    warn "Puis relancez ce script."
    # Décommentez la ligne suivante si vous utilisez Git :
    # git clone "$REPO_URL" .
fi

# ── 5. Créer le fichier .env s'il n'existe pas ───────────────────────────────
if [ ! -f "$APP_DIR/.env" ]; then
    log "Création du fichier .env..."
    cat > "$APP_DIR/.env" <<EOF
DB_USERNAME=kassouwa_user
DB_PASSWORD=CHANGE_ME
EOF
    warn "Vérifiez les credentials dans $APP_DIR/.env avant de continuer !"
    warn "Modifiez si nécessaire : nano $APP_DIR/.env"
    read -p "Appuyez sur Entrée pour continuer après vérification..."
fi

# ── 6. Autoriser le port 8082 dans le firewall ───────────────────────────────
log "Configuration du firewall (UFW)..."
if command -v ufw &>/dev/null; then
    ufw allow "$API_PORT/tcp" || warn "UFW non actif ou règle déjà présente"
    success "Port $API_PORT autorisé"
fi

# ── 7. Vérifier que PostgreSQL accepte les connexions depuis Docker ───────────
log "Vérification de la configuration PostgreSQL..."
PG_HBA="/etc/postgresql/*/main/pg_hba.conf"
POSTGRESQL_CONF=$(ls /etc/postgresql/*/main/postgresql.conf 2>/dev/null | head -1)

if [ -n "$POSTGRESQL_CONF" ]; then
    # S'assurer que PostgreSQL écoute sur toutes les interfaces locales
    if ! grep -q "listen_addresses = '\*'" "$POSTGRESQL_CONF" 2>/dev/null && \
       ! grep -q "listen_addresses = 'localhost'" "$POSTGRESQL_CONF" 2>/dev/null; then
        warn "Vérifiez que listen_addresses dans postgresql.conf inclut 'localhost' ou '*'"
    fi

    # Ajouter la règle Docker (172.17.0.0/16) dans pg_hba.conf si absente
    PG_HBA_FILE=$(ls /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1)
    if [ -n "$PG_HBA_FILE" ]; then
        if ! grep -q "172.17.0.0/16" "$PG_HBA_FILE" 2>/dev/null; then
            log "Ajout de la règle Docker dans pg_hba.conf..."
            echo "host    kassouwata_db    kassouwa_user    172.17.0.0/16    md5" \
                >> "$PG_HBA_FILE"
            systemctl reload postgresql || service postgresql reload
            success "pg_hba.conf mis à jour"
        else
            success "Règle Docker déjà présente dans pg_hba.conf"
        fi
    fi
fi

# ── 8. Build et démarrage via Docker Compose ─────────────────────────────────
log "Build de l'image Docker (peut prendre 3-5 minutes la première fois)..."
docker compose build --no-cache

log "Démarrage du container..."
docker compose down 2>/dev/null || true
docker compose up -d

# ── 9. Vérification du démarrage ─────────────────────────────────────────────
log "Attente du démarrage de l'API (60 secondes max)..."
for i in $(seq 1 12); do
    sleep 5
    if curl -sf "http://localhost:$API_PORT/api/nosCategories/list" > /dev/null 2>&1; then
        success "API démarrée et opérationnelle !"
        break
    fi
    echo -n "."
    if [ "$i" -eq 12 ]; then
        warn "L'API n'a pas répondu dans les temps. Vérifiez les logs :"
        echo "  docker compose logs -f kassouwata-api"
    fi
done

# ── 10. Résumé final ──────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    DÉPLOIEMENT TERMINÉ                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  API disponible sur : http://%-31s║\n" "$DOMAIN:$API_PORT"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Commandes utiles :                                          ║"
echo "║    Logs en direct    : docker compose logs -f                ║"
echo "║    Redémarrer        : docker compose restart                ║"
echo "║    Arrêter           : docker compose down                   ║"
echo "║    Rebuild + restart : docker compose up -d --build          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
