#!/usr/bin/env bash
# Runs the ledger against a local copy of Supabase in Docker, filled with
# made-up sample data. Nothing here touches the real ledger. See LOCAL-TESTING.md.
set -euo pipefail
cd "$(dirname "$0")"

# Only the parts the app uses: the database, login (gotrue), the data API
# (postgrest) and the gateway in front of them (kong). Everything else is
# skipped, which saves several large downloads.
npx --yes supabase@2 start \
  -x realtime,storage-api,imgproxy,mailpit,postgres-meta,studio,edge-runtime,logflare,vector,supavisor

# The test login. Sign-ups are off (as on the real site), so it is created
# through the admin API. Already existing is fine.
eval "$(npx --yes supabase@2 status -o env 2>/dev/null | grep -E '^(API_URL|SERVICE_ROLE_KEY)=')"
curl -s -o /dev/null -X POST "$API_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ledger.local","password":"ledger-test","email_confirm":true}' || true

echo
echo "  Open:     http://localhost:8000/mukoma-bob/"
echo "  Log in:   test@ledger.local / ledger-test"
echo "  Stop with Ctrl+C, then: npx supabase stop"
echo

cd .. && python3 -m http.server 8000
