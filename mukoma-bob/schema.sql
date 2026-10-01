-- Mukoma Bob's Ledger — database setup
-- For a NEW Supabase project: paste this whole file into Supabase → SQL Editor → New query → Run
--
-- This creates the tables as the app uses them today. The migration-*.sql
-- files are only for bringing an older database up to date; a database set up
-- from this file already has everything they add.

-- Goals (savings targets)
create table goals (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  target_amount numeric not null,
  current_amount numeric not null default 0,
  target_date date,
  category text not null default 'Savings',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- Transactions (income + expenses)
create table transactions (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('income', 'expense')),
  category text not null,
  amount numeric not null,
  occurred_on date not null default current_date,
  occurred_time time,          -- Harare clock time, when known
  note text,
  balance numeric,             -- account balance after, from bank/EcoCash messages
  spend_group text,            -- set by hand; empty means the app picks one
  source_ref text,             -- the message's own reference, for imported entries
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- The same SMS can never be imported twice, even from two phones at once.
create unique index transactions_source_ref_key on transactions (source_ref) where source_ref is not null;

-- Debts
create table debts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  total_amount numeric not null,
  remaining_amount numeric not null default 0,
  due_date date,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- Lock the tables down: only logged-in users (you two) can touch them.
-- This works because sign-ups will be disabled, so the ONLY accounts that
-- can ever exist are the ones you create by hand in the Auth tab.
alter table goals enable row level security;
alter table transactions enable row level security;
alter table debts enable row level security;

create policy "authenticated read goals" on goals
  for select using (auth.role() = 'authenticated');
create policy "authenticated write goals" on goals
  for insert with check (auth.role() = 'authenticated');
create policy "authenticated update goals" on goals
  for update using (auth.role() = 'authenticated');
create policy "authenticated delete goals" on goals
  for delete using (auth.role() = 'authenticated');

create policy "authenticated read transactions" on transactions
  for select using (auth.role() = 'authenticated');
create policy "authenticated write transactions" on transactions
  for insert with check (auth.role() = 'authenticated');
create policy "authenticated update transactions" on transactions
  for update using (auth.role() = 'authenticated');
create policy "authenticated delete transactions" on transactions
  for delete using (auth.role() = 'authenticated');

create policy "authenticated read debts" on debts
  for select using (auth.role() = 'authenticated');
create policy "authenticated write debts" on debts
  for insert with check (auth.role() = 'authenticated');
create policy "authenticated update debts" on debts
  for update using (auth.role() = 'authenticated');
create policy "authenticated delete debts" on debts
  for delete using (auth.role() = 'authenticated');
