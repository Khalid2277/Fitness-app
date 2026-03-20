-- 00003_exercises.sql
-- Exercise library: global seed exercises + user-created custom exercises

create table exercises (
  id                  text primary key,  -- e.g. 'barbell_bench_press'
  user_id             uuid references auth.users on delete cascade,  -- null = global, non-null = custom
  name                text not null,
  description         text,
  instructions        text,
  tips                text[] default '{}',
  common_mistakes     text[] default '{}',
  primary_muscle      muscle_group not null,
  secondary_muscles   muscle_group[] default '{}',
  equipment           equipment_type not null,
  difficulty          exercise_difficulty not null,
  category            exercise_category not null,
  video_url           text,
  image_url           text,
  best_for_goals      text[] default '{}',
  setup_instructions  text,
  safety_tips         text,
  suggested_rep_range text not null default '8-12',
  is_custom           boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-update updated_at
create trigger exercises_updated_at
  before update on exercises
  for each row
  execute function update_updated_at_column();

-- Indexes
create index idx_exercises_primary_muscle on exercises (primary_muscle);
create index idx_exercises_equipment      on exercises (equipment);
create index idx_exercises_difficulty      on exercises (difficulty);
create index idx_exercises_category        on exercises (category);
create index idx_exercises_user_id         on exercises (user_id);
create index idx_exercises_name_search     on exercises using gin (to_tsvector('english', name));
