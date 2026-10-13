#!/bin/bash
# test_authz.sh
BASE="https://35.192.87.173.nip.io"

test_route() {
  local method=$1 route=$2 cookie=$3 xsrf=$4
  local headers=()
  [ -n "$cookie" ] && headers+=(-b "$cookie")
  [ -n "$xsrf" ] && headers+=(-H "x-xsrf-token: $xsrf")
  code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE$route" "${headers[@]}")
  echo "$method $route → $code"
}

# Sans JWT
test_route GET /api/auth/me "" ""
test_route GET /api/users "" ""
test_route PATCH /api/users/1/role "" ""

# Avec employee
test_route GET /api/auth/me /tmp/cookies_emp.txt "$XSRF_EMP"
test_route GET /api/users /tmp/cookies_emp.txt "$XSRF_EMP"
test_route GET /api/manager/team /tmp/cookies_emp.txt "$XSRF_EMP"
# ... etc