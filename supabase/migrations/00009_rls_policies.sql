-- 00009_rls_policies.sql
-- Row Level Security policies for all tables

-- ============================================================
-- Enable RLS on every table
-- ============================================================
alter table profiles          enable row level security;
alter table exercises         enable row level security;
alter table workouts          enable row level security;
alter table workout_exercises enable row level security;
alter table exercise_sets     enable row level security;
alter table food_items        enable row level security;
alter table meals             enable row level security;
alter table body_metrics      enable row level security;
alter table workout_plans     enable row level security;
alter table plan_days         enable row level security;
alter table plan_exercises    enable row level security;
alter table ai_chat_messages  enable row level security;
alter table progress_photos   enable row level security;
alter table app_settings      enable row level security;

-- ============================================================
-- Profiles: users can read and update their own profile
-- ============================================================
create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id);

-- ============================================================
-- Exercises: anyone reads global, users CRUD own custom
-- ============================================================
create policy "Anyone can read global exercises"
  on exercises for select
  using (user_id is null);

create policy "Users can read own custom exercises"
  on exercises for select
  using (auth.uid() = user_id);

create policy "Users can insert own custom exercises"
  on exercises for insert
  with check (auth.uid() = user_id and is_custom = true);

create policy "Users can update own custom exercises"
  on exercises for update
  using (auth.uid() = user_id and is_custom = true);

create policy "Users can delete own custom exercises"
  on exercises for delete
  using (auth.uid() = user_id and is_custom = true);

-- ============================================================
-- Workouts: all ops where auth.uid() = user_id
-- ============================================================
create policy "Users can select own workouts"
  on workouts for select
  using (auth.uid() = user_id);

create policy "Users can insert own workouts"
  on workouts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own workouts"
  on workouts for update
  using (auth.uid() = user_id);

create policy "Users can delete own workouts"
  on workouts for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Workout Exercises: via join to workouts
-- ============================================================
create policy "Users can select own workout exercises"
  on workout_exercises for select
  using (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can insert own workout exercises"
  on workout_exercises for insert
  with check (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can update own workout exercises"
  on workout_exercises for update
  using (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can delete own workout exercises"
  on workout_exercises for delete
  using (
    exists (
      select 1 from workouts
      where workouts.id = workout_exercises.workout_id
        and workouts.user_id = auth.uid()
    )
  );

-- ============================================================
-- Exercise Sets: via join to workout_exercises -> workouts
-- ============================================================
create policy "Users can select own exercise sets"
  on exercise_sets for select
  using (
    exists (
      select 1 from workout_exercises
      join workouts on workouts.id = workout_exercises.workout_id
      where workout_exercises.id = exercise_sets.workout_exercise_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can insert own exercise sets"
  on exercise_sets for insert
  with check (
    exists (
      select 1 from workout_exercises
      join workouts on workouts.id = workout_exercises.workout_id
      where workout_exercises.id = exercise_sets.workout_exercise_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can update own exercise sets"
  on exercise_sets for update
  using (
    exists (
      select 1 from workout_exercises
      join workouts on workouts.id = workout_exercises.workout_id
      where workout_exercises.id = exercise_sets.workout_exercise_id
        and workouts.user_id = auth.uid()
    )
  );

create policy "Users can delete own exercise sets"
  on exercise_sets for delete
  using (
    exists (
      select 1 from workout_exercises
      join workouts on workouts.id = workout_exercises.workout_id
      where workout_exercises.id = exercise_sets.workout_exercise_id
        and workouts.user_id = auth.uid()
    )
  );

-- ============================================================
-- Food Items: anyone reads global, users CRUD own
-- ============================================================
create policy "Anyone can read global food items"
  on food_items for select
  using (user_id is null);

create policy "Users can read own food items"
  on food_items for select
  using (auth.uid() = user_id);

create policy "Users can insert own food items"
  on food_items for insert
  with check (auth.uid() = user_id);

create policy "Users can update own food items"
  on food_items for update
  using (auth.uid() = user_id);

create policy "Users can delete own food items"
  on food_items for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Meals: all ops where auth.uid() = user_id
-- ============================================================
create policy "Users can select own meals"
  on meals for select
  using (auth.uid() = user_id);

create policy "Users can insert own meals"
  on meals for insert
  with check (auth.uid() = user_id);

create policy "Users can update own meals"
  on meals for update
  using (auth.uid() = user_id);

create policy "Users can delete own meals"
  on meals for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Body Metrics: all where auth.uid() = user_id
-- ============================================================
create policy "Users can select own body metrics"
  on body_metrics for select
  using (auth.uid() = user_id);

create policy "Users can insert own body metrics"
  on body_metrics for insert
  with check (auth.uid() = user_id);

create policy "Users can update own body metrics"
  on body_metrics for update
  using (auth.uid() = user_id);

create policy "Users can delete own body metrics"
  on body_metrics for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Workout Plans: all where auth.uid() = user_id
-- ============================================================
create policy "Users can select own workout plans"
  on workout_plans for select
  using (auth.uid() = user_id);

create policy "Users can insert own workout plans"
  on workout_plans for insert
  with check (auth.uid() = user_id);

create policy "Users can update own workout plans"
  on workout_plans for update
  using (auth.uid() = user_id);

create policy "Users can delete own workout plans"
  on workout_plans for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Plan Days: via join to workout_plans
-- ============================================================
create policy "Users can select own plan days"
  on plan_days for select
  using (
    exists (
      select 1 from workout_plans
      where workout_plans.id = plan_days.plan_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can insert own plan days"
  on plan_days for insert
  with check (
    exists (
      select 1 from workout_plans
      where workout_plans.id = plan_days.plan_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can update own plan days"
  on plan_days for update
  using (
    exists (
      select 1 from workout_plans
      where workout_plans.id = plan_days.plan_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can delete own plan days"
  on plan_days for delete
  using (
    exists (
      select 1 from workout_plans
      where workout_plans.id = plan_days.plan_id
        and workout_plans.user_id = auth.uid()
    )
  );

-- ============================================================
-- Plan Exercises: via join to plan_days -> workout_plans
-- ============================================================
create policy "Users can select own plan exercises"
  on plan_exercises for select
  using (
    exists (
      select 1 from plan_days
      join workout_plans on workout_plans.id = plan_days.plan_id
      where plan_days.id = plan_exercises.plan_day_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can insert own plan exercises"
  on plan_exercises for insert
  with check (
    exists (
      select 1 from plan_days
      join workout_plans on workout_plans.id = plan_days.plan_id
      where plan_days.id = plan_exercises.plan_day_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can update own plan exercises"
  on plan_exercises for update
  using (
    exists (
      select 1 from plan_days
      join workout_plans on workout_plans.id = plan_days.plan_id
      where plan_days.id = plan_exercises.plan_day_id
        and workout_plans.user_id = auth.uid()
    )
  );

create policy "Users can delete own plan exercises"
  on plan_exercises for delete
  using (
    exists (
      select 1 from plan_days
      join workout_plans on workout_plans.id = plan_days.plan_id
      where plan_days.id = plan_exercises.plan_day_id
        and workout_plans.user_id = auth.uid()
    )
  );

-- ============================================================
-- AI Chat Messages: all where auth.uid() = user_id
-- ============================================================
create policy "Users can select own chat messages"
  on ai_chat_messages for select
  using (auth.uid() = user_id);

create policy "Users can insert own chat messages"
  on ai_chat_messages for insert
  with check (auth.uid() = user_id);

create policy "Users can update own chat messages"
  on ai_chat_messages for update
  using (auth.uid() = user_id);

create policy "Users can delete own chat messages"
  on ai_chat_messages for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Progress Photos: all where auth.uid() = user_id
-- ============================================================
create policy "Users can select own progress photos"
  on progress_photos for select
  using (auth.uid() = user_id);

create policy "Users can insert own progress photos"
  on progress_photos for insert
  with check (auth.uid() = user_id);

create policy "Users can update own progress photos"
  on progress_photos for update
  using (auth.uid() = user_id);

create policy "Users can delete own progress photos"
  on progress_photos for delete
  using (auth.uid() = user_id);

-- ============================================================
-- App Settings: all where auth.uid() = user_id
-- ============================================================
create policy "Users can select own app settings"
  on app_settings for select
  using (auth.uid() = user_id);

create policy "Users can insert own app settings"
  on app_settings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own app settings"
  on app_settings for update
  using (auth.uid() = user_id);

create policy "Users can delete own app settings"
  on app_settings for delete
  using (auth.uid() = user_id);
