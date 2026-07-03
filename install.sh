#!/usr/bin/env bash
# =============================================================================
#  Bulawayo Polytechnic — DSpace 8 Full Installer
#  Works on any Ubuntu/Debian PC on the campus network.
#
#  Usage (one command):
#    curl -fsSL https://raw.githubusercontent.com/wgmasvix-hue/bulawayo-polytechnic-dspace-/claude/dspace-deployment-review-48qeth/install.sh | bash
#
#  Or after cloning:
#    chmod +x install.sh && ./install.sh
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/wgmasvix-hue/bulawayo-polytechnic-dspace-.git"
BRANCH="claude/dspace-deployment-review-48qeth"
INSTALL_DIR="$HOME/bpoly-dspace"
DB_PASSWORD="BpolyRepo2025!"

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
success() { echo -e "${GREEN}[DONE]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "   Bulawayo Polytechnic — DSpace 8 Institutional Repository"
echo "   Automated Installer"
echo "============================================================"
echo ""

# ── 1. Detect LAN IP ─────────────────────────────────────────────────────────
info "Detecting LAN IP address..."
SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null \
  | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
[[ -z "$SERVER_IP" ]] && SERVER_IP=$(hostname -I | awk '{print $1}')
[[ -z "$SERVER_IP" ]] && error "Cannot detect LAN IP. Connect to the campus network and retry."
success "Server IP: $SERVER_IP"

# ── 2. Install Docker ─────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  success "Docker installed."
else
  success "Docker already installed: $(docker --version)"
fi

# Install Docker Compose plugin if missing
if ! docker compose version &>/dev/null; then
  info "Installing Docker Compose plugin..."
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  success "Docker Compose installed."
else
  success "Docker Compose: $(docker compose version)"
fi

# ── 3. Clone / update repo ────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Updating existing installation at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" fetch origin "$BRANCH"
  git -C "$INSTALL_DIR" checkout "$BRANCH"
  git -C "$INSTALL_DIR" pull origin "$BRANCH"
else
  info "Cloning repository to $INSTALL_DIR..."
  git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"
success "Repository ready."

# ── 4. Write .env ─────────────────────────────────────────────────────────────
info "Configuring for IP: $SERVER_IP ..."
cat > .env << EOF
SERVER_IP=${SERVER_IP}
POSTGRES_PASSWORD=${DB_PASSWORD}
EOF

# Update Angular config.yml REST host
sed -i "s/^  host: .*/  host: ${SERVER_IP}/" config.yml

success "Configuration written."

# ── 5. Build BPoly Angular image ──────────────────────────────────────────────
if ! docker image inspect bpoly-dspace-angular:latest &>/dev/null; then
  info "Building Bulawayo Polytechnic branded Angular image (~2 minutes)..."
  docker build -f Dockerfile.angular -t bpoly-dspace-angular:latest .
  success "Angular image built."
else
  success "Angular image already built."
fi

# ── 6. Start all containers ───────────────────────────────────────────────────
info "Starting DSpace services..."
docker compose -f docker-compose-campus.yml down --remove-orphans 2>/dev/null || true
docker compose -f docker-compose-campus.yml up -d
success "Containers started."

# ── 7. Wait for DSpace backend ────────────────────────────────────────────────
info "Waiting for DSpace backend to start (this takes 3-5 minutes)..."
WAIT=0
until curl -sf http://localhost:8080/server/api &>/dev/null; do
  sleep 10
  WAIT=$((WAIT + 10))
  if [[ $WAIT -ge 360 ]]; then
    error "DSpace did not start after 6 minutes. Run: docker logs dspace"
  fi
  echo -n "."
done
echo ""
success "DSpace backend is running!"

# ── 8. Create admin account ───────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  Create Administrator Account"
echo "============================================================"
echo "  This account will be used to manage the repository."
echo ""

read -rp "  Admin email address : " ADMIN_EMAIL
read -rsp "  Admin password      : " ADMIN_PASS
echo ""
read -rsp "  Confirm password    : " ADMIN_PASS2
echo ""

if [[ "$ADMIN_PASS" != "$ADMIN_PASS2" ]]; then
  error "Passwords do not match. Re-run the installer."
fi

# Check if admin already exists and update password, else create new
if docker exec dspace /dspace/bin/dspace user --list 2>/dev/null | grep -q "$ADMIN_EMAIL"; then
  docker exec dspace /dspace/bin/dspace user --modify \
    --email "$ADMIN_EMAIL" --newPassword "$ADMIN_PASS"
  success "Admin password updated for $ADMIN_EMAIL"
else
  docker exec -i dspace /dspace/bin/dspace create-administrator << EOF
$ADMIN_EMAIL
Admin
User
y
$ADMIN_PASS
$ADMIN_PASS
EOF
  success "Admin account created: $ADMIN_EMAIL"
fi

# ── 9. Set up faculty communities ─────────────────────────────────────────────
echo ""
info "Setting up Bulawayo Polytechnic faculty communities..."
DSPACE_URL="http://localhost:8080/server" \
  ADMIN_EMAIL="$ADMIN_EMAIL" \
  ADMIN_PASS="$ADMIN_PASS" \
  bash setup-communities.sh || warn "Communities script had errors — check manually."

# ── 10. Final summary ─────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "  ${GREEN}Bulawayo Polytechnic DSpace is READY!${NC}"
echo "============================================================"
echo ""
echo "  UI (browser):  http://${SERVER_IP}:4000"
echo "  REST API:      http://${SERVER_IP}:8080/server"
echo "  Admin login:   $ADMIN_EMAIL"
echo ""
echo "  Share the UI URL with anyone on the campus network."
echo ""
echo "  To restart later:  docker compose -f $INSTALL_DIR/docker-compose-campus.yml up -d"
echo "  To stop:           docker compose -f $INSTALL_DIR/docker-compose-campus.yml down"
echo "============================================================"
