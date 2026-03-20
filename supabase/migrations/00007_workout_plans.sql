-- 00007_workout_plans.sql
-- Workout plan generation: plans -> plan_days -> plan_exercises

-- ============================================================
-- Workout Plans
-- ============================================================
create table workout_plans (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users on delete cascade,
  name             text not null,
  description      text,
  split_type       split_type not null,
  goal             workout_goal not null,
  experience_level experience_level not null,
  days_per_week    int not null,
  is_active        boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger workout_plans_updated_at
  before update on workout_plans
  for each row
  execute function update_updated_at_column();

create index idx_workout_plans_user_id on workout_plans (user_id);

-- ============================================================
-- Plan Days
-- ============================================================
create table plan_days (
  id              uuid primary key default uuid_generate_v4(),
  plan_id         uuid not null references workout_plans on delete cascade,
  name            text not null,
  day_number      int not null,
  focus           text,
  target_muscles  muscle_group[] default '{}',

  created_at timestamptz not null default now(),

  unique (plan_id, day_number)
);

create index idx_plan_days_plan_id on plan_days (plan_id);

-- ============================================================
-- Plan Exercises
-- ============================================================
create table plan_exercises (
  id              uuid primary key default uuid_generate_v4(),
  plan_day_id     uuid not null references plan_days on delete cascade,
  exercise_id     text not null references exercises on delete restrict,
  exercise_name   text not null,       -- cached for fast reads
  primary_muscle  muscle_group not null,
  sets            int not null default 3,
  reps            int not null default 10,
  rest_seconds    int not null default 90,
  notes           text,
  sort_order      int not null default 0,

  created_at timestamptz not null default now()
);

create index idx_plan_exercises_plan_day_id  on plan_exercises (plan_day_id);
create index idx_plan_exercises_exercise_id  on plan_exercises (exercise_id);
