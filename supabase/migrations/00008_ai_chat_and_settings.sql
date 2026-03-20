-- 00008_ai_chat_and_settings.sql
-- AI chat messages, progress photos, and app settings

-- ============================================================
-- AI Chat Messages
-- ============================================================
create table ai_chat_messages (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users on delete cascade,
  session_id  uuid not null default uuid_generate_v4(),
  role        text not null check (role in ('user', 'assistant', 'system')),
  content     text not null,
  agent_type  text not null check (agent_type in ('trainer', 'nutritionist', 'general')),
  suggestions text[] not null default '{}',

  created_at timestamptz not null default now()
);

create index idx_ai_chat_messages_user_id    on ai_chat_messages (user_id);
create index idx_ai_chat_messages_session_id on ai_chat_messages (user_id, session_id, created_at);

-- ============================================================
-- Progress Photos
-- ============================================================
create table progress_photos (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid not null references auth.users on delete cascade,
  date                 date not null default current_date,
  front_photo_url      text,
  left_side_photo_url  text,
  right_side_photo_url text,
  back_photo_url       text,
  notes                text,
  weight_kg            numeric(5,1),
  body_fat_percentage  numeric(4,1),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger progress_photos_updated_at
  before update on progress_photos
  for each row
  execute function update_updated_at_column();

create index idx_progress_photos_user_date on progress_photos (user_id, date desc);

-- ============================================================
-- App Settings (one row per user)
-- ============================================================
create table app_settings (
  user_id                uuid primary key references auth.users on delete cascade,
  theme_mode             text not null default 'dark' check (theme_mode in ('light', 'dark', 'system')),
  unit_system            text not null default 'metric' check (unit_system in ('metric', 'imperial')),
  rest_timer_seconds     int not null default 90,
  notifications_enabled  boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger app_settings_updated_at
  before update on app_settings
  for each row
  execute function update_updated_at_column();
