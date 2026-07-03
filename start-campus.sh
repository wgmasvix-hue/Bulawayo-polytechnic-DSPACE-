#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Bulawayo Polytechnic DSpace — Campus Quick-Start
#
# Usage:
#   chmod +x start-campus.sh
#   ./start-campus.sh
#
# On any PC on the campus network this script will:
#   1. Auto-detect the machine's LAN IP address
#   2. Write a .env file with that IP and a DB password
#   3. Build the BPoly-branded Angular image (first run only)
#   4. Start all DSpace services
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Detect LAN IP ────────────────────────────────────────────────────────────
SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)

if [[ -z "$SERVER_IP" ]]; then
  SERVER_IP=$(hostname -I | awk '{print $1}')
fi

if [[ -z "$SERVER_IP" ]]; then
  echo "ERROR: Could not detect LAN IP. Set it manually:"
  echo "  SERVER_IP=192.168.x.x ./start-campus.sh"
  exit 1
fi

echo "Detected IP: $SERVER_IP"
echo "DSpace UI will be available at: http://${SERVER_IP}:4000"
echo "DSpace REST API:                http://${SERVER_IP}:8080/server"
echo ""

# ── Write .env (skip if already exists) ──────────────────────────────────────
if [[ ! -f .env ]]; then
  cat > .env << EOF
SERVER_IP=${SERVER_IP}
POSTGRES_PASSWORD=BpolyRepo2025!
EOF
  echo ".env created."
else
  # Always update SERVER_IP in case the machine's IP changed
  sed -i "s/^SERVER_IP=.*/SERVER_IP=${SERVER_IP}/" .env
  echo ".env updated with current IP."
fi

# ── Update config.yml so Angular serves the correct REST host ────────────────
sed -i "s/^  host: .*/  host: ${SERVER_IP}/" config.yml

# ── Build BPoly Angular image if not already built ───────────────────────────
if ! docker image inspect bpoly-dspace-angular:latest &>/dev/null; then
  echo "Building BPoly Angular image (one-time, ~2 min)..."
  docker build -f Dockerfile.angular -t bpoly-dspace-angular:latest .
fi

# ── Start all services ────────────────────────────────────────────────────────
echo ""
echo "Starting DSpace (takes 3-5 minutes on first run)..."
docker compose -f docker-compose-campus.yml up -d

echo ""
echo "Watching startup — press Ctrl+C when you see 'Started ServerApplication'"
echo "(Angular will then auto-start)"
echo ""
docker logs -f dspace 2>&1 | grep -E "Started|ERROR|Caused by" || true

echo ""
echo "─────────────────────────────────────────────────────"
echo " Bulawayo Polytechnic DSpace is ready!"
echo " Open your browser: http://${SERVER_IP}:4000"
echo "─────────────────────────────────────────────────────"
