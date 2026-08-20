create extension if not exists pgcrypto;

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  business_name text not null,
  address text not null,
  latitude numeric(9, 6) not null,
  longitude numeric(10, 6) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint branches_name_length
    check (char_length(btrim(name)) between 2 and 150),
  constraint branches_business_name_length
    check (char_length(btrim(business_name)) between 2 and 200),
  constraint branches_address_length
    check (char_length(btrim(address)) between 5 and 500),
  constraint branches_latitude_range
    check (latitude between -90 and 90),
  constraint branches_longitude_range
    check (longitude between -180 and 180)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text not null,
  description text not null default '',
  base_price numeric(12, 2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint products_name_length
    check (char_length(btrim(name)) between 2 and 200),
  constraint products_sku_format
    check (sku ~ '^[A-Z0-9][A-Z0-9._-]{1,49}$'),
  constraint products_description_length
    check (char_length(description) <= 500),
  constraint products_base_price_range
    check (base_price between 0 and 9999999999.99)
);

create table if not exists public.branch_products (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists branches_active_name_idx
  on public.branches (lower(name))
  where deleted_at is null;

create unique index if not exists products_active_sku_unique_idx
  on public.products (sku)
  where deleted_at is null;

create index if not exists products_active_name_idx
  on public.products (lower(name))
  where deleted_at is null;

create unique index if not exists branch_products_active_unique_idx
  on public.branch_products (branch_id, product_id)
  where deleted_at is null;

create index if not exists branch_products_active_branch_idx
  on public.branch_products (branch_id)
  where deleted_at is null;

create index if not exists branch_products_active_product_idx
  on public.branch_products (product_id)
  where deleted_at is null;

create or replace function public.set_branches_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.set_products_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.set_branch_products_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists branches_set_updated_at on public.branches;
create trigger branches_set_updated_at
before update on public.branches
for each row execute function public.set_branches_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute function public.set_products_updated_at();

drop trigger if exists branch_products_set_updated_at
  on public.branch_products;
create trigger branch_products_set_updated_at
before update on public.branch_products
for each row execute function public.set_branch_products_updated_at();

alter table public.branches enable row level security;
alter table public.products enable row level security;
alter table public.branch_products enable row level security;

revoke all on table public.branches from anon;
revoke all on table public.products from anon;
revoke all on table public.branch_products from anon;
revoke all on table public.branches from authenticated;
revoke all on table public.products from authenticated;
revoke all on table public.branch_products from authenticated;
grant select, insert, update on table public.branches to authenticated;
grant select, insert, update on table public.products to authenticated;
grant select, insert, update on table public.branch_products to authenticated;

create policy "Authenticated users can read branches"
on public.branches for select
to authenticated
using (deleted_at is null);

create policy "Authenticated users can create branches"
on public.branches for insert
to authenticated
with check (deleted_at is null);

create policy "Authenticated users can update branches"
on public.branches for update
to authenticated
using (deleted_at is null)
with check (true);

create policy "Authenticated users can read products"
on public.products for select
to authenticated
using (deleted_at is null);

create policy "Authenticated users can create products"
on public.products for insert
to authenticated
with check (deleted_at is null);

create policy "Authenticated users can update products"
on public.products for update
to authenticated
using (deleted_at is null)
with check (true);

create policy "Authenticated users can read branch products"
on public.branch_products for select
to authenticated
using (
  deleted_at is null
  and exists (
    select 1 from public.branches
    where branches.id = branch_products.branch_id
      and branches.deleted_at is null
  )
  and exists (
    select 1 from public.products
    where products.id = branch_products.product_id
      and products.deleted_at is null
  )
);

create policy "Authenticated users can create branch products"
on public.branch_products for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1 from public.branches
    where branches.id = branch_products.branch_id
      and branches.deleted_at is null
  )
  and exists (
    select 1 from public.products
    where products.id = branch_products.product_id
      and products.deleted_at is null
  )
);

create policy "Authenticated users can update branch products"
on public.branch_products for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or (
    exists (
      select 1 from public.branches
      where branches.id = branch_products.branch_id
        and branches.deleted_at is null
    )
    and exists (
      select 1 from public.products
      where products.id = branch_products.product_id
        and products.deleted_at is null
    )
  )
);

create or replace function public.soft_delete_branch_links()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.branch_products
  set deleted_at = new.deleted_at
  where branch_id = new.id
    and deleted_at is null;
  return new;
end;
$$;

create or replace function public.soft_delete_product_links()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.branch_products
  set deleted_at = new.deleted_at
  where product_id = new.id
    and deleted_at is null;
  return new;
end;
$$;

drop trigger if exists branches_soft_delete_links on public.branches;
create trigger branches_soft_delete_links
after update of deleted_at on public.branches
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_branch_links();

drop trigger if exists products_soft_delete_links on public.products;
create trigger products_soft_delete_links
after update of deleted_at on public.products
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_product_links();

create or replace function public.configure_branch_products(
  p_branch_id uuid,
  p_product_ids uuid[]
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform 1
  from public.branches
  where id = p_branch_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'La sucursal no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from unnest(coalesce(p_product_ids, array[]::uuid[]))
      as requested(product_id)
    where not exists (
      select 1
      from public.products
      where products.id = requested.product_id
        and products.deleted_at is null
    )
  ) then
    raise exception 'Uno o más productos no existen o están eliminados.'
      using errcode = 'P0001';
  end if;

  update public.branch_products
  set deleted_at = now()
  where branch_id = p_branch_id
    and deleted_at is null
    and not (
      product_id = any(coalesce(p_product_ids, array[]::uuid[]))
    );

  insert into public.branch_products (branch_id, product_id)
  select distinct p_branch_id, requested.product_id
  from unnest(coalesce(p_product_ids, array[]::uuid[]))
    as requested(product_id)
  where not exists (
    select 1
    from public.branch_products
    where branch_products.branch_id = p_branch_id
      and branch_products.product_id = requested.product_id
      and branch_products.deleted_at is null
  );
end;
$$;

create or replace function public.soft_delete_branch(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.branches
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'La sucursal no existe o ya fue eliminada.'
      using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.soft_delete_product(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.products
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'El producto no existe o ya fue eliminado.'
      using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.configure_branch_products(uuid, uuid[])
  from public;
revoke all on function public.configure_branch_products(uuid, uuid[])
  from anon;
grant execute on function public.configure_branch_products(uuid, uuid[])
  to authenticated;

revoke all on function public.soft_delete_branch(uuid) from public;
revoke all on function public.soft_delete_branch(uuid) from anon;
grant execute on function public.soft_delete_branch(uuid) to authenticated;

revoke all on function public.soft_delete_product(uuid) from public;
revoke all on function public.soft_delete_product(uuid) from anon;
grant execute on function public.soft_delete_product(uuid) to authenticated;

revoke all on function public.soft_delete_branch_links() from public;
revoke all on function public.soft_delete_product_links() from public;
