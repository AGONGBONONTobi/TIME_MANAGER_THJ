#!/usr/bin/env bash
# =============================================================================
# TEST M1 — Détection de token JWT dans localStorage (mobile bundle)
# =============================================================================
# Vérifie que le bundle JS mobile NE stocke JAMAIS de token JWT dans
# localStorage. Génère un rapport coloré dans le terminal.
#
# Usage :
#   chmod +x security/scripts/test_m1_localStorage.sh
#   bash security/scripts/test_m1_localStorage.sh [chemin/vers/bundle.js]
# =============================================================================

set -euo pipefail

# ─── Couleurs ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Configuration ─────────────────────────────────────────────────────────────
BUNDLE="${1:-mobile/www/assets/index-BCaN1ow8.js}"
REPORT_FILE="security/reports/report_m1_$(date +%Y%m%d_%H%M%S).txt"
PASS=0
FAIL=0
WARN=0

mkdir -p security/reports

# ─── Fonctions utilitaires ─────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}${BOLD}║       TEST SÉCURITÉ M1 — JWT / localStorage (Mobile)        ║${RESET}"
  echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "  Bundle cible  : ${BOLD}$BUNDLE${RESET}"
  echo -e "  Date          : $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "  Commit actuel : $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
  echo ""
}

count_pattern() {
  # Retourne un entier propre — compatible avec grep qui retourne exit 1 si 0 match
  local pattern="$1"
  local file="$2"
  local n
  n=$(grep -oP "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' \n') || true
  # wc -l peut retourner "     0" avec espaces, tr nettoie
  echo "${n:-0}"
}

check() {
  local desc="$1"
  local pattern="$2"
  local expect_zero="${3:-true}"   # true = on veut 0 occurrences (vulnérabilité absente)
  local count
  count=$(count_pattern "$pattern" "$BUNDLE")

  if [ "$expect_zero" = "true" ]; then
    if [ "$count" -eq 0 ]; then
      echo -e "  ${GREEN}✅ PASS${RESET}  $desc (0 occurrence)"
      echo "  [PASS] $desc (0 occurrence)" >> "$REPORT_FILE"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}❌ FAIL${RESET}  $desc (${count} occurrence(s) détectée(s))"
      echo "  [FAIL] $desc (${count} occurrences)" >> "$REPORT_FILE"
      FAIL=$((FAIL + 1))
    fi
  else
    # On veut AU MOINS 1 occurrence (présence d'un mécanisme de sécurité)
    if [ "$count" -gt 0 ]; then
      echo -e "  ${GREEN}✅ PASS${RESET}  $desc (${count} occurrence(s) présente(s))"
      echo "  [PASS] $desc (${count} occurrences)" >> "$REPORT_FILE"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}❌ FAIL${RESET}  $desc (absent du bundle)"
      echo "  [FAIL] $desc (absent)" >> "$REPORT_FILE"
      FAIL=$((FAIL + 1))
    fi
  fi
}

warn_check() {
  local desc="$1"
  local pattern="$2"
  local count
  count=$(count_pattern "$pattern" "$BUNDLE")

  if [ "$count" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  WARN${RESET}  $desc (${count} occurrence(s))"
    echo "  [WARN] $desc (${count} occurrences)" >> "$REPORT_FILE"
    WARN=$((WARN + 1))
  else
    echo -e "  ${GREEN}✅ INFO${RESET}  $desc (non présent)"
    echo "  [INFO] $desc (absent)" >> "$REPORT_FILE"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
print_header

# Écrire l'en-tête du rapport
{
  echo "============================================================"
  echo " RAPPORT TEST M1 — JWT / localStorage"
  echo " Bundle : $BUNDLE"
  echo " Date   : $(date '+%Y-%m-%d %H:%M:%S')"
  echo " Commit : $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
  echo "============================================================"
} > "$REPORT_FILE"

# ─── Vérification du bundle ────────────────────────────────────────────────────
if [ ! -f "$BUNDLE" ]; then
  echo -e "${RED}❌ Bundle introuvable : $BUNDLE${RESET}"
  echo "Spécifie le chemin du bundle JS : $0 <chemin/bundle.js>"
  exit 1
fi

BUNDLE_SIZE=$(du -h "$BUNDLE" | cut -f1)
echo -e "${BOLD}📦 Analyse du bundle ($BUNDLE_SIZE)...${RESET}"
echo ""

# ─── SECTION 1 : Détection de stockage JWT dans localStorage ──────────────────
echo -e "${BOLD}── Section 1 : Stockage du token JWT ──────────────────────────${RESET}"
echo "-- Section 1 : Stockage du token JWT --" >> "$REPORT_FILE"

# Pas de setItem avec les clés de token connues
check "localStorage.setItem n'écrit pas 'time_manager_token'" \
  "localStorage\.setItem\([^)]*time_manager_token[^)]*\)"

check "localStorage.setItem n'écrit pas 'time_manager_csrf_token'" \
  "localStorage\.setItem\([^)]*time_manager_csrf_token[^)]*\)"

# Pas de pattern de l'ancienne fonction vulnérable (fallback direct)
check "Pas de fallback localStorage pour le token (pattern Uu/Ku)" \
  "localStorage\.setItem\(Uu"

check "Pas de stockage de CSRF token dans localStorage" \
  "localStorage\.setItem\(Uu|localStorage\.setItem\(Hu"

# ─── SECTION 2 : Présence du mécanisme SecureStorage ──────────────────────────
echo ""
echo -e "${BOLD}── Section 2 : SecureStorage (mécanisme de remplacement) ──────${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- Section 2 : SecureStorage --" >> "$REPORT_FILE"

check "SecureStorage présent dans le bundle" \
  "SecureStorage" "false"

check "Mécanisme storage.set() présent (écriture sécurisée)" \
  "\.set\([a-z],[a-z],[a-z],[a-z]\)|storage\.set\|\.set\(resolve,reject\|\.set\(r,i" "false"

check "Rejet explicite si SecureStorage indisponible" \
  "Secure storage unavailable" "false"

# ─── SECTION 3 : Données sensibles dans localStorage ─────────────────────────
echo ""
echo -e "${BOLD}── Section 3 : Détection de données sensibles résiduelles ─────${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- Section 3 : Données sensibles résiduelles --" >> "$REPORT_FILE"

warn_check "localStorage contient des mots-clés 'password' ou 'secret'" \
  "localStorage\.setItem\([^)]*password[^)]*\)"

warn_check "Présence de token JWT en clair (eyJ)" \
  "eyJ[A-Za-z0-9_-]{10,}"

warn_check "localStorage.setItem global (données non sensibles)" \
  "localStorage\.setItem"

# ─── SECTION 4 : Vérification URL API sécurisée ───────────────────────────────
echo ""
echo -e "${BOLD}── Section 4 : URL API (pas de HTTP non chiffré) ──────────────${RESET}"
echo "" >> "$REPORT_FILE"
echo "-- Section 4 : URL API --" >> "$REPORT_FILE"

check "Pas d'URL http:// avec IP publique (non chiffré)" \
  "http://35\.[0-9]+\.[0-9]+\.[0-9]+"

check "Pas de port 4000 hardcodé dans le bundle" \
  ":4000"

check "URL HTTPS nip.io présente (proxy Nginx)" \
  "35\.192\.87\.173\.nip\.io" "false"

# ─── Résumé Final ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Résumé ──────────────────────────────────────────────────────${RESET}"

{
  echo ""
  echo "============================================================"
  echo " RÉSUMÉ"
  echo "============================================================"
  echo " PASS : $PASS"
  echo " FAIL : $FAIL"
  echo " WARN : $WARN"
} >> "$REPORT_FILE"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}🎉 RÉSULTAT : TOUTES LES VÉRIFICATIONS PASSENT${RESET}"
  echo -e "  Passes   : ${GREEN}$PASS${RESET}"
  echo -e "  Failures : ${GREEN}$FAIL${RESET}"
  echo -e "  Warnings : ${YELLOW}$WARN${RESET}"
  echo " RÉSULTAT : PASS — Faille M1 non détectée" >> "$REPORT_FILE"
else
  echo -e "  ${RED}${BOLD}🚨 RÉSULTAT : $FAIL VÉRIFICATION(S) ÉCHOUÉE(S) — VULNÉRABILITÉ M1 POSSIBLE${RESET}"
  echo -e "  Passes   : ${GREEN}$PASS${RESET}"
  echo -e "  Failures : ${RED}$FAIL${RESET}"
  echo -e "  Warnings : ${YELLOW}$WARN${RESET}"
  echo " RÉSULTAT : FAIL — Indices de vulnérabilité M1 détectés" >> "$REPORT_FILE"
fi

echo ""
echo -e "  📄 Rapport enregistré : ${BOLD}$REPORT_FILE${RESET}"
echo ""

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
