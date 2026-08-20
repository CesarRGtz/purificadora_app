create extension if not exists pgcrypto;

create table if not exists public.finished_goods (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  product_id uuid references public.products(id) on delete restrict,
  name text not null,
  asset_type text not null,
  status text not null,
  quantity bigint not null default 0,
  is_sellable boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint finished_goods_name_length
    check (char_length(btrim(name)) between 2 and 200),
  constraint finished_goods_asset_type_length
    check (char_length(btrim(asset_type)) between 2 and 100),
  constraint finished_goods_status_values
    check (status in ('purchased', 'sold', 'loaned', 'returned')),
  constraint finished_goods_quantity_range
    check (quantity >= 0)
);

create table if not exists public.raw_materials (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  category text not null,
  name text not null,
  unit text not null,
  last_unit_cost numeric(14, 4) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint raw_materials_category_length
    check (char_length(btrim(category)) between 2 and 100),
  constraint raw_materials_name_length
    check (char_length(btrim(name)) between 2 and 200),
  constraint raw_materials_unit_length
    check (char_length(btrim(unit)) between 1 and 50),
  constraint raw_materials_last_unit_cost_range
    check (
      last_unit_cost >= 0
      and last_unit_cost <> 'NaN'::numeric
      and last_unit_cost <> 'Infinity'::numeric
      and last_unit_cost <> '-Infinity'::numeric
    )
);

create table if not exists public.inventory_consumptions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  quantity numeric(14, 3) not null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint inventory_consumptions_quantity_range
    check (
      quantity > 0
      and quantity <> 'NaN'::numeric
      and quantity <> 'Infinity'::numeric
      and quantity <> '-Infinity'::numeric
    )
);

create table if not exists public.raw_material_movements (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null
    references public.raw_materials(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  type text not null,
  quantity numeric(14, 3) not null,
  unit_cost numeric(14, 4),
  product_id uuid references public.products(id) on delete restrict,
  consumption_id uuid
    references public.inventory_consumptions(id) on delete restrict,
  transfer_group_id uuid,
  note text not null default '',
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint raw_material_movements_type_values
    check (type in ('purchase', 'use', 'transfer_in', 'transfer_out')),
  constraint raw_material_movements_quantity_range
    check (
      quantity > 0
      and quantity <> 'NaN'::numeric
      and quantity <> 'Infinity'::numeric
      and quantity <> '-Infinity'::numeric
    ),
  constraint raw_material_movements_unit_cost_range
    check (
      unit_cost is null
      or (
        unit_cost >= 0
        and unit_cost <> 'NaN'::numeric
        and unit_cost <> 'Infinity'::numeric
        and unit_cost <> '-Infinity'::numeric
      )
    ),
  constraint raw_material_movements_unit_cost_type
    check (
      (type = 'use' and unit_cost is null)
      or
      (type in ('purchase', 'transfer_in', 'transfer_out')
        and unit_cost is not null)
    ),
  constraint raw_material_movements_note_length
    check (char_length(note) <= 500),
  constraint raw_material_movements_use_product
    check (
      (type = 'use' and product_id is not null)
      or
      (type <> 'use' and product_id is null)
    ),
  constraint raw_material_movements_consumption_type
    check (consumption_id is null or type = 'use'),
  constraint raw_material_movements_transfer_group
    check (
      (type in ('transfer_in', 'transfer_out') and transfer_group_id is not null)
      or
      (type not in ('transfer_in', 'transfer_out') and transfer_group_id is null)
    )
);

create table if not exists public.product_material_requirements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  raw_material_id uuid not null
    references public.raw_materials(id) on delete restrict,
  quantity_per_unit numeric(14, 3) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint product_material_requirements_quantity_range
    check (
      quantity_per_unit > 0
      and quantity_per_unit <> 'NaN'::numeric
      and quantity_per_unit <> 'Infinity'::numeric
      and quantity_per_unit <> '-Infinity'::numeric
    )
);

create index if not exists finished_goods_active_branch_idx
  on public.finished_goods (branch_id)
  where deleted_at is null;

create index if not exists finished_goods_active_product_idx
  on public.finished_goods (product_id)
  where deleted_at is null and product_id is not null;

create index if not exists finished_goods_active_status_idx
  on public.finished_goods (status)
  where deleted_at is null;

create index if not exists raw_materials_active_branch_name_idx
  on public.raw_materials (branch_id, lower(name))
  where deleted_at is null;

create unique index if not exists raw_materials_active_identity_uidx
  on public.raw_materials (
    branch_id,
    lower(btrim(name)),
    lower(btrim(unit))
  )
  where deleted_at is null;

create index if not exists raw_materials_active_category_idx
  on public.raw_materials (branch_id, lower(category))
  where deleted_at is null;

create index if not exists inventory_consumptions_active_branch_date_idx
  on public.inventory_consumptions (branch_id, occurred_at desc)
  where deleted_at is null;

create index if not exists inventory_consumptions_active_product_idx
  on public.inventory_consumptions (product_id)
  where deleted_at is null;

create index if not exists raw_material_movements_active_material_date_idx
  on public.raw_material_movements (raw_material_id, occurred_at desc)
  where deleted_at is null;

create index if not exists raw_material_movements_active_branch_date_idx
  on public.raw_material_movements (branch_id, occurred_at desc)
  where deleted_at is null;

create index if not exists raw_material_movements_active_product_idx
  on public.raw_material_movements (product_id)
  where deleted_at is null and product_id is not null;

create index if not exists raw_material_movements_active_consumption_idx
  on public.raw_material_movements (consumption_id)
  where deleted_at is null and consumption_id is not null;

create index if not exists raw_material_movements_active_transfer_idx
  on public.raw_material_movements (transfer_group_id)
  where deleted_at is null and transfer_group_id is not null;

create unique index if not exists raw_material_movements_transfer_pair_uidx
  on public.raw_material_movements (transfer_group_id, type)
  where transfer_group_id is not null;

create unique index if not exists
  product_material_requirements_active_unique_idx
  on public.product_material_requirements (product_id, raw_material_id)
  where deleted_at is null;

create index if not exists product_material_requirements_active_product_idx
  on public.product_material_requirements (product_id)
  where deleted_at is null;

create index if not exists product_material_requirements_active_material_idx
  on public.product_material_requirements (raw_material_id)
  where deleted_at is null;

create or replace function public.set_inventory_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.guard_raw_material_branch_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.branch_id <> old.branch_id and (
    exists (
      select 1
      from public.raw_material_movements
      where raw_material_movements.raw_material_id = old.id
        and raw_material_movements.deleted_at is null
    )
    or exists (
      select 1
      from public.product_material_requirements
      where product_material_requirements.raw_material_id = old.id
        and product_material_requirements.deleted_at is null
    )
  ) then
    raise exception
      'No se puede cambiar la sucursal de una materia prima con historial o recetas.'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists finished_goods_set_updated_at
  on public.finished_goods;
create trigger finished_goods_set_updated_at
before update on public.finished_goods
for each row execute function public.set_inventory_updated_at();

drop trigger if exists raw_materials_set_updated_at
  on public.raw_materials;
create trigger raw_materials_set_updated_at
before update on public.raw_materials
for each row execute function public.set_inventory_updated_at();

drop trigger if exists raw_materials_guard_branch_change
  on public.raw_materials;
create trigger raw_materials_guard_branch_change
before update of branch_id on public.raw_materials
for each row execute function public.guard_raw_material_branch_change();

drop trigger if exists inventory_consumptions_set_updated_at
  on public.inventory_consumptions;
create trigger inventory_consumptions_set_updated_at
before update on public.inventory_consumptions
for each row execute function public.set_inventory_updated_at();

drop trigger if exists raw_material_movements_set_updated_at
  on public.raw_material_movements;
create trigger raw_material_movements_set_updated_at
before update on public.raw_material_movements
for each row execute function public.set_inventory_updated_at();

drop trigger if exists product_material_requirements_set_updated_at
  on public.product_material_requirements;
create trigger product_material_requirements_set_updated_at
before update on public.product_material_requirements
for each row execute function public.set_inventory_updated_at();

alter table public.finished_goods enable row level security;
alter table public.raw_materials enable row level security;
alter table public.inventory_consumptions enable row level security;
alter table public.raw_material_movements enable row level security;
alter table public.product_material_requirements enable row level security;

revoke all on table public.finished_goods from anon;
revoke all on table public.raw_materials from anon;
revoke all on table public.inventory_consumptions from anon;
revoke all on table public.raw_material_movements from anon;
revoke all on table public.product_material_requirements from anon;
revoke all on table public.finished_goods from authenticated;
revoke all on table public.raw_materials from authenticated;
revoke all on table public.inventory_consumptions from authenticated;
revoke all on table public.raw_material_movements from authenticated;
revoke all on table public.product_material_requirements from authenticated;
revoke insert, update on table public.branch_products from authenticated;

grant select, insert, update on table public.finished_goods
  to authenticated;
grant select, insert, update on table public.raw_materials
  to authenticated;
-- El ledger y las recetas sólo se escriben mediante RPC validadas. Esto evita
-- omitir bloqueos, crear salidas sin existencia o alterar el historial.
grant select on table public.inventory_consumptions to authenticated;
grant select on table public.raw_material_movements to authenticated;
grant select on table public.product_material_requirements to authenticated;

create policy "Authenticated users can read finished goods"
on public.finished_goods for select
to authenticated
using (
  deleted_at is null
  and exists (
    select 1
    from public.branches
    where branches.id = finished_goods.branch_id
      and branches.deleted_at is null
  )
  and (
    product_id is null
    or exists (
      select 1
      from public.products
      where products.id = finished_goods.product_id
        and products.deleted_at is null
    )
  )
);

create policy "Authenticated users can create finished goods"
on public.finished_goods for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1
    from public.branches
    where branches.id = finished_goods.branch_id
      and branches.deleted_at is null
  )
  and (
    product_id is null
    or (
      exists (
        select 1
        from public.products
        where products.id = finished_goods.product_id
          and products.deleted_at is null
      )
      and exists (
        select 1
        from public.branch_products
        where branch_products.branch_id = finished_goods.branch_id
          and branch_products.product_id = finished_goods.product_id
          and branch_products.deleted_at is null
      )
    )
  )
);

create policy "Authenticated users can update finished goods"
on public.finished_goods for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or (
    exists (
      select 1
      from public.branches
      where branches.id = finished_goods.branch_id
        and branches.deleted_at is null
    )
    and (
      product_id is null
      or (
        exists (
          select 1
          from public.products
          where products.id = finished_goods.product_id
            and products.deleted_at is null
        )
        and exists (
          select 1
          from public.branch_products
          where branch_products.branch_id = finished_goods.branch_id
            and branch_products.product_id = finished_goods.product_id
            and branch_products.deleted_at is null
        )
      )
    )
  )
);

create policy "Authenticated users can read raw materials"
on public.raw_materials for select
to authenticated
using (
  deleted_at is null
  and exists (
    select 1
    from public.branches
    where branches.id = raw_materials.branch_id
      and branches.deleted_at is null
  )
);

create policy "Authenticated users can create raw materials"
on public.raw_materials for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1
    from public.branches
    where branches.id = raw_materials.branch_id
      and branches.deleted_at is null
  )
);

create policy "Authenticated users can update raw materials"
on public.raw_materials for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or exists (
    select 1
    from public.branches
    where branches.id = raw_materials.branch_id
      and branches.deleted_at is null
  )
);

create policy "Authenticated users can read inventory consumptions"
on public.inventory_consumptions for select
to authenticated
using (deleted_at is null);

create policy "Authenticated users can create inventory consumptions"
on public.inventory_consumptions for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1
    from public.branches
    where branches.id = inventory_consumptions.branch_id
      and branches.deleted_at is null
  )
  and exists (
    select 1
    from public.products
    where products.id = inventory_consumptions.product_id
      and products.deleted_at is null
  )
  and exists (
    select 1
    from public.branch_products
    where branch_products.branch_id = inventory_consumptions.branch_id
      and branch_products.product_id = inventory_consumptions.product_id
      and branch_products.deleted_at is null
  )
);

create policy "Authenticated users can update inventory consumptions"
on public.inventory_consumptions for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or (
    exists (
      select 1
      from public.branches
      where branches.id = inventory_consumptions.branch_id
        and branches.deleted_at is null
    )
    and exists (
      select 1
      from public.products
      where products.id = inventory_consumptions.product_id
        and products.deleted_at is null
    )
    and exists (
      select 1
      from public.branch_products
      where branch_products.branch_id = inventory_consumptions.branch_id
        and branch_products.product_id = inventory_consumptions.product_id
        and branch_products.deleted_at is null
    )
  )
);

create policy "Authenticated users can read raw material movements"
on public.raw_material_movements for select
to authenticated
using (
  deleted_at is null
  and exists (
    select 1
    from public.raw_materials
    where raw_materials.id = raw_material_movements.raw_material_id
      and raw_materials.branch_id = raw_material_movements.branch_id
      and raw_materials.deleted_at is null
  )
  and exists (
    select 1
    from public.branches
    where branches.id = raw_material_movements.branch_id
      and branches.deleted_at is null
  )
  and (
    consumption_id is null
    or exists (
      select 1
      from public.inventory_consumptions
      where inventory_consumptions.id =
        raw_material_movements.consumption_id
        and inventory_consumptions.branch_id =
          raw_material_movements.branch_id
        and inventory_consumptions.product_id =
          raw_material_movements.product_id
      and inventory_consumptions.deleted_at is null
    )
  )
);

create policy "Authenticated users can create raw material movements"
on public.raw_material_movements for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1
    from public.raw_materials
    where raw_materials.id = raw_material_movements.raw_material_id
      and raw_materials.branch_id = raw_material_movements.branch_id
      and raw_materials.deleted_at is null
  )
  and exists (
    select 1
    from public.branches
    where branches.id = raw_material_movements.branch_id
      and branches.deleted_at is null
  )
  and (
    product_id is null
    or (
      exists (
        select 1
        from public.products
        where products.id = raw_material_movements.product_id
          and products.deleted_at is null
      )
      and exists (
        select 1
        from public.branch_products
        where branch_products.branch_id =
            raw_material_movements.branch_id
          and branch_products.product_id =
            raw_material_movements.product_id
          and branch_products.deleted_at is null
      )
    )
  )
  and (
    consumption_id is null
    or exists (
      select 1
      from public.inventory_consumptions
      where inventory_consumptions.id =
        raw_material_movements.consumption_id
        and inventory_consumptions.branch_id =
          raw_material_movements.branch_id
        and inventory_consumptions.product_id =
          raw_material_movements.product_id
        and inventory_consumptions.deleted_at is null
    )
  )
  and (
    type <> 'use'
    or exists (
      select 1
      from public.product_material_requirements
      where product_material_requirements.product_id =
          raw_material_movements.product_id
        and product_material_requirements.raw_material_id =
          raw_material_movements.raw_material_id
        and product_material_requirements.deleted_at is null
    )
  )
);

create policy "Authenticated users can update raw material movements"
on public.raw_material_movements for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or (
    exists (
      select 1
      from public.raw_materials
      where raw_materials.id = raw_material_movements.raw_material_id
        and raw_materials.branch_id = raw_material_movements.branch_id
        and raw_materials.deleted_at is null
    )
    and exists (
      select 1
      from public.branches
      where branches.id = raw_material_movements.branch_id
        and branches.deleted_at is null
    )
    and (
      product_id is null
      or (
        exists (
          select 1
          from public.products
          where products.id = raw_material_movements.product_id
            and products.deleted_at is null
        )
        and exists (
          select 1
          from public.branch_products
          where branch_products.branch_id =
              raw_material_movements.branch_id
            and branch_products.product_id =
              raw_material_movements.product_id
            and branch_products.deleted_at is null
        )
      )
    )
    and (
      consumption_id is null
      or exists (
        select 1
        from public.inventory_consumptions
        where inventory_consumptions.id =
          raw_material_movements.consumption_id
          and inventory_consumptions.branch_id =
            raw_material_movements.branch_id
          and inventory_consumptions.product_id =
            raw_material_movements.product_id
          and inventory_consumptions.deleted_at is null
      )
    )
    and (
      type <> 'use'
      or exists (
        select 1
        from public.product_material_requirements
        where product_material_requirements.product_id =
            raw_material_movements.product_id
          and product_material_requirements.raw_material_id =
            raw_material_movements.raw_material_id
          and product_material_requirements.deleted_at is null
      )
    )
  )
);

create policy "Authenticated users can read product material requirements"
on public.product_material_requirements for select
to authenticated
using (
  deleted_at is null
  and exists (
    select 1
    from public.products
    where products.id = product_material_requirements.product_id
      and products.deleted_at is null
  )
  and exists (
    select 1
    from public.raw_materials
    where raw_materials.id =
      product_material_requirements.raw_material_id
      and raw_materials.deleted_at is null
  )
);

create policy "Authenticated users can create product material requirements"
on public.product_material_requirements for insert
to authenticated
with check (
  deleted_at is null
  and exists (
    select 1
    from public.products
    where products.id = product_material_requirements.product_id
      and products.deleted_at is null
  )
  and exists (
    select 1
    from public.raw_materials
    where raw_materials.id =
      product_material_requirements.raw_material_id
      and raw_materials.deleted_at is null
  )
  and exists (
    select 1
    from public.raw_materials
    join public.branch_products
      on branch_products.branch_id = raw_materials.branch_id
    where raw_materials.id =
        product_material_requirements.raw_material_id
      and raw_materials.deleted_at is null
      and branch_products.product_id =
        product_material_requirements.product_id
      and branch_products.deleted_at is null
  )
);

create policy "Authenticated users can update product material requirements"
on public.product_material_requirements for update
to authenticated
using (deleted_at is null)
with check (
  deleted_at is not null
  or (
    exists (
      select 1
      from public.products
      where products.id = product_material_requirements.product_id
        and products.deleted_at is null
    )
    and exists (
      select 1
      from public.raw_materials
      where raw_materials.id =
        product_material_requirements.raw_material_id
        and raw_materials.deleted_at is null
    )
    and exists (
      select 1
      from public.raw_materials
      join public.branch_products
        on branch_products.branch_id = raw_materials.branch_id
      where raw_materials.id =
          product_material_requirements.raw_material_id
        and raw_materials.deleted_at is null
        and branch_products.product_id =
          product_material_requirements.product_id
        and branch_products.deleted_at is null
    )
  )
);

create or replace function public.soft_delete_branch_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.finished_goods
  set deleted_at = new.deleted_at
  where branch_id = new.id
    and deleted_at is null;

  update public.raw_materials
  set deleted_at = new.deleted_at
  where branch_id = new.id
    and deleted_at is null;

  return new;
end;
$$;

create or replace function public.soft_delete_product_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.finished_goods
  set product_id = null,
      updated_at = now()
  where product_id = new.id
    and deleted_at is null;

  update public.product_material_requirements
  set deleted_at = new.deleted_at
  where product_id = new.id
    and deleted_at is null;

  return new;
end;
$$;

create or replace function public.soft_delete_raw_material_dependents()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.product_material_requirements
  set deleted_at = new.deleted_at
  where raw_material_id = new.id
    and deleted_at is null;

  return new;
end;
$$;

create or replace function public.soft_delete_consumption_movements()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.raw_material_movements
  set deleted_at = new.deleted_at
  where consumption_id = new.id
    and deleted_at is null;

  return new;
end;
$$;

drop trigger if exists branches_soft_delete_inventory
  on public.branches;
create trigger branches_soft_delete_inventory
after update of deleted_at on public.branches
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_branch_inventory();

drop trigger if exists products_soft_delete_inventory
  on public.products;
create trigger products_soft_delete_inventory
after update of deleted_at on public.products
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_product_inventory();

drop trigger if exists raw_materials_soft_delete_dependents
  on public.raw_materials;
create trigger raw_materials_soft_delete_dependents
after update of deleted_at on public.raw_materials
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_raw_material_dependents();

drop trigger if exists inventory_consumptions_soft_delete_movements
  on public.inventory_consumptions;
create trigger inventory_consumptions_soft_delete_movements
after update of deleted_at on public.inventory_consumptions
for each row
when (old.deleted_at is null and new.deleted_at is not null)
execute function public.soft_delete_consumption_movements();

create or replace view public.raw_material_inventory
with (security_invoker = true)
as
select
  raw_materials.id,
  raw_materials.branch_id,
  raw_materials.category,
  raw_materials.name,
  raw_materials.unit,
  raw_materials.last_unit_cost,
  raw_materials.created_at,
  raw_materials.updated_at,
  balances.purchase_quantity,
  balances.used_quantity,
  balances.transfer_in_quantity,
  balances.transfer_out_quantity,
  balances.stock_quantity,
  balances.stock_quantity * raw_materials.last_unit_cost as total_value
from public.raw_materials
cross join lateral (
  select
    coalesce(sum(raw_material_movements.quantity) filter (
      where raw_material_movements.type = 'purchase'
    ), 0::numeric) as purchase_quantity,
    coalesce(sum(raw_material_movements.quantity) filter (
      where raw_material_movements.type = 'use'
    ), 0::numeric) as used_quantity,
    coalesce(sum(raw_material_movements.quantity) filter (
      where raw_material_movements.type = 'transfer_in'
    ), 0::numeric) as transfer_in_quantity,
    coalesce(sum(raw_material_movements.quantity) filter (
      where raw_material_movements.type = 'transfer_out'
    ), 0::numeric) as transfer_out_quantity,
    coalesce(sum(
      case raw_material_movements.type
        when 'purchase' then raw_material_movements.quantity
        when 'transfer_in' then raw_material_movements.quantity
        when 'use' then -raw_material_movements.quantity
        when 'transfer_out' then -raw_material_movements.quantity
      end
    ), 0::numeric) as stock_quantity
  from public.raw_material_movements
  where raw_material_movements.raw_material_id = raw_materials.id
    and raw_material_movements.branch_id = raw_materials.branch_id
    and raw_material_movements.deleted_at is null
) as balances
where raw_materials.deleted_at is null;

revoke all on table public.raw_material_inventory from public;
revoke all on table public.raw_material_inventory from anon;
revoke all on table public.raw_material_inventory from authenticated;
grant select on table public.raw_material_inventory to authenticated;

create or replace function public.configure_product_materials(
  p_product_id uuid,
  p_materials jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_materials jsonb := coalesce(p_materials, '{}'::jsonb);
  v_affected_material_ids uuid[] := array[]::uuid[];
  v_discovered_branch_ids uuid[] := array[]::uuid[];
  v_locked_branch_ids uuid[] := array[]::uuid[];
  v_locked_material_ids uuid[] := array[]::uuid[];
  v_branch_id uuid;
  v_material_id uuid;
begin
  if jsonb_typeof(v_materials) <> 'object' then
    raise exception
      'La configuración de materias primas debe ser un objeto JSON.'
      using errcode = 'P0001';
  end if;

  perform 1
  from public.products
  where id = p_product_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'El producto no existe o está eliminado.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from jsonb_each_text(v_materials) as requested(material_id, quantity)
    where requested.material_id !~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  ) then
    raise exception 'Una materia prima tiene un identificador inválido.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from jsonb_each_text(v_materials) as requested(material_id, quantity)
    where requested.quantity is null
      or requested.quantity !~ '^[+]?[0-9]+([.][0-9]+)?$'
      or requested.quantity::numeric <= 0
      or requested.quantity::numeric > 99999999999.999
      or requested.quantity::numeric <>
        trunc(requested.quantity::numeric, 3)
  ) then
    raise exception
      'La cantidad requerida por producto debe ser mayor que cero.'
      using errcode = 'P0001';
  end if;

  select coalesce(
    array_agg(
      distinct affected.material_id
      order by affected.material_id
    ),
    array[]::uuid[]
  )
  into v_affected_material_ids
  from (
    select requested.material_id::uuid as material_id
    from jsonb_each_text(v_materials)
      as requested(material_id, quantity)
    union
    select product_material_requirements.raw_material_id
    from public.product_material_requirements
    where product_material_requirements.product_id = p_product_id
      and product_material_requirements.deleted_at is null
  ) as affected;

  select coalesce(
    array_agg(
      distinct raw_materials.branch_id
      order by raw_materials.branch_id
    ),
    array[]::uuid[]
  )
  into v_discovered_branch_ids
  from public.raw_materials
  where raw_materials.id = any(v_affected_material_ids);

  for v_branch_id in
    select branches.id
    from public.branches
    where branches.id = any(v_discovered_branch_ids)
    order by branches.id
    for update
  loop
    v_locked_branch_ids := array_append(
      v_locked_branch_ids,
      v_branch_id
    );
  end loop;

  for v_material_id in
    select raw_materials.id
    from public.raw_materials
    where raw_materials.id = any(v_affected_material_ids)
    order by raw_materials.id
    for update
  loop
    v_locked_material_ids := array_append(
      v_locked_material_ids,
      v_material_id
    );
  end loop;

  if exists (
    select 1
    from jsonb_each_text(v_materials) as requested(material_id, quantity)
    where not (requested.material_id::uuid = any(v_locked_material_ids))
      or not exists (
        select 1
        from public.raw_materials
        where raw_materials.id = requested.material_id::uuid
          and raw_materials.deleted_at is null
      )
  ) then
    raise exception
      'Una o más materias primas no existen o están eliminadas.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from public.raw_materials
    where raw_materials.id = any(v_affected_material_ids)
      and raw_materials.deleted_at is null
      and not (raw_materials.branch_id = any(v_locked_branch_ids))
  ) then
    raise exception
      'La sucursal de una materia prima cambió durante la operación. Intenta nuevamente.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from jsonb_each_text(v_materials) as requested(material_id, quantity)
    join public.raw_materials
      on raw_materials.id = requested.material_id::uuid
    where not exists (
      select 1
      from public.branches
      where branches.id = raw_materials.branch_id
        and branches.deleted_at is null
    )
      or not exists (
        select 1
        from public.branch_products
        where branch_products.product_id = p_product_id
          and branch_products.branch_id = raw_materials.branch_id
          and branch_products.deleted_at is null
      )
  ) then
    raise exception
      'Cada materia prima debe pertenecer a una sucursal activa del producto.'
      using errcode = 'P0001';
  end if;

  update public.product_material_requirements
  set deleted_at = now()
  where product_id = p_product_id
    and deleted_at is null
    and not exists (
      select 1
      from jsonb_each_text(v_materials)
        as requested(material_id, quantity)
      where requested.material_id::uuid =
        product_material_requirements.raw_material_id
    );

  insert into public.product_material_requirements (
    product_id,
    raw_material_id,
    quantity_per_unit
  )
  select
    p_product_id,
    requested.material_id::uuid,
    requested.quantity::numeric
  from jsonb_each_text(v_materials) as requested(material_id, quantity)
  on conflict (product_id, raw_material_id)
    where deleted_at is null
  do update
  set quantity_per_unit = excluded.quantity_per_unit,
      updated_at = now();
end;
$$;

create or replace function public.configure_product_branches(
  p_product_id uuid,
  p_branch_ids uuid[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1
  from public.products
  where id = p_product_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'El producto no existe o está eliminado.'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1
    from unnest(coalesce(p_branch_ids, array[]::uuid[]))
      as requested(branch_id)
    where requested.branch_id is null
      or not exists (
        select 1
        from public.branches
        where branches.id = requested.branch_id
          and branches.deleted_at is null
      )
  ) then
    raise exception 'Una o más sucursales no existen o están eliminadas.'
      using errcode = 'P0001';
  end if;

  perform branches.id
  from public.branches
  join (
    select distinct requested.branch_id
    from unnest(coalesce(p_branch_ids, array[]::uuid[]))
      as requested(branch_id)
  ) as requested on requested.branch_id = branches.id
  order by branches.id
  for update of branches;

  update public.branch_products
  set deleted_at = now()
  where product_id = p_product_id
    and deleted_at is null
    and not (
      branch_id = any(coalesce(p_branch_ids, array[]::uuid[]))
    );

  update public.product_material_requirements
  set deleted_at = now()
  where product_id = p_product_id
    and deleted_at is null
    and exists (
      select 1
      from public.raw_materials
      where raw_materials.id =
          product_material_requirements.raw_material_id
        and raw_materials.deleted_at is null
        and not (
          raw_materials.branch_id = any(
            coalesce(p_branch_ids, array[]::uuid[])
          )
        )
    );

  update public.finished_goods
  set product_id = null,
      updated_at = now()
  where product_id = p_product_id
    and deleted_at is null
    and not (
      branch_id = any(coalesce(p_branch_ids, array[]::uuid[]))
    );

  insert into public.branch_products (branch_id, product_id)
  select distinct requested.branch_id, p_product_id
  from unnest(coalesce(p_branch_ids, array[]::uuid[]))
    as requested(branch_id)
  where not exists (
    select 1
    from public.branch_products
    where branch_products.branch_id = requested.branch_id
      and branch_products.product_id = p_product_id
      and branch_products.deleted_at is null
  );
end;
$$;

-- Mantiene sincronizado el flujo existente de Sucursales con las recetas de
-- Inventario y usa el mismo orden de bloqueos: productos -> sucursal.
create or replace function public.configure_branch_products(
  p_branch_id uuid,
  p_product_ids uuid[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_locked_product_ids uuid[] := array[]::uuid[];
  v_product_id uuid;
begin
  for v_product_id in
    select products.id
    from public.products
    join (
      select distinct requested.product_id
      from unnest(coalesce(p_product_ids, array[]::uuid[]))
        as requested(product_id)
      where requested.product_id is not null
      union
      select branch_products.product_id
      from public.branch_products
      where branch_products.branch_id = p_branch_id
        and branch_products.deleted_at is null
    ) as affected on affected.product_id = products.id
    order by products.id
    for update of products
  loop
    v_locked_product_ids := array_append(
      v_locked_product_ids,
      v_product_id
    );
  end loop;

  if exists (
    select 1
    from unnest(coalesce(p_product_ids, array[]::uuid[]))
      as requested(product_id)
    where requested.product_id is null
      or not (requested.product_id = any(v_locked_product_ids))
      or not exists (
        select 1
        from public.products
        where products.id = requested.product_id
          and products.deleted_at is null
      )
  ) then
    raise exception 'Uno o más productos no existen o están eliminados.'
      using errcode = 'P0001';
  end if;

  perform 1
  from public.branches
  where id = p_branch_id
  for update;

  if not found then
    raise exception 'La sucursal no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.branches
    where branches.id = p_branch_id
      and branches.deleted_at is null
  ) then
    raise exception 'La sucursal no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  perform raw_materials.id
  from public.raw_materials
  where raw_materials.branch_id = p_branch_id
    and raw_materials.deleted_at is null
  order by raw_materials.id
  for update;

  update public.branch_products
  set deleted_at = now()
  where branch_id = p_branch_id
    and deleted_at is null
    and not (
      product_id = any(coalesce(p_product_ids, array[]::uuid[]))
    );

  update public.product_material_requirements
  set deleted_at = now()
  where deleted_at is null
    and not (
      product_id = any(coalesce(p_product_ids, array[]::uuid[]))
    )
    and exists (
      select 1
      from public.raw_materials
      where raw_materials.id =
          product_material_requirements.raw_material_id
        and raw_materials.branch_id = p_branch_id
        and raw_materials.deleted_at is null
    );

  update public.finished_goods
  set product_id = null,
      updated_at = now()
  where branch_id = p_branch_id
    and deleted_at is null
    and product_id is not null
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

create or replace function public.register_raw_material_movement(
  p_raw_material_id uuid,
  p_branch_id uuid,
  p_type text,
  p_quantity numeric,
  p_operation_id uuid,
  p_unit_cost numeric default null,
  p_product_id uuid default null,
  p_note text default '',
  p_occurred_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_type text := lower(btrim(coalesce(p_type, '')));
  v_current_stock numeric;
  v_occurred_at timestamptz := coalesce(p_occurred_at, now());
begin
  if p_operation_id is null then
    raise exception 'La operación debe incluir un identificador único.'
      using errcode = 'P0001';
  end if;

  select id into v_id
  from public.raw_material_movements
  where id = p_operation_id;

  if found then
    return v_id;
  end if;

  if v_type not in ('purchase', 'use', 'transfer_in', 'transfer_out') then
    raise exception 'El tipo de movimiento no es válido.'
      using errcode = 'P0001';
  end if;

  if v_type in ('transfer_in', 'transfer_out') then
    raise exception
      'Los traslados deben registrarse con la operación entre sucursales.'
      using errcode = 'P0001';
  end if;

  if p_quantity is null
    or p_quantity <= 0
    or p_quantity > 99999999999.999
    or p_quantity <> trunc(p_quantity, 3)
    or p_quantity = 'NaN'::numeric
    or p_quantity = 'Infinity'::numeric
    or p_quantity = '-Infinity'::numeric then
    raise exception 'La cantidad del movimiento debe ser mayor que cero.'
      using errcode = 'P0001';
  end if;

  if v_type = 'purchase' and p_unit_cost is null then
    raise exception 'Las compras deben indicar el costo unitario.'
      using errcode = 'P0001';
  end if;

  if v_type <> 'purchase' and p_unit_cost is not null then
    raise exception 'El costo unitario sólo se captura en las compras.'
      using errcode = 'P0001';
  end if;

  if v_type <> 'use' and p_product_id is not null then
    raise exception 'Sólo los usos pueden asociarse a un producto.'
      using errcode = 'P0001';
  end if;

  if p_unit_cost is not null and (
      p_unit_cost < 0
      or p_unit_cost > 9999999999.9999
      or p_unit_cost <> trunc(p_unit_cost, 4)
      or p_unit_cost = 'NaN'::numeric
      or p_unit_cost = 'Infinity'::numeric
      or p_unit_cost = '-Infinity'::numeric
    ) then
    raise exception 'El costo unitario no es válido.'
      using errcode = 'P0001';
  end if;

  if char_length(coalesce(p_note, '')) > 500 then
    raise exception 'La nota no puede exceder 500 caracteres.'
      using errcode = 'P0001';
  end if;

  if p_product_id is not null then
    perform 1
    from public.products
    where id = p_product_id
      and deleted_at is null
    for update;

    if not found then
      raise exception 'El producto no existe o está eliminado.'
        using errcode = 'P0001';
    end if;
  end if;

  perform 1
  from public.branches
  where id = p_branch_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'La sucursal no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  perform 1
  from public.raw_materials
  where id = p_raw_material_id
    and branch_id = p_branch_id
    and deleted_at is null
  for update;

  if not found then
    raise exception
      'La materia prima no existe, está eliminada o pertenece a otra sucursal.'
      using errcode = 'P0001';
  end if;

  select id into v_id
  from public.raw_material_movements
  where id = p_operation_id;

  if found then
    return v_id;
  end if;

  if v_type = 'use' and p_product_id is null then
    raise exception 'Los consumos deben indicar un producto.'
      using errcode = 'P0001';
  end if;

  if p_product_id is not null and not exists (
    select 1
    from public.branch_products
    where branch_products.product_id = p_product_id
      and branch_products.branch_id = p_branch_id
      and branch_products.deleted_at is null
  ) then
    raise exception 'El producto no está activo en la sucursal.'
      using errcode = 'P0001';
  end if;

  if v_type = 'use' and not exists (
    select 1
    from public.product_material_requirements
    where product_material_requirements.product_id = p_product_id
      and product_material_requirements.raw_material_id = p_raw_material_id
      and product_material_requirements.deleted_at is null
  ) then
    raise exception 'La materia prima no forma parte de la receta.'
      using errcode = 'P0001';
  end if;

  if v_type in ('use', 'transfer_out') then
    select coalesce(sum(
      case raw_material_movements.type
        when 'purchase' then raw_material_movements.quantity
        when 'transfer_in' then raw_material_movements.quantity
        when 'use' then -raw_material_movements.quantity
        when 'transfer_out' then -raw_material_movements.quantity
      end
    ), 0::numeric)
    into v_current_stock
    from public.raw_material_movements
    where raw_material_movements.raw_material_id = p_raw_material_id
      and raw_material_movements.branch_id = p_branch_id
      and raw_material_movements.deleted_at is null;

    if v_current_stock < p_quantity then
      raise exception
        'No hay existencia suficiente para registrar la salida.'
        using errcode = 'P0001';
    end if;
  end if;

  insert into public.raw_material_movements (
    id,
    raw_material_id,
    branch_id,
    type,
    quantity,
    unit_cost,
    product_id,
    note,
    occurred_at
  ) values (
    p_operation_id,
    p_raw_material_id,
    p_branch_id,
    v_type,
    p_quantity,
    p_unit_cost,
    p_product_id,
    btrim(coalesce(p_note, '')),
    v_occurred_at
  )
  returning id into v_id;

  if v_type = 'purchase'
    and p_unit_cost is not null
    and not exists (
      select 1
      from public.raw_material_movements
      where raw_material_movements.raw_material_id = p_raw_material_id
        and raw_material_movements.branch_id = p_branch_id
        and raw_material_movements.type in ('purchase', 'transfer_in')
        and raw_material_movements.deleted_at is null
        and raw_material_movements.occurred_at > v_occurred_at
    ) then
    update public.raw_materials
    set last_unit_cost = p_unit_cost
    where id = p_raw_material_id
      and deleted_at is null;
  end if;

  return v_id;
end;
$$;

create or replace function public.transfer_raw_material(
  p_source_raw_material_id uuid,
  p_destination_raw_material_id uuid,
  p_quantity numeric,
  p_operation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transfer_group_id uuid;
  v_source_branch_id uuid;
  v_destination_branch_id uuid;
  v_source_name text;
  v_destination_name text;
  v_source_unit text;
  v_destination_unit text;
  v_source_unit_cost numeric;
  v_current_stock numeric;
  v_occurred_at timestamptz := now();
begin
  if p_operation_id is null then
    raise exception 'La operación debe incluir un identificador único.'
      using errcode = 'P0001';
  end if;
  v_transfer_group_id := p_operation_id;

  if exists (
    select 1
    from public.raw_material_movements
    where transfer_group_id = v_transfer_group_id
  ) then
    return v_transfer_group_id;
  end if;

  if p_quantity is null
    or p_quantity <= 0
    or p_quantity > 99999999999.999
    or p_quantity <> trunc(p_quantity, 3)
    or p_quantity = 'NaN'::numeric
    or p_quantity = 'Infinity'::numeric
    or p_quantity = '-Infinity'::numeric then
    raise exception 'La cantidad del traslado debe ser mayor que cero.'
      using errcode = 'P0001';
  end if;

  if p_source_raw_material_id = p_destination_raw_material_id then
    raise exception
      'La materia prima de origen y destino deben ser diferentes.'
      using errcode = 'P0001';
  end if;

  perform raw_materials.id
  from public.raw_materials
  where raw_materials.id in (
      p_source_raw_material_id,
      p_destination_raw_material_id
    )
    and raw_materials.deleted_at is null
  order by raw_materials.id
  for update;

  if exists (
    select 1
    from public.raw_material_movements
    where transfer_group_id = v_transfer_group_id
  ) then
    return v_transfer_group_id;
  end if;

  select branch_id, name, unit, last_unit_cost
  into
    v_source_branch_id,
    v_source_name,
    v_source_unit,
    v_source_unit_cost
  from public.raw_materials
  where id = p_source_raw_material_id
    and deleted_at is null;

  if not found then
    raise exception 'La materia prima de origen no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  select branch_id, name, unit
  into v_destination_branch_id, v_destination_name, v_destination_unit
  from public.raw_materials
  where id = p_destination_raw_material_id
    and deleted_at is null;

  if not found then
    raise exception 'La materia prima de destino no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  if v_source_branch_id = v_destination_branch_id then
    raise exception 'El traslado debe ser entre sucursales diferentes.'
      using errcode = 'P0001';
  end if;

  if lower(btrim(v_source_name)) <> lower(btrim(v_destination_name))
    or lower(btrim(v_source_unit)) <> lower(btrim(v_destination_unit)) then
    raise exception
      'El insumo de destino debe tener el mismo nombre y unidad.'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.branches
    where branches.id = v_source_branch_id
      and branches.deleted_at is null
  ) or not exists (
    select 1
    from public.branches
    where branches.id = v_destination_branch_id
      and branches.deleted_at is null
  ) then
    raise exception 'La sucursal de origen o destino ya no está disponible.'
      using errcode = 'P0001';
  end if;

  select coalesce(sum(
    case raw_material_movements.type
      when 'purchase' then raw_material_movements.quantity
      when 'transfer_in' then raw_material_movements.quantity
      when 'use' then -raw_material_movements.quantity
      when 'transfer_out' then -raw_material_movements.quantity
    end
  ), 0::numeric)
  into v_current_stock
  from public.raw_material_movements
  where raw_material_movements.raw_material_id = p_source_raw_material_id
    and raw_material_movements.branch_id = v_source_branch_id
    and raw_material_movements.deleted_at is null;

  if v_current_stock < p_quantity then
    raise exception 'No hay existencia suficiente para el traslado.'
      using errcode = 'P0001';
  end if;

  insert into public.raw_material_movements (
    raw_material_id,
    branch_id,
    type,
    quantity,
    unit_cost,
    transfer_group_id,
    note,
    occurred_at
  ) values
  (
    p_source_raw_material_id,
    v_source_branch_id,
    'transfer_out',
    p_quantity,
    v_source_unit_cost,
    v_transfer_group_id,
    'Traslado #' || v_transfer_group_id::text,
    v_occurred_at
  ),
  (
    p_destination_raw_material_id,
    v_destination_branch_id,
    'transfer_in',
    p_quantity,
    v_source_unit_cost,
    v_transfer_group_id,
    'Traslado #' || v_transfer_group_id::text,
    v_occurred_at
  );

  update public.raw_materials
  set last_unit_cost = v_source_unit_cost,
      updated_at = now()
  where id = p_destination_raw_material_id
    and deleted_at is null;

  return v_transfer_group_id;
end;
$$;

create or replace function public.consume_product_materials(
  p_product_id uuid,
  p_branch_id uuid,
  p_quantity numeric,
  p_operation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_consumption_id uuid;
  v_current_stock numeric;
  v_required_quantity numeric;
  v_has_requirements boolean := false;
  v_occurred_at timestamptz := now();
  v_requirement record;
begin
  if p_operation_id is null then
    raise exception 'La operación debe incluir un identificador único.'
      using errcode = 'P0001';
  end if;

  select id into v_consumption_id
  from public.inventory_consumptions
  where id = p_operation_id;

  if found then
    return v_consumption_id;
  end if;

  if p_quantity is null
    or p_quantity <= 0
    or p_quantity > 99999999999
    or p_quantity <> trunc(p_quantity)
    or p_quantity = 'NaN'::numeric
    or p_quantity = 'Infinity'::numeric
    or p_quantity = '-Infinity'::numeric then
    raise exception 'La cantidad de producto debe ser mayor que cero.'
      using errcode = 'P0001';
  end if;

  perform 1
  from public.products
  where id = p_product_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'El producto no existe o está eliminado.'
      using errcode = 'P0001';
  end if;

  select id into v_consumption_id
  from public.inventory_consumptions
  where id = p_operation_id;

  if found then
    return v_consumption_id;
  end if;

  perform 1
  from public.branches
  where id = p_branch_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'La sucursal no existe o está eliminada.'
      using errcode = 'P0001';
  end if;

  perform 1
  from public.branch_products
  where product_id = p_product_id
    and branch_id = p_branch_id
    and deleted_at is null
  for update;

  if not found then
    raise exception 'El producto no está activo en la sucursal.'
      using errcode = 'P0001';
  end if;

  for v_requirement in
    select
      product_material_requirements.raw_material_id,
      product_material_requirements.quantity_per_unit,
      raw_materials.name as raw_material_name
    from public.product_material_requirements
    join public.raw_materials
      on raw_materials.id =
        product_material_requirements.raw_material_id
    where product_material_requirements.product_id = p_product_id
      and product_material_requirements.deleted_at is null
      and raw_materials.branch_id = p_branch_id
      and raw_materials.deleted_at is null
    order by raw_materials.id
    for update of raw_materials
  loop
    v_has_requirements := true;
    v_required_quantity :=
      v_requirement.quantity_per_unit * p_quantity;

    select coalesce(sum(
      case raw_material_movements.type
        when 'purchase' then raw_material_movements.quantity
        when 'transfer_in' then raw_material_movements.quantity
        when 'use' then -raw_material_movements.quantity
        when 'transfer_out' then -raw_material_movements.quantity
      end
    ), 0::numeric)
    into v_current_stock
    from public.raw_material_movements
    where raw_material_movements.raw_material_id =
        v_requirement.raw_material_id
      and raw_material_movements.branch_id = p_branch_id
      and raw_material_movements.deleted_at is null;

    if v_current_stock < v_required_quantity then
      raise exception
        'Existencia insuficiente de la materia prima "%".',
        v_requirement.raw_material_name
        using errcode = 'P0001';
    end if;
  end loop;

  if not v_has_requirements then
    raise exception
      'El producto no tiene materias primas configuradas en la sucursal.'
      using errcode = 'P0001';
  end if;

  insert into public.inventory_consumptions (
    id,
    product_id,
    branch_id,
    quantity,
    occurred_at
  ) values (
    p_operation_id,
    p_product_id,
    p_branch_id,
    p_quantity,
    v_occurred_at
  )
  returning id into v_consumption_id;

  insert into public.raw_material_movements (
    raw_material_id,
    branch_id,
    type,
    quantity,
    product_id,
    consumption_id,
    note,
    occurred_at
  )
  select
    product_material_requirements.raw_material_id,
    p_branch_id,
    'use',
    product_material_requirements.quantity_per_unit * p_quantity,
    p_product_id,
    v_consumption_id,
    'Consumo automático #' || v_consumption_id::text,
    v_occurred_at
  from public.product_material_requirements
  join public.raw_materials
    on raw_materials.id = product_material_requirements.raw_material_id
  where product_material_requirements.product_id = p_product_id
    and product_material_requirements.deleted_at is null
    and raw_materials.branch_id = p_branch_id
    and raw_materials.deleted_at is null;

  return v_consumption_id;
end;
$$;

create or replace function public.soft_delete_finished_good(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.finished_goods
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'El activo no existe o ya fue eliminado.'
      using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.soft_delete_raw_material(p_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.raw_materials
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'La materia prima no existe o ya fue eliminada.'
      using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.soft_delete_raw_material_movement(
  p_id uuid
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.raw_material_movements
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'El movimiento no existe o ya fue eliminado.'
      using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.soft_delete_product_material_requirement(
  p_id uuid
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.product_material_requirements
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'La relación no existe o ya fue eliminada.'
      using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.soft_delete_inventory_consumption(
  p_id uuid
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.inventory_consumptions
  set deleted_at = now()
  where id = p_id
    and deleted_at is null;

  if not found then
    raise exception 'El consumo no existe o ya fue eliminado.'
      using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.configure_product_materials(uuid, jsonb)
  from public;
revoke all on function public.configure_product_materials(uuid, jsonb)
  from anon;
grant execute on function public.configure_product_materials(uuid, jsonb)
  to authenticated;

revoke all on function public.configure_product_branches(uuid, uuid[])
  from public;
revoke all on function public.configure_product_branches(uuid, uuid[])
  from anon;
grant execute on function public.configure_product_branches(uuid, uuid[])
  to authenticated;

revoke all on function public.configure_branch_products(uuid, uuid[])
  from public;
revoke all on function public.configure_branch_products(uuid, uuid[])
  from anon;
grant execute on function public.configure_branch_products(uuid, uuid[])
  to authenticated;

revoke all on function public.register_raw_material_movement(
  uuid,
  uuid,
  text,
  numeric,
  uuid,
  numeric,
  uuid,
  text,
  timestamptz
) from public;
revoke all on function public.register_raw_material_movement(
  uuid,
  uuid,
  text,
  numeric,
  uuid,
  numeric,
  uuid,
  text,
  timestamptz
) from anon;
grant execute on function public.register_raw_material_movement(
  uuid,
  uuid,
  text,
  numeric,
  uuid,
  numeric,
  uuid,
  text,
  timestamptz
) to authenticated;

revoke all on function public.transfer_raw_material(uuid, uuid, numeric, uuid)
  from public;
revoke all on function public.transfer_raw_material(uuid, uuid, numeric, uuid)
  from anon;
grant execute on function public.transfer_raw_material(uuid, uuid, numeric, uuid)
  to authenticated;

revoke all on function public.consume_product_materials(
  uuid,
  uuid,
  numeric,
  uuid
) from public;
revoke all on function public.consume_product_materials(
  uuid,
  uuid,
  numeric,
  uuid
) from anon;
grant execute on function public.consume_product_materials(
  uuid,
  uuid,
  numeric,
  uuid
) to authenticated;

revoke all on function public.soft_delete_finished_good(uuid) from public;
revoke all on function public.soft_delete_finished_good(uuid) from anon;
grant execute on function public.soft_delete_finished_good(uuid)
  to authenticated;

revoke all on function public.soft_delete_raw_material(uuid) from public;
revoke all on function public.soft_delete_raw_material(uuid) from anon;
grant execute on function public.soft_delete_raw_material(uuid)
  to authenticated;

revoke all on function public.soft_delete_raw_material_movement(uuid)
  from public;
revoke all on function public.soft_delete_raw_material_movement(uuid)
  from anon;
revoke all on function public.soft_delete_raw_material_movement(uuid)
  from authenticated;

revoke all on function public.soft_delete_product_material_requirement(uuid)
  from public;
revoke all on function public.soft_delete_product_material_requirement(uuid)
  from anon;
revoke all on function public.soft_delete_product_material_requirement(uuid)
  from authenticated;

revoke all on function public.soft_delete_inventory_consumption(uuid)
  from public;
revoke all on function public.soft_delete_inventory_consumption(uuid)
  from anon;
revoke all on function public.soft_delete_inventory_consumption(uuid)
  from authenticated;

revoke all on function public.set_inventory_updated_at() from public;
revoke all on function public.set_inventory_updated_at() from anon;
revoke all on function public.guard_raw_material_branch_change()
  from public;
revoke all on function public.guard_raw_material_branch_change()
  from anon;
revoke all on function public.soft_delete_branch_inventory() from public;
revoke all on function public.soft_delete_branch_inventory() from anon;
revoke all on function public.soft_delete_product_inventory() from public;
revoke all on function public.soft_delete_product_inventory() from anon;
revoke all on function public.soft_delete_raw_material_dependents()
  from public;
revoke all on function public.soft_delete_raw_material_dependents()
  from anon;
revoke all on function public.soft_delete_consumption_movements()
  from public;
revoke all on function public.soft_delete_consumption_movements()
  from anon;
