-- Run once after 20260929_catalog.sql. Existing products keep an empty description.
alter table public.products
  add column if not exists description text not null default '';
