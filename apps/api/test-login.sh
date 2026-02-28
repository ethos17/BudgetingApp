#!/usr/bin/env bash
# Quick test: login and then GET /me (requires API running on port 3000)
set -e
BASE="${1:-http://localhost:3000}"
COOKIE_FILE=$(mktemp)
trap "rm -f $COOKIE_FILE" EXIT

echo "=== 1. POST /auth/login ==="
RES=$(curl -s -w "\n%{http_code}" -c "$COOKIE_FILE" -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@ledgerlens.local","password":"Password123!"}')
BODY=$(echo "$RES" | head -n -1)
CODE=$(echo "$RES" | tail -n 1)
echo "Status: $CODE"
echo "Body: $BODY"
if [ "$CODE" != "200" ]; then
  echo "Login failed. Is the API running? (pnpm start:dev)"
  exit 1
fi

echo ""
echo "=== 2. GET /me (with cookie) ==="
RES=$(curl -s -w "\n%{http_code}" -b "$COOKIE_FILE" "$BASE/me")
BODY=$(echo "$RES" | head -n -1)
CODE=$(echo "$RES" | tail -n 1)
echo "Status: $CODE"
echo "Body: $BODY"
if [ "$CODE" != "200" ]; then
  echo "GET /me failed."
  exit 1
fi

echo ""
echo "Login flow OK."
