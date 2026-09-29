-- Public storefront reads published records. Only explicitly listed auth users edit.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create or replace function public.is_emir_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) > 0),
  category text not null check (category in ('ceramic', 'adhesive', 'toilet', 'sink')),
  brand text not null default '',
  size text not null default '',
  quality text not null default '',
  image_path text,
  published boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.catalogs (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) > 0),
  description text not null default '',
  published boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.catalog_products (
  catalog_id uuid not null references public.catalogs(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  primary key (catalog_id, product_id)
);

alter table public.admin_users enable row level security;
alter table public.products enable row level security;
alter table public.catalogs enable row level security;
alter table public.catalog_products enable row level security;

create policy "admin can read own membership" on public.admin_users
  for select to authenticated using (user_id = (select auth.uid()));

create policy "public can read published products" on public.products
  for select to anon, authenticated using (published or (select public.is_emir_admin()));
create policy "admin can insert products" on public.products
  for insert to authenticated with check ((select public.is_emir_admin()));
create policy "admin can update products" on public.products
  for update to authenticated using ((select public.is_emir_admin()))
  with check ((select public.is_emir_admin()));
create policy "admin can delete products" on public.products
  for delete to authenticated using ((select public.is_emir_admin()));

create policy "public can read published catalogs" on public.catalogs
  for select to anon, authenticated using (published or (select public.is_emir_admin()));
create policy "admin can insert catalogs" on public.catalogs
  for insert to authenticated with check ((select public.is_emir_admin()));
create policy "admin can update catalogs" on public.catalogs
  for update to authenticated using ((select public.is_emir_admin()))
  with check ((select public.is_emir_admin()));
create policy "admin can delete catalogs" on public.catalogs
  for delete to authenticated using ((select public.is_emir_admin()));

create policy "public can read published catalog membership" on public.catalog_products
  for select to anon, authenticated using (
    (select public.is_emir_admin()) or (
      exists (select 1 from public.catalogs c where c.id = catalog_id and c.published)
      and exists (select 1 from public.products p where p.id = product_id and p.published)
    )
  );
create policy "admin can insert catalog membership" on public.catalog_products
  for insert to authenticated with check ((select public.is_emir_admin()));
create policy "admin can delete catalog membership" on public.catalog_products
  for delete to authenticated using ((select public.is_emir_admin()));

grant select on public.admin_users to authenticated;
grant select on public.products, public.catalogs, public.catalog_products to anon, authenticated;
grant insert, update, delete on public.products, public.catalogs to authenticated;
grant insert, delete on public.catalog_products to authenticated;
grant execute on function public.is_emir_admin() to anon, authenticated;

-- Save catalog details and memberships in one transaction.
create or replace function public.save_emir_catalog(
  p_id uuid, p_title text, p_description text, p_published boolean,
  p_product_ids uuid[]
) returns uuid language plpgsql security definer set search_path = '' as $$
declare saved_id uuid;
begin
  if not public.is_emir_admin() then
    raise exception 'Not authorized';
  end if;
  if nullif(btrim(p_title), '') is null then
    raise exception 'Catalog title required';
  end if;
  if p_id is null then
    insert into public.catalogs(title, description, published)
    values (btrim(p_title), coalesce(p_description, ''), coalesce(p_published, false))
    returning id into saved_id;
  else
    update public.catalogs set title = btrim(p_title),
      description = coalesce(p_description, ''), published = coalesce(p_published, false)
    where id = p_id returning id into saved_id;
    if saved_id is null then raise exception 'Catalog not found'; end if;
  end if;
  delete from public.catalog_products where catalog_id = saved_id;
  insert into public.catalog_products(catalog_id, product_id)
  select saved_id, product_id
  from (select distinct unnest(coalesce(p_product_ids, '{}'::uuid[])) as product_id) ids;
  return saved_id;
end;
$$;
revoke all on function public.save_emir_catalog(uuid, text, text, boolean, uuid[]) from public;
grant execute on function public.save_emir_catalog(uuid, text, text, boolean, uuid[]) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 10485760,
  array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "admin can upload product images" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'product-images' and (select public.is_emir_admin())
  );
create policy "admin can delete product images" on storage.objects
  for delete to authenticated using (
    bucket_id = 'product-images' and (select public.is_emir_admin())
  );
