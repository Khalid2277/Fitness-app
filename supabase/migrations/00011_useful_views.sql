-- ─────────────────────────────────────────────────────────────────────────────
-- Daily nutrition summary view
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW daily_nutrition_summary AS
SELECT
  user_id,
  date_time::date AS date,
  COUNT(*)::int AS meal_count,
  ROUND(SUM(calories)::numeric, 1) AS total_calories,
  ROUND(SUM(protein)::numeric, 1) AS total_protein,
  ROUND(SUM(carbs)::numeric, 1) AS total_carbs,
  ROUND(SUM(fats)::numeric, 1) AS total_fats,
  ROUND(SUM(fiber)::numeric, 1) AS total_fiber
FROM meals
GROUP BY user_id, date_time::date;

-- RLS on view (Supabase requires this for views that reference RLS-protected tables)
ALTER VIEW daily_nutrition_summary SET (security_invoker = on);

-- ─────────────────────────────────────────────────────────────────────────────
-- Workout summary view
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW workout_summary AS
SELECT
  w.user_id,
  w.id AS workout_id,
  w.name,
  w.date,
  w.duration_seconds,
  w.is_completed,
  COUNT(DISTINCT we.id)::int AS exercise_count,
  COUNT(es.id)::int AS total_sets,
  ROUND(SUM(COALESCE(es.weight_kg, 0) * COALESCE(es.reps, 0))::numeric, 1) AS total_volume
FROM workouts w
LEFT JOIN workout_exercises we ON we.workout_id = w.id
LEFT JOIN exercise_sets es ON es.workout_exercise_id = we.id
  AND es.is_completed = true AND es.is_warmup = false
GROUP BY w.user_id, w.id, w.name, w.date, w.duration_seconds, w.is_completed;

ALTER VIEW workout_summary SET (security_invoker = on);

-- ─────────────────────────────────────────────────────────────────────────────
-- Function: Get weekly muscle volume for a user
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_weekly_muscle_volume(
  p_user_id uuid,
  p_week_start date DEFAULT (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::int)
)
RETURNS TABLE(
  muscle_group text,
  total_sets bigint,
  total_volume numeric
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    we.primary_muscle AS muscle_group,
    COUNT(es.id) AS total_sets,
    ROUND(SUM(COALESCE(es.weight_kg, 0) * COALESCE(es.reps, 0))::numeric, 1) AS total_volume
  FROM workouts w
  JOIN workout_exercises we ON we.workout_id = w.id
  JOIN exercise_sets es ON es.workout_exercise_id = we.id
    AND es.is_completed = true AND es.is_warmup = false
  WHERE w.user_id = p_user_id
    AND w.date >= p_week_start
    AND w.date < p_week_start + 7
  GROUP BY we.primary_muscle
  ORDER BY total_volume DESC;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Function: Get personal records for a user
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_personal_records(p_user_id uuid)
RETURNS TABLE(
  exercise_name text,
  exercise_id text,
  max_weight numeric,
  max_reps int,
  max_volume numeric,
  achieved_date date
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  WITH best_sets AS (
    SELECT
      we.exercise_name,
      we.exercise_id,
      es.weight_kg,
      es.reps,
      (COALESCE(es.weight_kg, 0) * COALESCE(es.reps, 0)) AS volume,
      w.date,
      ROW_NUMBER() OVER (
        PARTITION BY we.exercise_id
        ORDER BY (COALESCE(es.weight_kg, 0) * COALESCE(es.reps, 0)) DESC
      ) AS rn
    FROM workouts w
    JOIN workout_exercises we ON we.workout_id = w.id
    JOIN exercise_sets es ON es.workout_exercise_id = we.id
      AND es.is_completed = true AND es.is_warmup = false
    WHERE w.user_id = p_user_id
  )
  SELECT
    exercise_name,
    exercise_id,
    ROUND(weight_kg::numeric, 1) AS max_weight,
    reps::int AS max_reps,
    ROUND(volume::numeric, 1) AS max_volume,
    date AS achieved_date
  FROM best_sets
  WHERE rn = 1
  ORDER BY max_volume DESC;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Trigger: Deactivate other plans when a new plan is activated
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION deactivate_other_plans()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_active = true THEN
    UPDATE workout_plans
    SET is_active = false
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND is_active = true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_deactivate_other_plans ON workout_plans;
CREATE TRIGGER trg_deactivate_other_plans
  BEFORE INSERT OR UPDATE OF is_active ON workout_plans
  FOR EACH ROW
  WHEN (NEW.is_active = true)
  EXECUTE FUNCTION deactivate_other_plans();
