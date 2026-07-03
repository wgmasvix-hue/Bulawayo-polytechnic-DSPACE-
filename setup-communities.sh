#!/usr/bin/env bash
# Creates the Bulawayo Polytechnic faculty/department community structure in DSpace 8.
# Run AFTER the admin account has been created.
#
# Usage:
#   chmod +x setup-communities.sh
#   ./setup-communities.sh
#
# Defaults to http://localhost:8080/server.  Override with:
#   DSPACE_URL=http://your-host:8080/server ADMIN_EMAIL=admin@bpoly.ac.zw ./setup-communities.sh

set -euo pipefail

DSPACE_URL="${DSPACE_URL:-http://localhost:8080/server}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@bpoly.ac.zw}"
ADMIN_PASS="${ADMIN_PASS:-Bpoly@2025!}"

COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

# ── helpers ──────────────────────────────────────────────────────────────────

get_csrf() {
  # Extract XSRF token from response headers (DSpace 8 returns it there)
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -D - \
    "${DSPACE_URL}/api/authn/status" -o /dev/null \
    | grep -i "dspace-xsrf-token:" | awk '{print $2}' | tr -d '\r'
}

login() {
  local csrf="$1"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/authn/login" \
    -H "X-XSRF-Token: ${csrf}" \
    -d "user=${ADMIN_EMAIL}&password=${ADMIN_PASS}" \
    -D - -o /dev/null | grep -i "authorization:" | awk '{print $2}' | tr -d '\r'
}

create_community() {
  local name="$1" description="$2" csrf="$3" token="$4"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/communities" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -d "{
      \"name\": \"${name}\",
      \"metadata\": {
        \"dc.title\":       [{\"value\": \"${name}\",        \"language\": \"en_US\"}],
        \"dc.description\": [{\"value\": \"${description}\", \"language\": \"en_US\"}]
      }
    }" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR: '+str(d)))"
}

create_subcommunity() {
  local parent_uuid="$1" name="$2" description="$3" csrf="$4" token="$5"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/communities" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -G --data-urlencode "parent=${parent_uuid}" \
    -d "{
      \"name\": \"${name}\",
      \"metadata\": {
        \"dc.title\":       [{\"value\": \"${name}\",        \"language\": \"en_US\"}],
        \"dc.description\": [{\"value\": \"${description}\", \"language\": \"en_US\"}]
      }
    }" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR: '+str(d)))"
}

create_collection() {
  local parent_uuid="$1" name="$2" description="$3" csrf="$4" token="$5"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/collections" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -G --data-urlencode "parent=${parent_uuid}" \
    -d "{
      \"name\": \"${name}\",
      \"metadata\": {
        \"dc.title\":       [{\"value\": \"${name}\",        \"language\": \"en_US\"}],
        \"dc.description\": [{\"value\": \"${description}\", \"language\": \"en_US\"}]
      }
    }" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR: '+str(d)))"
}

# ── auth ─────────────────────────────────────────────────────────────────────

echo "Connecting to ${DSPACE_URL} ..."
CSRF=$(get_csrf)
TOKEN=$(login "$CSRF")

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Login failed. Check ADMIN_EMAIL and ADMIN_PASS."
  exit 1
fi
echo "Logged in as ${ADMIN_EMAIL}"

# Re-fetch CSRF after login (cookie is refreshed)
CSRF=$(grep -i dspace-xsrf-token "$COOKIE_JAR" | awk '{print $NF}')

# ── communities & collections ─────────────────────────────────────────────────

echo ""
echo "Creating top-level communities..."

# ── 1. Faculty of Engineering ─────────────────────────────────────────────────
echo -n "  Faculty of Engineering ... "
ENG=$(create_community "Faculty of Engineering" \
  "Research, projects and theses from the Faculty of Engineering" "$CSRF" "$TOKEN")
echo "$ENG"

echo -n "    Dept of Civil Engineering ... "
create_subcommunity "$ENG" "Department of Civil Engineering" \
  "Civil Engineering research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Electrical Engineering ... "
create_subcommunity "$ENG" "Department of Electrical Engineering" \
  "Electrical Engineering research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Mechanical Engineering ... "
create_subcommunity "$ENG" "Department of Mechanical Engineering" \
  "Mechanical Engineering research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Electronics ... "
create_subcommunity "$ENG" "Department of Electronics" \
  "Electronics research and student projects" "$CSRF" "$TOKEN"

# ── 2. Faculty of Business Studies ───────────────────────────────────────────
echo -n "  Faculty of Business Studies ... "
BUS=$(create_community "Faculty of Business Studies" \
  "Research, reports and theses from the Faculty of Business Studies" "$CSRF" "$TOKEN")
echo "$BUS"

echo -n "    Dept of Accounting ... "
create_subcommunity "$BUS" "Department of Accounting" \
  "Accounting research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Business Management ... "
create_subcommunity "$BUS" "Department of Business Management" \
  "Business Management research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Marketing ... "
create_subcommunity "$BUS" "Department of Marketing" \
  "Marketing research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Human Resources Management ... "
create_subcommunity "$BUS" "Department of Human Resources Management" \
  "Human Resources Management research and student projects" "$CSRF" "$TOKEN"

# ── 3. Faculty of Applied Sciences ───────────────────────────────────────────
echo -n "  Faculty of Applied Sciences ... "
SCI=$(create_community "Faculty of Applied Sciences" \
  "Research, reports and theses from the Faculty of Applied Sciences" "$CSRF" "$TOKEN")
echo "$SCI"

echo -n "    Dept of Food Technology ... "
create_subcommunity "$SCI" "Department of Food Technology" \
  "Food Technology research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Chemistry ... "
create_subcommunity "$SCI" "Department of Chemistry" \
  "Chemistry research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Biology ... "
create_subcommunity "$SCI" "Department of Biology" \
  "Biology research and student projects" "$CSRF" "$TOKEN"

# ── 4. Faculty of Information Technology ─────────────────────────────────────
echo -n "  Faculty of Information Technology ... "
IT=$(create_community "Faculty of Information Technology" \
  "Research, projects and theses from the Faculty of Information Technology" "$CSRF" "$TOKEN")
echo "$IT"

echo -n "    Dept of Computer Science ... "
create_subcommunity "$IT" "Department of Computer Science" \
  "Computer Science research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Information Systems ... "
create_subcommunity "$IT" "Department of Information Systems" \
  "Information Systems research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Networking and Telecommunications ... "
create_subcommunity "$IT" "Department of Networking and Telecommunications" \
  "Networking and Telecommunications research and student projects" "$CSRF" "$TOKEN"

# ── 5. Faculty of Art and Design ─────────────────────────────────────────────
echo -n "  Faculty of Art and Design ... "
ART=$(create_community "Faculty of Art and Design" \
  "Creative works, research and theses from the Faculty of Art and Design" "$CSRF" "$TOKEN")
echo "$ART"

echo -n "    Dept of Fine Art ... "
create_subcommunity "$ART" "Department of Fine Art" \
  "Fine Art works and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Fashion Design ... "
create_subcommunity "$ART" "Department of Fashion Design" \
  "Fashion Design works and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Graphic Design ... "
create_subcommunity "$ART" "Department of Graphic Design" \
  "Graphic Design works and student projects" "$CSRF" "$TOKEN"

# ── 6. Faculty of Built Environment ──────────────────────────────────────────
echo -n "  Faculty of Built Environment ... "
BUILT=$(create_community "Faculty of Built Environment" \
  "Research, projects and theses from the Faculty of Built Environment" "$CSRF" "$TOKEN")
echo "$BUILT"

echo -n "    Dept of Architecture ... "
create_subcommunity "$BUILT" "Department of Architecture" \
  "Architecture research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Quantity Surveying ... "
create_subcommunity "$BUILT" "Department of Quantity Surveying" \
  "Quantity Surveying research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Construction Management ... "
create_subcommunity "$BUILT" "Department of Construction Management" \
  "Construction Management research and student projects" "$CSRF" "$TOKEN"

# ── 7. Faculty of Hospitality and Tourism ────────────────────────────────────
echo -n "  Faculty of Hospitality and Tourism ... "
HT=$(create_community "Faculty of Hospitality and Tourism" \
  "Research, reports and theses from the Faculty of Hospitality and Tourism" "$CSRF" "$TOKEN")
echo "$HT"

echo -n "    Dept of Hotel Management ... "
create_subcommunity "$HT" "Department of Hotel Management" \
  "Hotel Management research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of Tourism ... "
create_subcommunity "$HT" "Department of Tourism" \
  "Tourism research and student projects" "$CSRF" "$TOKEN"

# ── 8. Faculty of Applied Languages ──────────────────────────────────────────
echo -n "  Faculty of Applied Languages ... "
LANG=$(create_community "Faculty of Applied Languages" \
  "Research, reports and theses from the Faculty of Applied Languages" "$CSRF" "$TOKEN")
echo "$LANG"

echo -n "    Dept of English ... "
create_subcommunity "$LANG" "Department of English" \
  "English language research and student projects" "$CSRF" "$TOKEN"

echo -n "    Dept of French ... "
create_subcommunity "$LANG" "Department of French" \
  "French language research and student projects" "$CSRF" "$TOKEN"

# ── 9. Library and Institutional Research ────────────────────────────────────
echo -n "  Library and Institutional Research ... "
LIB=$(create_community "Library and Institutional Research" \
  "Institutional publications, policies, and research output from Bulawayo Polytechnic" "$CSRF" "$TOKEN")
echo "$LIB"

echo -n "    Staff Publications ... "
create_collection "$LIB" "Staff Publications" \
  "Peer-reviewed articles, conference papers and reports by Bulawayo Polytechnic staff" "$CSRF" "$TOKEN"

echo -n "    Student Theses and Dissertations ... "
create_collection "$LIB" "Student Theses and Dissertations" \
  "Final-year projects, dissertations and theses submitted at Bulawayo Polytechnic" "$CSRF" "$TOKEN"

echo -n "    Institutional Policies ... "
create_collection "$LIB" "Institutional Policies" \
  "Official policies, procedures and strategic documents of Bulawayo Polytechnic" "$CSRF" "$TOKEN"

echo ""
echo "Done. Visit http://144.91.125.128:4000 to see the communities."
