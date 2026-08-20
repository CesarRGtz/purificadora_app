alter table public.companies
  add column if not exists deleted_at timestamptz;

alter table public.companies
  drop constraint if exists companies_rfc_unique;

create unique index if not exists companies_active_rfc_unique_idx
  on public.companies (rfc)
  where deleted_at is null;

revoke all on table public.companies from authenticated;
grant select, insert, update on table public.companies to authenticated;

drop policy if exists "Authenticated users can read companies"
  on public.companies;
drop policy if exists "Authenticated users can create companies"
  on public.companies;
drop policy if exists "Authenticated users can update companies"
  on public.companies;
drop policy if exists "Authenticated users can delete companies"
  on public.companies;

create policy "Authenticated users can read companies"
on public.companies for select
to authenticated
using (deleted_at is null);

create policy "Authenticated users can create companies"
on public.companies for insert
to authenticated
with check (deleted_at is null);

create policy "Authenticated users can update companies"
on public.companies for update
to authenticated
using (deleted_at is null)
with check (true);

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  branch_name text not null,
  name text not null,
  address text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint suppliers_branch_name_length
    check (char_length(btrim(branch_name)) between 2 and 150),
  constraint suppliers_name_length
    check (char_length(btrim(name)) between 2 and 200),
  constraint suppliers_address_length
    check (char_length(btrim(address)) between 5 and 500),
  constraint suppliers_phone_format
    check (phone ~ '^\+?[0-9]{10,15}$')
);

create index if not exists suppliers_active_name_idx
  on public.suppliers (lower(name))
  where deleted_at is null;

create index if not exists suppliers_active_branch_idx
  on public.suppliers (lower(branch_name))
  where deleted_at is null;

create or replace function public.set_suppliers_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists suppliers_set_updated_at on public.suppliers;
create trigger suppliers_set_updated_at
before update on public.suppliers
for each row execute function public.set_suppliers_updated_at();

alter table public.suppliers enable row level security;

revoke all on table public.suppliers from anon;
revoke all on table public.suppliers from authenticated;
grant select, insert, update on table public.suppliers to authenticated;

create policy "Authenticated users can read suppliers"
on public.suppliers for select
to authenticated
using (deleted_at is null);

create policy "Authenticated users can create suppliers"
on public.suppliers for insert
to authenticated
with check (deleted_at is null);

create policy "Authenticated users can update suppliers"
on public.suppliers for update
to authenticated
using (deleted_at is null)
with check (true);
