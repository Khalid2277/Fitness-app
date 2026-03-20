-- 00006_body_metrics.sql
-- Body measurements and weight tracking

create table body_metrics (
  id                    uuid primary key default uuid_generate_v4(),
  user_id               uuid not null references auth.users on delete cascade,
  date                  date not null default current_date,
  weight_kg             numeric(5,1),
  body_fat_percentage   numeric(4,1),
  chest_cm              numeric(5,1),
  waist_cm              numeric(5,1),
  hips_cm               numeric(5,1),
  bicep_left_cm         numeric(5,1),
  bicep_right_cm        numeric(5,1),
  thigh_left_cm         numeric(5,1),
  thigh_right_cm        numeric(5,1),
  neck_cm               numeric(5,1),
  notes                 text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, date)
);

create trigger body_metrics_updated_at
  before update on body_metrics
  for each row
  execute function update_updated_at_column();

create index idx_body_metrics_user_date on body_metrics (user_id, date desc);
