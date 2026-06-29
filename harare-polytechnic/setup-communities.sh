#!/usr/bin/env bash
# Creates the Harare Polytechnic faculty/department community structure in DSpace 8.
# Run AFTER the admin account has been created.
#
# Usage:
#   bash setup-communities.sh

set -euo pipefail

DSPACE_URL="${DSPACE_URL:-http://localhost:8080/server}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@harare-polytechnic.ac.zw}"
ADMIN_PASS="${ADMIN_PASS:-HPolyAdmin2025!}"

COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

get_csrf() {
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    "${DSPACE_URL}/api/authn/status" -o /dev/null
  grep -i dspace-xsrf-token "$COOKIE_JAR" | awk '{print $NF}'
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
  local name="$1" desc="$2" csrf="$3" token="$4"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/communities" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -d "{\"name\":\"${name}\",\"metadata\":{\"dc.title\":[{\"value\":\"${name}\",\"language\":\"en_US\"}],\"dc.description\":[{\"value\":\"${desc}\",\"language\":\"en_US\"}]}}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR'))"
}

create_subcommunity() {
  local parent="$1" name="$2" desc="$3" csrf="$4" token="$5"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/communities" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -G --data-urlencode "parent=${parent}" \
    -d "{\"name\":\"${name}\",\"metadata\":{\"dc.title\":[{\"value\":\"${name}\",\"language\":\"en_US\"}],\"dc.description\":[{\"value\":\"${desc}\",\"language\":\"en_US\"}]}}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR'))"
}

create_collection() {
  local parent="$1" name="$2" desc="$3" csrf="$4" token="$5"
  curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "${DSPACE_URL}/api/core/collections" \
    -H "Content-Type: application/json" \
    -H "X-XSRF-Token: ${csrf}" \
    -H "Authorization: ${token}" \
    -G --data-urlencode "parent=${parent}" \
    -d "{\"name\":\"${name}\",\"metadata\":{\"dc.title\":[{\"value\":\"${name}\",\"language\":\"en_US\"}],\"dc.description\":[{\"value\":\"${desc}\",\"language\":\"en_US\"}]}}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uuid','ERROR'))"
}

echo "Connecting to ${DSPACE_URL} ..."
CSRF=$(get_csrf)
TOKEN=$(login "$CSRF")
[[ -z "$TOKEN" ]] && { echo "Login failed. Check credentials."; exit 1; }
echo "Logged in as ${ADMIN_EMAIL}"
CSRF=$(grep -i dspace-xsrf-token "$COOKIE_JAR" | awk '{print $NF}')

echo ""
echo "Creating Harare Polytechnic communities..."

# Faculty of Engineering
echo -n "  Faculty of Engineering ... "
ENG=$(create_community "Faculty of Engineering" "Engineering research and projects" "$CSRF" "$TOKEN")
echo "$ENG"
for dept in "Civil Engineering" "Electrical Engineering" "Mechanical Engineering" "Electronics and Telecommunications"; do
  echo -n "    $dept ... "
  create_subcommunity "$ENG" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Faculty of Business Studies
echo -n "  Faculty of Business Studies ... "
BUS=$(create_community "Faculty of Business Studies" "Business research and projects" "$CSRF" "$TOKEN")
echo "$BUS"
for dept in "Accounting" "Business Management" "Marketing" "Human Resources Management" "Banking and Finance"; do
  echo -n "    $dept ... "
  create_subcommunity "$BUS" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Faculty of Applied Sciences
echo -n "  Faculty of Applied Sciences ... "
SCI=$(create_community "Faculty of Applied Sciences" "Applied Sciences research" "$CSRF" "$TOKEN")
echo "$SCI"
for dept in "Food Technology" "Chemistry" "Biology" "Environmental Science"; do
  echo -n "    $dept ... "
  create_subcommunity "$SCI" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Faculty of Information Technology
echo -n "  Faculty of Information Technology ... "
IT=$(create_community "Faculty of Information Technology" "IT research and projects" "$CSRF" "$TOKEN")
echo "$IT"
for dept in "Computer Science" "Information Systems" "Networking and Telecommunications" "Software Engineering"; do
  echo -n "    $dept ... "
  create_subcommunity "$IT" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Faculty of Art and Design
echo -n "  Faculty of Art and Design ... "
ART=$(create_community "Faculty of Art and Design" "Creative works and research" "$CSRF" "$TOKEN")
echo "$ART"
for dept in "Fine Art" "Fashion Design" "Graphic Design" "Interior Design"; do
  echo -n "    $dept ... "
  create_subcommunity "$ART" "Department of $dept" "$dept works" "$CSRF" "$TOKEN"
done

# Faculty of Built Environment
echo -n "  Faculty of Built Environment ... "
BUILT=$(create_community "Faculty of Built Environment" "Built Environment research" "$CSRF" "$TOKEN")
echo "$BUILT"
for dept in "Architecture" "Quantity Surveying" "Construction Management" "Land Surveying"; do
  echo -n "    $dept ... "
  create_subcommunity "$BUILT" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Faculty of Hospitality and Tourism
echo -n "  Faculty of Hospitality and Tourism ... "
HT=$(create_community "Faculty of Hospitality and Tourism" "Hospitality and Tourism research" "$CSRF" "$TOKEN")
echo "$HT"
for dept in "Hotel Management" "Tourism Management" "Catering and Food Service"; do
  echo -n "    $dept ... "
  create_subcommunity "$HT" "Department of $dept" "$dept research" "$CSRF" "$TOKEN"
done

# Library and Institutional Research
echo -n "  Library and Institutional Research ... "
LIB=$(create_community "Library and Institutional Research" "Institutional publications and research output" "$CSRF" "$TOKEN")
echo "$LIB"
echo -n "    Staff Publications ... "
create_collection "$LIB" "Staff Publications" "Peer-reviewed articles and reports by HPoly staff" "$CSRF" "$TOKEN"
echo -n "    Student Theses and Dissertations ... "
create_collection "$LIB" "Student Theses and Dissertations" "Final-year projects and dissertations" "$CSRF" "$TOKEN"
echo -n "    Institutional Policies ... "
create_collection "$LIB" "Institutional Policies" "Official policies and strategic documents" "$CSRF" "$TOKEN"

echo ""
echo "Done! Visit http://localhost:4000"
