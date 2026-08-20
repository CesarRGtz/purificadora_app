create extension if not exists pgcrypto;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  rfc text not null,
  address text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint companies_business_name_length
    check (char_length(btrim(business_name)) between 3 and 200),
  constraint companies_rfc_format
    check (rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$'),
  constraint companies_address_length
    check (char_length(btrim(address)) between 5 and 500),
  constraint companies_phone_format
    check (phone ~ '^\+?[0-9]{10,15}$')
);

create index if not exists companies_business_name_search_idx
  on public.companies (lower(business_name));

create unique index if not exists companies_active_rfc_unique_idx
  on public.companies (rfc)
  where deleted_at is null;

create or replace function public.set_companies_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at
before update on public.companies
for each row execute function public.set_companies_updated_at();

alter table public.companies enable row level security;

revoke all on table public.companies from anon;
revoke all on table public.companies from authenticated;
grant select, insert, update on table public.companies to authenticated;

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
