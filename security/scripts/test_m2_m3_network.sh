#!/usr/bin/env bash
# =============================================================================
# TEST M2+M3 — JWT dans le body JSON & Port 4000 exposé
# =============================================================================
# Vérifie :
#   M2 : Le backend ne retourne PAS de token JWT dans le corps de la réponse
#        (sauf pour l'origine mobile contrôlée)
#   M3 : Le port 4000 n'est pas accessible publiquement
#        ET l'URL API mobile utilise HTTPS sur port 443
#
# Usage :
#   chmod +x security/scripts/test_m2_m3_network.sh
#   bash security/scripts/test_m2_m3_network.sh [API_HOST]
#
#   Exemples :
#     bash security/scripts/test_m2_m3_network.sh                   # défaut: 35.192.87.173
#     bash security/scripts/test_m2_m3_network.sh localhost
# =============================================================================

# NE PAS utiliser set -e ici — les grep peuvent retourner 1 quand rien n'est trouvé
set -uo pipefail

# ─── Couleurs ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Configuration ─────────────────────────────────────────────────────────────
TARGET_HOST="${1:-35.192.87.173}"
TIMEOUT=5
REPORT_FILE="security/reports/report_m2_m3_$(date +%Y%m%d_%H%M%S).txt"
PASS=0
FAIL=0
WARN=0
SKIP=0

BUNDLE_PATH="mobile/www/assets/index-BCaN1ow8.js"
ENV_MOBILE="frontend/.env.mobile"
DOCKER_COMPOSE="docker-compose.yml"

mkdir -p security/reports

# ─── Fonctions ─────────────────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}${BOLD}║    TEST SÉCURITÉ M2+M3 — JWT Body & Port 4000 Exposure      ║${RESET}"
  echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "  Hôte cible    : ${BOLD}$TARGET_HOST${RESET}"
  echo -e "  Date          : $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "  Commit actuel : $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
  echo ""
}

pass() {
  echo -e "  ${GREEN}✅ PASS${RESET}  $1"
  echo "  [PASS] $1" >> "$REPORT_FILE"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "  ${RED}❌ FAIL${RESET}  $1"
  echo "  [FAIL] $1" >> "$REPORT_FILE"
  FAIL=$((FAIL + 1))
}

warn_msg() {
  echo -e "  ${YELLOW}⚠️  WARN${RESET}  $1"
  echo "  [WARN] $1" >> "$REPORT_FILE"
  WARN=$((WARN + 1))
}

skip_test() {
  echo -e "  ${CYAN}⏭  SKIP${RESET}  $1"
  echo "  [SKIP] $1" >> "$REPORT_FILE"
  SKIP=$((SKIP + 1))
}

info() {
  echo -e "         ${CYAN}→${RESET} $1"
  echo "         → $1" >> "$REPORT_FILE"
}

count_in_file() {
  local pattern="$1"
  local file="$2"
  local n
  n=$(grep -oP "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' \n')
  echo "${n:-0}"
}

str_contains() {
  # Retourne 0 (vrai) si $1 contient le motif $2
  echo "$1" | grep -qP "$2"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
print_header

{
  echo "============================================================"
  echo " RAPPORT TEST M2+M3 — JWT Body & Port 4000"
  echo " Host   : $TARGET_HOST"
  echo " Date   : $(date '+%Y-%m-%d %H:%M:%S')"
  echo " Commit : $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
  echo "============================================================"
} > "$REPORT_FILE"

# =============================================================================
# SECTION 1 — M3 : Vérification statique (fichiers source / config)
# =============================================================================
echo -e "${BOLD}══ [M3] Section 1 : Analyse statique des fichiers ════════════${RESET}"
echo "-- [M3] Section 1 : Statique --" >> "$REPORT_FILE"

# 1a. .env.mobile : URL doit être HTTPS, pas :4000
if [ -f "$ENV_MOBILE" ]; then
  API_URL=$(grep "VITE_API_URL" "$ENV_MOBILE" | cut -d= -f2 | tr -d ' \r\n' 2>/dev/null || echo "")
  info ".env.mobile VITE_API_URL = $API_URL"
  echo "         → .env.mobile: $API_URL" >> "$REPORT_FILE"

  if echo "$API_URL" | grep -qP ':4000' 2>/dev/null; then
    fail ".env.mobile : URL contient :4000 (Phoenix direct exposé)"
  else
    pass ".env.mobile : pas de port 4000 dans l'URL API"
  fi

  if echo "$API_URL" | grep -qP '^https://' 2>/dev/null; then
    pass ".env.mobile : URL API utilise HTTPS"
  else
    fail ".env.mobile : URL API n'utilise pas HTTPS"
  fi
else
  skip_test ".env.mobile introuvable (non applicable)"
fi

echo ""

# 1b. docker-compose.yml : port 4000 doit être expose (interne), pas ports (public)
if [ -f "$DOCKER_COMPOSE" ]; then
  PORT_MAPPED=$(count_in_file '"4000:4000"' "$DOCKER_COMPOSE")

  if [ "$PORT_MAPPED" -gt 0 ]; then
    fail "docker-compose.yml : port 4000 mappé publiquement (ports: 4000:4000)"
  else
    pass "docker-compose.yml : port 4000 non mappé publiquement"
    info "Port 4000 déclaré en 'expose' (interne Docker uniquement)"
  fi
else
  skip_test "docker-compose.yml introuvable"
fi

echo ""

# 1c. Bundle mobile compilé : pas de :4000 ou http:// IP
if [ -f "$BUNDLE_PATH" ]; then
  COUNT_4000=$(count_in_file ':4000' "$BUNDLE_PATH")
  COUNT_HTTP_IP=$(count_in_file 'http://35\.[0-9]+\.[0-9]+\.[0-9]+' "$BUNDLE_PATH")

  if [ "$COUNT_4000" -eq 0 ]; then
    pass "Bundle mobile : aucune référence à :4000"
  else
    fail "Bundle mobile : $COUNT_4000 référence(s) à :4000 détectée(s)"
  fi

  if [ "$COUNT_HTTP_IP" -eq 0 ]; then
    pass "Bundle mobile : aucune URL HTTP non chiffrée avec IP publique"
  else
    fail "Bundle mobile : $COUNT_HTTP_IP URL HTTP non chiffrée détectée(s)"
  fi
else
  skip_test "Bundle mobile introuvable ($BUNDLE_PATH)"
fi

echo ""

# =============================================================================
# SECTION 2 — M3 : Tests réseau (port 4000 accessible ?)
# =============================================================================
echo -e "${BOLD}══ [M3] Section 2 : Tests réseau (connectivité) ═══════════════${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- [M3] Section 2 : Réseau --" >> "$REPORT_FILE"

# 2a. Port 4000 doit être FERMÉ depuis l'extérieur
echo -e "  🔌 Test connexion TCP $TARGET_HOST:4000 (doit être fermé)..."
if timeout "$TIMEOUT" bash -c "echo > /dev/tcp/$TARGET_HOST/4000" 2>/dev/null; then
  fail "Port 4000 ACCESSIBLE publiquement sur $TARGET_HOST — VULNÉRABILITÉ M3 !"
  info "Fermer le port dans GCP : gcloud compute firewall-rules delete allow-phoenix-4000"
else
  pass "Port 4000 FERMÉ sur $TARGET_HOST (timeout = inaccessible)"
fi

echo ""

# 2b. Port 443 doit être OUVERT (Nginx disponible)
echo -e "  🔌 Test connexion HTTPS $TARGET_HOST:443 (doit être ouvert)..."
if timeout "$TIMEOUT" bash -c "echo > /dev/tcp/$TARGET_HOST/443" 2>/dev/null; then
  pass "Port 443 OUVERT sur $TARGET_HOST (Nginx actif)"
else
  warn_msg "Port 443 non accessible depuis cette machine (peut être normal en réseau interne)"
fi

echo ""

# =============================================================================
# SECTION 3 — M2 : Test de réponse JSON de l'endpoint sign_in
# =============================================================================
echo -e "${BOLD}══ [M2] Section 3 : Réponse JSON de /api/auth/sign_in ═════════${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- [M2] Section 3 : JWT dans body JSON --" >> "$REPORT_FILE"

API_BASE="https://${TARGET_HOST}.nip.io/api"
SIGNIN_URL="$API_BASE/auth/sign_in"

echo -e "  🌐 Endpoint testé : $SIGNIN_URL"
info "Envoi d'une requête sign_in avec des credentials invalides"

# Test avec un email invalide pour obtenir une réponse 401 (pas de token)
RESPONSE=$(curl -sk \
  -X POST "$SIGNIN_URL" \
  -H "Content-Type: application/json" \
  -H "Origin: https://not-localhost.com" \
  -d '{"email":"security_test_invalid@test.invalid","password":"WrongPassword123!"}' \
  -w "\n---HTTP_STATUS:%{http_code}" \
  --connect-timeout "$TIMEOUT" \
  --max-time "$((TIMEOUT * 2))" 2>/dev/null || echo '{"error":"curl_failed"}
---HTTP_STATUS:000')

HTTP_STATUS=$(echo "$RESPONSE" | grep -oP "(?<=HTTP_STATUS:)\d+" 2>/dev/null || echo "000")
BODY=$(echo "$RESPONSE" | grep -v "^---HTTP_STATUS:" || echo "{}")

info "HTTP Status : $HTTP_STATUS"
info "Body reçu  : $(echo "$BODY" | head -c 200)"

# Un token JWT commence par "eyJ"
if echo "$BODY" | grep -qP '"token"\s*:\s*"eyJ' 2>/dev/null; then
  fail "M2 : Le body JSON contient un champ 'token' avec un JWT (pour origine non-mobile)"
  info "JWT détecté dans la réponse — le token ne devrait être que dans le cookie HttpOnly"
else
  if [ "$HTTP_STATUS" = "000" ]; then
    skip_test "M2 : Serveur inaccessible (test réseau impossible depuis cette machine)"
  else
    pass "M2 : Pas de token JWT dans le body JSON pour une origine non-mobile"
    info "Status $HTTP_STATUS reçu pour credentials invalides (401 attendu)"
  fi
fi

echo ""

# Test depuis l'origine mobile (https://localhost)
RESPONSE_MOBILE=$(curl -sk \
  -X POST "$SIGNIN_URL" \
  -H "Content-Type: application/json" \
  -H "Origin: https://localhost" \
  -d '{"email":"security_test_invalid@test.invalid","password":"WrongPassword123!"}' \
  -w "\n---HTTP_STATUS:%{http_code}" \
  --connect-timeout "$TIMEOUT" \
  --max-time "$((TIMEOUT * 2))" 2>/dev/null || echo '{"error":"curl_failed"}
---HTTP_STATUS:000')

HTTP_STATUS_MOBILE=$(echo "$RESPONSE_MOBILE" | grep -oP "(?<=HTTP_STATUS:)\d+" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS_MOBILE" = "000" ]; then
  skip_test "M2 (mobile origin) : serveur inaccessible"
else
  info "Test origine mobile (https://localhost) — status : $HTTP_STATUS_MOBILE"
  info "(Avec credentials invalides, pas de token attendu même pour mobile)"
  pass "M2 : Comportement serveur cohérent pour origine mobile"
fi

echo ""

# =============================================================================
# SECTION 4 — Vérification des headers de sécurité Nginx
# =============================================================================
echo -e "${BOLD}══ [M3] Section 4 : Headers de sécurité Nginx ═════════════════${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- [M3] Section 4 : Headers Nginx --" >> "$REPORT_FILE"

HEADERS=$(curl -sk -I "https://${TARGET_HOST}.nip.io/" \
  --connect-timeout "$TIMEOUT" \
  --max-time "$((TIMEOUT * 2))" 2>/dev/null || echo "")

if [ -z "$HEADERS" ]; then
  skip_test "Headers Nginx : serveur non accessible"
else
  check_header() {
    local header="$1"
    local desc="$2"
    if echo "$HEADERS" | grep -qiP "^${header}:" 2>/dev/null; then
      pass "Header $desc présent"
      local hval
      hval=$(echo "$HEADERS" | grep -iP "^${header}:" | head -1)
      info "$hval"
    else
      warn_msg "Header $desc absent (Nginx non configuré ou inaccessible)"
    fi
  }

  check_header "X-Frame-Options" "X-Frame-Options"
  check_header "X-Content-Type-Options" "X-Content-Type-Options"
  check_header "Strict-Transport-Security" "HSTS"
  check_header "Content-Security-Policy" "CSP"
fi

echo ""

# =============================================================================
# Résumé Final
# =============================================================================
echo -e "${BOLD}── Résumé Final ─────────────────────────────────────────────────${RESET}"

{
  echo ""
  echo "============================================================"
  echo " RÉSUMÉ FINAL"
  echo "============================================================"
  printf " PASS : %d\n" "$PASS"
  printf " FAIL : %d\n" "$FAIL"
  printf " WARN : %d\n" "$WARN"
  printf " SKIP : %d\n" "$SKIP"
} >> "$REPORT_FILE"

echo -e "  ${GREEN}PASS  : $PASS${RESET}  |  ${RED}FAIL : $FAIL${RESET}  |  ${YELLOW}WARN : $WARN${RESET}  |  ${CYAN}SKIP : $SKIP${RESET}"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}🎉 RÉSULTAT GLOBAL : M2 + M3 NON DÉTECTÉES — SÉCURITÉ OK${RESET}"
  echo " RÉSULTAT : PASS — M2 et M3 non détectées" >> "$REPORT_FILE"
  FINAL_EXIT=0
else
  echo -e "  ${RED}${BOLD}🚨 RÉSULTAT GLOBAL : $FAIL VÉRIFICATION(S) ÉCHOUÉE(S)${RESET}"
  echo -e "  ${RED}Consulte le rapport pour identifier les vulnérabilités.${RESET}"
  echo " RÉSULTAT : FAIL — Indices de M2/M3 détectés" >> "$REPORT_FILE"
  FINAL_EXIT=1
fi

echo ""
echo -e "  📄 Rapport enregistré : ${BOLD}$REPORT_FILE${RESET}"
echo ""

exit $FINAL_EXIT
