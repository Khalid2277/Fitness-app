-- 00004_workouts.sql
-- Workout logging: workouts -> workout_exercises -> exercise_sets

-- ============================================================
-- Workouts
-- ============================================================
create table workouts (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users on delete cascade,
  name             text not null,
  date             timestamptz not null default now(),
  duration_seconds int not null default 0,
  notes            text,
  is_completed     boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger workouts_updated_at
  before update on workouts
  for each row
  execute function update_updated_at_column();

create index idx_workouts_user_id  on workouts (user_id);
create index idx_workouts_date     on workouts (user_id, date desc);

-- ============================================================
-- Workout Exercises (exercises within a workout)
-- ============================================================
create table workout_exercises (
  id             uuid primary key default uuid_generate_v4(),
  workout_id     uuid not null references workouts on delete cascade,
  exercise_id    text not null references exercises on delete restrict,
  exercise_name  text not null,       -- cached for fast reads
  primary_muscle muscle_group not null,
  notes          text,
  sort_order     int not null default 0,

  created_at timestamptz not null default now()
);

create index idx_workout_exercises_workout_id  on workout_exercises (workout_id);
create index idx_workout_exercises_exercise_id on workout_exercises (exercise_id);

-- ============================================================
-- Exercise Sets (individual sets within a workout exercise)
-- ============================================================
create table exercise_sets (
  id                  uuid primary key default uuid_generate_v4(),
  workout_exercise_id uuid not null references workout_exercises on delete cascade,
  set_number          int not null check (set_number > 0),
  weight_kg           numeric(6,2),
  reps                int,
  rpe                 numeric(3,1) check (rpe >= 0 and rpe <= 10),
  rest_time_seconds   int,
  is_completed        boolean not null default false,
  is_warmup           boolean not null default false,

  created_at timestamptz not null default now(),

  unique (workout_exercise_id, set_number)
);

create index idx_exercise_sets_workout_exercise_id on exercise_sets (workout_exercise_id);
