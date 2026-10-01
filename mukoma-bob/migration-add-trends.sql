-- Run this in the Supabase SQL Editor (New query, then Run)
-- Adds what the Trends tab and duplicate-safe imports need to transactions.
-- Safe to run more than once.

-- 1. Spending group.
-- Left empty, the app picks a group automatically from the category
-- (e.g. "OK Zimbabwe" -> Groceries, "Chicken Inn" -> Fast food). It is only
-- filled in when someone corrects a group by hand, or when an imported
-- EcoCash message says the money was sent to a person. That group is then
-- reused for every other entry with the same category.
alter table transactions add column if not exists spend_group text;

-- 2. Time of day, as the clock read in Harare when the money moved.
alter table transactions add column if not exists occurred_time time;

-- 3. The imported message's own reference (e.g. the EcoCash approval code),
-- so the same SMS can never be imported twice, even from two phones at once.
-- Entries imported before this have no reference; the app checks those by
-- date, amount and time instead.
alter table transactions add column if not exists source_ref text;
create unique index if not exists transactions_source_ref_key
  on transactions (source_ref) where source_ref is not null;

-- Fill in times for entries logged before this column existed, from
-- created_at. The two kinds of entry stored it differently:
--
-- Imported messages saved the message's own clock time, e.g. "14:30", which
-- the database took to be UTC. Those are whole seconds, so their time is
-- read back as-is.
update transactions
set occurred_time = (created_at at time zone 'UTC')::time
where occurred_time is null
  and date_trunc('second', created_at) = created_at
  and (created_at at time zone 'UTC')::date = occurred_on;

-- Entries typed in by hand got the moment they were saved, with fractions of
-- a second. That is only the time the money moved if they were logged on the
-- same day; entries logged on a later day are left without a time.
update transactions
set occurred_time = date_trunc('second', created_at at time zone 'Africa/Harare')::time
where occurred_time is null
  and date_trunc('second', created_at) <> created_at
  and (created_at at time zone 'Africa/Harare')::date = occurred_on;
