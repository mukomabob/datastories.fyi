# Testing the ledger on your own computer

This runs the app against a **local copy of the database** in Docker, filled
with made-up sample data. Nothing you do here touches the real ledger. The
page shows **LOCAL TEST DATABASE** next to your email when it is using the
local copy.

## What you need

- Docker Desktop, running
- Node.js (for `npx`) and Python 3 (both come with most Macs' dev tools)

## Start it

```bash
cd mukoma-bob
./local-test.sh
```

The first run downloads the database, login and API images, which takes a few minutes. If Docker is set to use a work proxy, you need to be on that network (or turn the proxy off in Docker Desktop → Settings → Resources → Proxies). Then
open **http://localhost:8000/mukoma-bob/** and log in with
`test@ledger.local` / `ledger-test`.

Stop with Ctrl+C, then `npx supabase stop`.

## What gets loaded

`supabase/migrations/` points at the real `schema.sql` and
`migration-add-trends.sql`, so the local database is built by exactly the SQL
the live one uses. `supabase/seed.sql` then adds about 200 made-up
transactions over the last few pay cycles, two goals and a debt.

To throw away everything you changed and start again from the sample data:

```bash
npx supabase db reset
./local-test.sh
```

## Testing duplicate checks

Paste the contents of `sample-messages.txt` into **Import messages** and
press Parse. You should see:

- **Chicken Inn, 27 Sep:** already in the ledger (same approval code), can't be ticked
- **Tendai Moyo:** pasted twice, kept once
- **Pick n Pay bank debit, 29 Sep:** possible duplicate of an older entry
  without a reference, unticked
- **ZIPIT, Pizza Inn, loan recovery, airtime recharge, Netflix card payment:** new

Import them, then paste the same text again: everything should now say
"already in the ledger".
