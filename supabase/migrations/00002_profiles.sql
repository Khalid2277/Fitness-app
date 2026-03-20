-- 00002_profiles.sql
-- User profiles table with auto-creation on signup

create table profiles (
  id              uuid primary key references auth.users on delete cascade,
  name            text,
  height_cm       numeric(5,1),
  weight_kg       numeric(5,1),
  age             int,
  goal            workout_goal not null default 'general_fitness',
  experience_level experience_level not null default 'beginner',
  gender          gender_type,
  activity_level  activity_level,

  -- Nullable nutrition target overrides (computed defaults used when null)
  daily_calorie_target numeric,
  protein_target       numeric,
  carbs_target         numeric,
  fats_target          numeric,

  workout_days_per_week int not null default 4,
  join_date             date default current_date,
  current_streak        int not null default 0,
  longest_streak        int not null default 0,
  avatar_url            text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-update updated_at
create trigger profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();

-- Index on goal for filtering / leaderboards
create index idx_profiles_goal on profiles (goal);

-- ============================================================
-- Auto-create a profile row when a new auth user signs up
-- ============================================================
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      ''
    )
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function handle_new_user();
