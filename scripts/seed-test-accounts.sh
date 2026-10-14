#!/usr/bin/env bash
# scripts/seed-test-accounts.sh
# Seed 8 comptes de test + working times via l'API Phoenix (TIME_MANAGER_THJ)
#
# Prérequis : un compte admin existe déjà.
# Usage :
#   API=https://35.192.87.173.nip.io/api \
#   ADMIN_EMAIL=admin@tonorg.com \
#   ADMIN_PASSWORD='ton_mdp' \
#   ./scripts/seed-test-accounts.sh

set -euo pipefail

# ─── Config ────────────────────────────────────────────────
API="${API:-http://localhost:4000/api}"
ADMIN_EMAIL="${ADMIN_EMAIL:?ADMIN_EMAIL requis}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:?ADMIN_PASSWORD requis}"
COOKIE_JAR="$(mktemp)"
CREATED_FILE="$(mktemp)"   # stocke les couples email/mdp temporaire

# 8 comptes : username|email|role
USERS=(
  "alice|alice@test.local|employee"
  "bob|bob@test.local|employee"
  "chloe|chloe@test.local|manager"
  "david|david@test.local|employee"
  "emma|emma@test.local|employee"
  "farid|farid@test.local|manager"
  "grace|grace@test.local|employee"
  "hugo|hugo@test.local|employee"
)

# ─── Helpers ───────────────────────────────────────────────
log()  { printf "\033[1;34m▸\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; }

# Récupère la valeur du cookie CSRF (lisible, nommé xsrf_token côté Phoenix)
csrf_header() {
  local token
  token=$(awk '/xsrf_token/ {print $7}' "$COOKIE_JAR" | tail -1)
  [[ -n "$token" ]] && echo "x-xsrf-token: $token"
}

# ─── 1. Login admin ────────────────────────────────────────
log "Connexion admin : $ADMIN_EMAIL"

# 1a. Récupérer le cookie CSRF (Phoenix l'envoie sur GET /)
curl -sS -c "$COOKIE_JAR" "$API/../" >/dev/null 2>&1 || true

# 1b. POST login
LOGIN_RES=$(curl -sS -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
  -X POST "$API/auth/sign_in" \
  -H "Content-Type: application/json" \
  $(csrf_header | sed 's/^/-H /') \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
  -w "\n__HTTP__%{http_code}")

HTTP=$(echo "$LOGIN_RES" | sed -n 's/.*__HTTP__//p')
BODY=$(echo "$LOGIN_RES" | sed 's/__HTTP__.*//')

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  err "Login admin échoué (HTTP $HTTP)"
  echo "$BODY"
  exit 1
fi

if ! grep -q auth_token "$COOKIE_JAR"; then
  err "Pas de cookie auth_token — vérifie l'URL API ($API)"
  exit 1
fi
ok "Cookie admin obtenu"

# ─── 2. Créer les 8 comptes ────────────────────────────────
log "Création de ${#USERS[@]} comptes de test"

declare -a USER_IDS=()

for entry in "${USERS[@]}"; do
  IFS='|' read -r username email role <<< "$entry"

  PAYLOAD=$(jq -n \
    --arg u "$username" \
    --arg e "$email" \
    --arg r "$role" \
    '{user:{username:$u, email:$e, role:$r}}')

  RES=$(curl -sS -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -X POST "$API/users" \
    -H "Content-Type: application/json" \
    $(csrf_header | sed 's/^/-H /') \
    -d "$PAYLOAD" \
    -w "\n__HTTP__%{http_code}")

  HTTP=$(echo "$RES" | sed -n 's/.*__HTTP__//p')
  BODY=$(echo "$RES" | sed 's/__HTTP__.*//')

  UID=$(echo "$BODY" | jq -r '.id // .data.id // .user.id // empty' 2>/dev/null)
  TMP_PWD=$(echo "$BODY" | jq -r '.temporary_password // .temp_password // .password // empty' 2>/dev/null)

  if [[ -z "$UID" ]]; then
    warn "$email : échec création (HTTP $HTTP) → ${BODY:0:200}"
    continue
  fi

  USER_IDS+=("$UID")
  echo "$email|$TMP_PWD" >> "$CREATED_FILE"
  ok "$email → id=$UID (role=$role, mdp temp=${TMP_PWD:-?})"
done

# ─── 3. Working times (7 derniers jours ouvrés) ────────────
log "Insertion des working times (7 derniers jours ouvrés)"

for uid in "${USER_IDS[@]}"; do
  for d in {1..7}; do
    DAY=$(date -d "-$d day" +%Y-%m-%d)
    DOW=$(date -d "$DAY" +%u)
    (( DOW > 5 )) && continue

    START="${DAY}T09:00:00Z"
    END="${DAY}T17:30:00Z"

    PAYLOAD=$(jq -n \
      --arg s "$START" \
      --arg e "$END" \
      '{workingtime:{start:$s, end:$e, break_duration:30}}')

    curl -sS -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
      -X POST "$API/users/$uid/working-times" \
      -H "Content-Type: application/json" \
      $(csrf_header | sed 's/^/-H /') \
      -d "$PAYLOAD" >/dev/null
  done
  ok "Working times créés pour user id=$uid"
done

# ─── 4. Notifications ──────────────────────────────────────
warn "Notifications : pas d'endpoint POST → à créer côté serveur (voir iex plus bas)"

# ─── Résumé ────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════"
echo "  ✅ Seed terminé"
echo "════════════════════════════════════════════"
echo "  Admin : $ADMIN_EMAIL"
echo "  Comptes créés (email|mot de passe temporaire) :"
column -t -s'|' "$CREATED_FILE" 2>/dev/null || cat "$CREATED_FILE"
echo "════════════════════════════════════════════"
echo "  ⚠️  Les mots de passe temporaires doivent être"
echo "      changés au premier login (comportement Phoenix)."
echo "════════════════════════════════════════════"

rm -f "$COOKIE_JAR"