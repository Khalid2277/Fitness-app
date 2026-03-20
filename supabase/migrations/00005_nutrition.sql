-- 00005_nutrition.sql
-- Food items catalog and meal logging

-- ============================================================
-- Food Items (global + user-created)
-- ============================================================
create table food_items (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid references auth.users on delete cascade,  -- null = global
  name          text not null,
  brand         text,
  calories      numeric not null check (calories >= 0),
  protein       numeric not null default 0 check (protein >= 0),
  carbs         numeric not null default 0 check (carbs >= 0),
  fats          numeric not null default 0 check (fats >= 0),
  fiber         numeric not null default 0 check (fiber >= 0),
  serving_size  numeric,
  serving_unit  text,
  category      food_category not null default 'custom',
  barcode       text,
  source        text not null default 'custom',
  source_id     text,
  image_url     text,
  is_custom     boolean not null default true,
  use_count     int not null default 0,
  last_used_at  timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger food_items_updated_at
  before update on food_items
  for each row
  execute function update_updated_at_column();

-- Indexes
create index idx_food_items_user_id      on food_items (user_id);
create index idx_food_items_name_search  on food_items using gin (to_tsvector('english', name));
create index idx_food_items_barcode      on food_items (barcode) where barcode is not null;
create index idx_food_items_source       on food_items (source, source_id) where source_id is not null;
create index idx_food_items_recent       on food_items (user_id, last_used_at desc nulls last);
create index idx_food_items_frequent     on food_items (user_id, use_count desc);

-- ============================================================
-- Meals (logged food entries)
-- ============================================================
create table meals (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references auth.users on delete cascade,
  food_item_id  uuid references food_items on delete set null,
  name          text not null,
  meal_type     meal_type not null,
  calories      numeric not null check (calories >= 0),
  protein       numeric not null default 0 check (protein >= 0),
  carbs         numeric not null default 0 check (carbs >= 0),
  fats          numeric not null default 0 check (fats >= 0),
  fiber         numeric not null default 0 check (fiber >= 0),
  date_time     timestamptz not null default now(),
  serving_size  numeric,
  serving_unit  text,
  notes         text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger meals_updated_at
  before update on meals
  for each row
  execute function update_updated_at_column();

create index idx_meals_user_date on meals (user_id, date_time desc);
