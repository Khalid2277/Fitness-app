-- Seed all exercises from AlfaNutrition exercise database as global exercises
-- Generated from lib/data/seed/exercise_database.dart
-- Total exercises: 90

BEGIN;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'bench_press',
  NULL,
  'Barbell Bench Press',
  'The king of chest exercises. A compound push movement.',
  'Lie on a flat bench, grip the bar slightly wider than shoulder width, lower to mid-chest, press up.',
  ARRAY['Keep shoulder blades retracted','Drive feet into the floor','Control the descent']::text[],
  ARRAY['Bouncing bar off chest','Flaring elbows too wide','Lifting hips off bench']::text[],
  'chest'::muscle_group,
  ARRAY['triceps'::muscle_group,'shoulders'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'incline_db_press',
  NULL,
  'Incline Dumbbell Press',
  'Targets the upper chest with dumbbells on an incline bench.',
  'Set bench to 30-45 degrees, press dumbbells from shoulder level to full extension.',
  ARRAY['Keep wrists neutral','Full range of motion','Squeeze at the top']::text[],
  ARRAY['Incline too steep','Not going deep enough']::text[],
  'chest'::muscle_group,
  ARRAY['shoulders'::muscle_group,'triceps'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_fly',
  NULL,
  'Cable Fly',
  'Constant tension chest isolation with cables.',
  'Set cables to mid height, step forward, bring handles together in an arc.',
  ARRAY['Slight bend in elbows','Squeeze at peak contraction','Control the eccentric']::text[],
  ARRAY['Using too much weight','Bending arms too much']::text[],
  'chest'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'push_up',
  NULL,
  'Push-Up',
  'Classic bodyweight chest exercise.',
  'Hands shoulder-width apart, lower chest to floor, push up.',
  ARRAY['Keep core tight','Full range of motion','Elbows at 45 degrees']::text[],
  ARRAY['Sagging hips','Not going low enough']::text[],
  'chest'::muscle_group,
  ARRAY['triceps'::muscle_group,'shoulders'::muscle_group,'core'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Endurance']::text[],
  NULL,
  NULL,
  '10-25',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'dips',
  NULL,
  'Dips',
  'Compound pressing movement for chest and triceps.',
  'Grip parallel bars, lean slightly forward, lower until upper arms are parallel to floor, press up.',
  ARRAY['Lean forward for more chest','Stay upright for more triceps']::text[],
  ARRAY['Going too deep','Swinging body']::text[],
  'chest'::muscle_group,
  ARRAY['triceps'::muscle_group,'shoulders'::muscle_group],
  'bodyweight'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'barbell_row',
  NULL,
  'Barbell Row',
  'Heavy compound pull for overall back thickness.',
  'Hinge at hips, grip bar slightly wider than shoulder width, row to lower chest.',
  ARRAY['Keep back flat','Drive elbows back','Squeeze shoulder blades']::text[],
  ARRAY['Rounding lower back','Using momentum']::text[],
  'back'::muscle_group,
  ARRAY['biceps'::muscle_group,'lats'::muscle_group,'traps'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'pull_up',
  NULL,
  'Pull-Up',
  'The gold standard for back development.',
  'Hang from bar with overhand grip, pull chin above bar, lower with control.',
  ARRAY['Initiate with lats','Full dead hang at bottom','Avoid kipping']::text[],
  ARRAY['Half reps','Using momentum','Ignoring eccentric']::text[],
  'lats'::muscle_group,
  ARRAY['biceps'::muscle_group,'back'::muscle_group,'forearms'::muscle_group],
  'bodyweight'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'lat_pulldown',
  NULL,
  'Lat Pulldown',
  'Machine-based lat isolation, great for all levels.',
  'Grip bar wider than shoulder width, pull to upper chest, control the return.',
  ARRAY['Lean back slightly','Drive elbows down','Avoid pulling behind neck']::text[],
  ARRAY['Leaning too far back','Using arms instead of lats']::text[],
  'lats'::muscle_group,
  ARRAY['biceps'::muscle_group,'back'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'seated_cable_row',
  NULL,
  'Seated Cable Row',
  'Targets mid-back with constant cable tension.',
  'Sit with feet on platform, pull handle to torso, squeeze shoulder blades.',
  ARRAY['Keep torso still','Full stretch at bottom','Squeeze at peak']::text[],
  ARRAY['Excessive lean','Shrugging shoulders']::text[],
  'back'::muscle_group,
  ARRAY['biceps'::muscle_group,'lats'::muscle_group,'traps'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'db_row',
  NULL,
  'Dumbbell Row',
  'Unilateral back exercise for balanced development.',
  'One knee on bench, row dumbbell to hip, squeeze at top.',
  ARRAY['Keep hips square','Row to hip not shoulder','Full stretch']::text[],
  ARRAY['Rotating torso','Using momentum']::text[],
  'back'::muscle_group,
  ARRAY['biceps'::muscle_group,'lats'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'ohp',
  NULL,
  'Overhead Press',
  'Primary compound shoulder builder.',
  'Press barbell from front shoulders to overhead lockout.',
  ARRAY['Brace core','Lock out at top','Bar path close to face']::text[],
  ARRAY['Excessive lean back','Partial range of motion']::text[],
  'shoulders'::muscle_group,
  ARRAY['triceps'::muscle_group,'core'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-10',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'lateral_raise',
  NULL,
  'Lateral Raise',
  'Isolation exercise for medial deltoids.',
  'Hold dumbbells at sides, raise arms to shoulder height in an arc.',
  ARRAY['Lead with elbows','Slight forward lean','Control descent']::text[],
  ARRAY['Swinging weight','Going above shoulder height','Shrugging']::text[],
  'shoulders'::muscle_group,
  ARRAY['traps'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'face_pull',
  NULL,
  'Face Pull',
  'Rear delt and rotator cuff health exercise.',
  'Set cable to face height, pull rope to face while externally rotating.',
  ARRAY['Squeeze rear delts','High elbow position','Light weight high reps']::text[],
  ARRAY['Using too much weight','Pulling too low']::text[],
  'shoulders'::muscle_group,
  ARRAY['traps'::muscle_group,'back'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'barbell_curl',
  NULL,
  'Barbell Curl',
  'Classic biceps mass builder.',
  'Stand with barbell, curl to shoulder height, lower with control.',
  ARRAY['Keep elbows pinned','Full range of motion','Avoid swinging']::text[],
  ARRAY['Swinging body','Partial reps','Elbows drifting forward']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'barbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'hammer_curl',
  NULL,
  'Hammer Curl',
  'Neutral grip curl targeting brachialis and brachioradialis.',
  'Hold dumbbells with neutral grip, curl to shoulder, lower slowly.',
  ARRAY['Keep palms facing each other','Alternate or both arms','Control the weight']::text[],
  ARRAY['Swinging','Partial range']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'tricep_pushdown',
  NULL,
  'Tricep Pushdown',
  'Cable isolation for triceps.',
  'Grip bar at cable station, push down to full extension, return with control.',
  ARRAY['Keep elbows at sides','Squeeze at bottom','Control return']::text[],
  ARRAY['Flaring elbows','Leaning over the bar']::text[],
  'triceps'::muscle_group,
  '{}'::muscle_group[],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'skull_crusher',
  NULL,
  'Skull Crusher',
  'Lying triceps extension for long head development.',
  'Lie on bench, lower EZ bar to forehead, extend to lockout.',
  ARRAY['Keep elbows narrow','Lower behind head for more stretch','Control descent']::text[],
  ARRAY['Flaring elbows','Using too much weight']::text[],
  'triceps'::muscle_group,
  '{}'::muscle_group[],
  'ez_bar'::equipment_type,
  'intermediate'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'barbell_squat',
  NULL,
  'Barbell Squat',
  'The ultimate lower body compound exercise.',
  'Bar on upper back, squat to parallel or below, drive up through heels.',
  ARRAY['Keep chest up','Knees track over toes','Brace core throughout']::text[],
  ARRAY['Rounding back','Knees caving in','Not hitting depth']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group,'core'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'leg_press',
  NULL,
  'Leg Press',
  'Machine-based quad dominant compound movement.',
  'Place feet shoulder width on platform, lower sled, press to extension.',
  ARRAY['Do not lock knees','Full range of motion','Keep back flat on pad']::text[],
  ARRAY['Locking out knees','Too much weight with partial ROM']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'leg_extension',
  NULL,
  'Leg Extension',
  'Quad isolation exercise.',
  'Sit in machine, extend legs to full lockout, lower with control.',
  ARRAY['Squeeze at top','Control eccentric','Adjust pad to ankle']::text[],
  ARRAY['Using momentum','Partial range']::text[],
  'quadriceps'::muscle_group,
  '{}'::muscle_group[],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'lunges',
  NULL,
  'Walking Lunges',
  'Unilateral leg exercise for balance and strength.',
  'Step forward into a lunge position, drive up and step into next lunge.',
  ARRAY['Keep torso upright','Front knee over ankle','Long steps']::text[],
  ARRAY['Short steps','Leaning forward','Knee caving']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '10-14',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'rdl',
  NULL,
  'Romanian Deadlift',
  'Hip hinge movement for hamstring and glute development.',
  'Hold barbell, hinge at hips with slight knee bend, lower to mid-shin, drive hips forward.',
  ARRAY['Keep bar close to body','Feel stretch in hamstrings','Squeeze glutes at top']::text[],
  ARRAY['Rounding back','Bending knees too much','Going too low']::text[],
  'hamstrings'::muscle_group,
  ARRAY['glutes'::muscle_group,'back'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'leg_curl',
  NULL,
  'Lying Leg Curl',
  'Hamstring isolation exercise.',
  'Lie face down on machine, curl pad toward glutes, lower with control.',
  ARRAY['Keep hips on pad','Full range of motion','Squeeze at top']::text[],
  ARRAY['Lifting hips','Using momentum']::text[],
  'hamstrings'::muscle_group,
  ARRAY['calves'::muscle_group],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'hip_thrust',
  NULL,
  'Hip Thrust',
  'The best exercise for glute activation and development.',
  'Upper back on bench, bar over hips, thrust hips to full extension.',
  ARRAY['Chin tucked at top','Squeeze glutes hard','Pause at top']::text[],
  ARRAY['Hyperextending lower back','Not reaching full hip extension']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'core'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'calf_raise',
  NULL,
  'Standing Calf Raise',
  'Primary calf builder targeting gastrocnemius.',
  'Stand on edge of platform, raise heels as high as possible, lower with full stretch.',
  ARRAY['Full range of motion','Pause at top','Slow eccentric']::text[],
  ARRAY['Bouncing','Partial range of motion']::text[],
  'calves'::muscle_group,
  '{}'::muscle_group[],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'plank',
  NULL,
  'Plank',
  'Isometric core stability exercise.',
  'Forearms and toes on ground, hold body in a straight line.',
  ARRAY['Squeeze glutes','Brace core','Keep hips level']::text[],
  ARRAY['Sagging hips','Piking hips up']::text[],
  'core'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Endurance']::text[],
  NULL,
  NULL,
  '30-60s',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_crunch',
  NULL,
  'Cable Crunch',
  'Weighted core exercise for abdominal development.',
  'Kneel at cable machine, hold rope behind head, crunch down.',
  ARRAY['Focus on contracting abs','Do not pull with arms','Controlled movement']::text[],
  ARRAY['Sitting back on heels','Using arms to pull']::text[],
  'core'::muscle_group,
  ARRAY['obliques'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'deadlift',
  NULL,
  'Deadlift',
  'Full-body compound pull from the floor.',
  'Stand with mid-foot under bar, grip bar, lift by driving hips and legs, stand tall.',
  ARRAY['Keep bar close','Brace core','Lock out with glutes']::text[],
  ARRAY['Rounding back','Pulling with arms','Hips shooting up too fast']::text[],
  'back'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'glutes'::muscle_group,'quadriceps'::muscle_group,'core'::muscle_group,'traps'::muscle_group,'forearms'::muscle_group],
  'barbell'::equipment_type,
  'advanced'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength']::text[],
  NULL,
  NULL,
  '3-8',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'barbell_shrug',
  NULL,
  'Barbell Shrug',
  'Primary upper trap builder through scapular elevation.',
  'Hold barbell at arm''s length, shrug shoulders straight up, hold, lower.',
  ARRAY['Go straight up and down, no rolling','Hold top for 1-2 seconds','Use straps for heavy loads']::text[],
  ARRAY['Rolling shoulders','Using momentum','Bending elbows']::text[],
  'traps'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'barbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'wrist_curl',
  NULL,
  'Wrist Curl',
  'Isolation exercise for forearm flexors and grip strength.',
  'Rest forearms on thighs palms up, curl barbell with wrists only.',
  ARRAY['Keep forearms flat','Slow controlled reps','Try both grips']::text[],
  ARRAY['Lifting forearms','Using momentum','Going too heavy']::text[],
  'forearms'::muscle_group,
  '{}'::muscle_group[],
  'barbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '15-25',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'russian_twist',
  NULL,
  'Russian Twist',
  'Rotational core exercise for oblique development.',
  'Sit with knees bent, lean back, rotate torso side to side with weight.',
  ARRAY['Rotate from torso not arms','Keep chest up','Lift feet for more challenge']::text[],
  ARRAY['Moving only arms','Rounding back','Going too fast']::text[],
  'obliques'::muscle_group,
  ARRAY['core'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Hypertrophy']::text[],
  NULL,
  NULL,
  '15-20 per side',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'adductor_machine',
  NULL,
  'Adductor Machine',
  'Machine isolation for inner thigh adductors.',
  'Sit in adductor machine, squeeze legs together against resistance.',
  ARRAY['Squeeze from inner thigh','Slow controlled tempo','Full range of motion']::text[],
  ARRAY['Using momentum','Partial reps','Going too heavy']::text[],
  'adductors'::muscle_group,
  '{}'::muscle_group[],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'decline_bench_press',
  NULL,
  'Decline Bench Press',
  'Barbell press on a decline bench emphasizing the lower chest.',
  'Set bench to 15-30 degree decline, unrack bar, lower to lower chest, press to lockout. Keep feet secured under pads.',
  ARRAY['Use a spotter or safety pins','Keep shoulder blades retracted','Control the bar path to lower chest']::text[],
  ARRAY['Bouncing bar off chest','Setting decline too steep','Flaring elbows excessively']::text[],
  'chest'::muscle_group,
  ARRAY['triceps'::muscle_group,'shoulders'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_crossover',
  NULL,
  'Cable Crossover',
  'High-to-low cable movement for chest isolation with constant tension.',
  'Set pulleys to highest position, step forward, bring handles down and together in a hugging motion. Squeeze chest at the bottom.',
  ARRAY['Maintain a slight bend in elbows throughout','Step forward for a good stretch','Squeeze and hold at peak contraction']::text[],
  ARRAY['Bending arms too much turning it into a press','Using too much weight and losing form','Not controlling the eccentric']::text[],
  'chest'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'machine_chest_fly',
  NULL,
  'Machine Chest Fly',
  'Pec deck machine for controlled chest isolation.',
  'Sit with back flat against pad, grip handles at chest height, bring arms together in front of chest, return with control.',
  ARRAY['Keep a slight bend in elbows','Focus on squeezing pecs together','Use a slow eccentric for more tension']::text[],
  ARRAY['Setting seat too high or low','Using momentum','Not getting a full stretch at the back']::text[],
  'chest'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'diamond_push_up',
  NULL,
  'Diamond Push-Up',
  'Close-hand push-up variation emphasizing triceps and inner chest.',
  'Place hands close together forming a diamond shape under chest. Lower chest to hands and press back up, keeping elbows close to body.',
  ARRAY['Keep core braced throughout','Elbows should track backward not outward','Progress from knees if needed']::text[],
  ARRAY['Flaring elbows wide','Sagging hips','Not touching chest to hands']::text[],
  'chest'::muscle_group,
  ARRAY['triceps'::muscle_group,'shoulders'::muscle_group,'core'::muscle_group],
  'bodyweight'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Endurance']::text[],
  NULL,
  NULL,
  '8-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'tbar_row',
  NULL,
  'T-Bar Row',
  'Heavy compound rowing movement for mid-back thickness.',
  'Straddle the T-bar, hinge at hips, grip the handles, row the weight to your chest while keeping your back flat. Lower under control.',
  ARRAY['Keep chest up and back flat','Drive elbows past your torso','Use a neutral grip for best leverage']::text[],
  ARRAY['Rounding the lower back','Using too much body English','Standing too upright']::text[],
  'back'::muscle_group,
  ARRAY['biceps'::muscle_group,'lats'::muscle_group,'traps'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'chest_supported_row',
  NULL,
  'Chest-Supported Row',
  'Incline bench dumbbell row that eliminates lower back stress.',
  'Lie face down on an incline bench set to 30-45 degrees. Let dumbbells hang, row both to your ribcage, squeeze shoulder blades, lower slowly.',
  ARRAY['Let shoulders protract fully at the bottom for a stretch','Squeeze shoulder blades together at the top','Keep chest on the pad throughout']::text[],
  ARRAY['Lifting chest off the pad','Shrugging shoulders up','Using momentum']::text[],
  'back'::muscle_group,
  ARRAY['biceps'::muscle_group,'lats'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'hyperextension',
  NULL,
  'Hyperextension',
  'Lower back and posterior chain exercise using a Roman chair.',
  'Position hips on pad, cross arms over chest or behind head. Lower upper body toward floor, then extend back up to a straight line. Do not hyperextend.',
  ARRAY['Squeeze glutes at the top','Move slowly and controlled','Hold a plate at chest for added resistance']::text[],
  ARRAY['Hyperextending the spine past neutral','Rounding the back on the way down','Using momentum to swing up']::text[],
  'back'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'glutes'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Strength']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'good_morning',
  NULL,
  'Good Morning',
  'Barbell hip hinge for posterior chain strength and hamstring flexibility.',
  'Place barbell on upper back as in a squat. With a slight knee bend, hinge at hips and lower torso until nearly parallel to the floor. Drive hips forward to return.',
  ARRAY['Start with light weight to master the hinge','Keep back flat throughout','Push hips back, not down']::text[],
  ARRAY['Rounding the lower back','Bending knees too much','Going too heavy before mastering form']::text[],
  'hamstrings'::muscle_group,
  ARRAY['back'::muscle_group,'glutes'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'meadows_row',
  NULL,
  'Meadows Row',
  'Unilateral landmine row popularized by John Meadows for lat development.',
  'Stand perpendicular to a loaded landmine. Stagger stance with the inside foot forward. Grip the end of the bar with an overhand grip, row to hip, squeeze lat, lower with control.',
  ARRAY['Drive elbow behind your body','Allow a full stretch at the bottom','Use straps if grip is limiting']::text[],
  ARRAY['Rotating the torso excessively','Not getting a full stretch','Using too much bicep']::text[],
  'lats'::muscle_group,
  ARRAY['back'::muscle_group,'biceps'::muscle_group,'traps'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'straight_arm_pulldown',
  NULL,
  'Straight-Arm Pulldown',
  'Cable isolation for the lats without biceps involvement.',
  'Stand facing a high pulley with a straight bar. With arms nearly straight, pull the bar down in an arc to your thighs. Return slowly overhead.',
  ARRAY['Keep arms almost fully extended','Squeeze lats at the bottom','Lean slightly forward at the hips']::text[],
  ARRAY['Bending elbows too much','Using too much weight','Shrugging shoulders']::text[],
  'lats'::muscle_group,
  ARRAY['back'::muscle_group,'triceps'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'db_overhead_press',
  NULL,
  'Dumbbell Overhead Press',
  'Seated or standing dumbbell press for balanced shoulder development.',
  'Hold dumbbells at shoulder height with palms facing forward. Press overhead until arms are fully extended. Lower with control back to shoulder height.',
  ARRAY['Keep core tight to avoid excessive arching','Press in a slight arc, not straight out','Full range of motion from ears to lockout']::text[],
  ARRAY['Arching the back excessively','Not pressing to full lockout','Using legs to push the weight up']::text[],
  'shoulders'::muscle_group,
  ARRAY['triceps'::muscle_group,'core'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'arnold_press',
  NULL,
  'Arnold Press',
  'Rotational dumbbell press that hits all three deltoid heads.',
  'Start with dumbbells in front of shoulders, palms facing you. As you press up, rotate palms to face forward at the top. Reverse the motion on the way down.',
  ARRAY['Smooth rotation throughout the movement','Do not rush the rotation','Control the eccentric with the same rotation path']::text[],
  ARRAY['Rotating too early or too late','Using too much weight','Arching the lower back']::text[],
  'shoulders'::muscle_group,
  ARRAY['triceps'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_lateral_raise',
  NULL,
  'Cable Lateral Raise',
  'Constant-tension lateral raise using a low cable for medial deltoids.',
  'Stand sideways to a low pulley, grab the handle with the far hand. Raise arm out to the side to shoulder height, lower with control.',
  ARRAY['Lead with the elbow','Keep a slight bend in the elbow','Pause briefly at the top']::text[],
  ARRAY['Swinging the body','Raising above shoulder height','Going too fast']::text[],
  'shoulders'::muscle_group,
  ARRAY['traps'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'rear_delt_fly',
  NULL,
  'Rear Delt Fly',
  'Isolation exercise for posterior deltoids using dumbbells.',
  'Bend forward at the hips with dumbbells hanging below. Raise arms out to the sides, squeezing rear delts at the top. Lower slowly.',
  ARRAY['Keep torso stationary','Lead with elbows not hands','Use lighter weight for better mind-muscle connection']::text[],
  ARRAY['Using too much weight and swinging','Not hinging forward enough','Shrugging traps instead of squeezing rear delts']::text[],
  'shoulders'::muscle_group,
  ARRAY['traps'::muscle_group,'back'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'front_raise',
  NULL,
  'Front Raise',
  'Isolation exercise targeting the anterior deltoid.',
  'Hold dumbbells in front of thighs with palms facing you. Raise one or both arms to shoulder height, keeping arms nearly straight. Lower with control.',
  ARRAY['Avoid swinging the weight','Stop at shoulder height','Alternate arms to reduce fatigue']::text[],
  ARRAY['Using momentum','Raising too high above shoulder level','Leaning back']::text[],
  'shoulders'::muscle_group,
  ARRAY['chest'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'upright_row',
  NULL,
  'Upright Row',
  'Compound shoulder and trap exercise pulling the bar vertically.',
  'Hold barbell with a shoulder-width grip. Pull the bar up along your body to chin height, leading with elbows. Lower under control.',
  ARRAY['Use a wider grip to reduce shoulder impingement risk','Lead with elbows','Do not pull higher than your shoulders']::text[],
  ARRAY['Using too narrow a grip','Pulling too high causing impingement','Swinging the weight']::text[],
  'shoulders'::muscle_group,
  ARRAY['traps'::muscle_group,'biceps'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'preacher_curl',
  NULL,
  'Preacher Curl',
  'Strict biceps curl using a preacher bench to eliminate momentum.',
  'Sit at a preacher bench, rest upper arms on the pad. Curl the bar or dumbbells up, squeeze biceps at the top, lower slowly to full extension.',
  ARRAY['Do not lift elbows off the pad','Control the eccentric portion','Use a full range of motion']::text[],
  ARRAY['Cutting the range of motion short','Lifting elbows off the pad','Lowering too fast risking elbow strain']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'ez_bar'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'concentration_curl',
  NULL,
  'Concentration Curl',
  'Seated single-arm curl for peak biceps contraction.',
  'Sit on a bench, brace the back of your upper arm against your inner thigh. Curl the dumbbell up, squeeze at the top, lower under control.',
  ARRAY['Squeeze hard at the top for peak contraction','Keep your upper arm stationary against the thigh','Use a slow negative']::text[],
  ARRAY['Swinging the weight','Moving the upper arm','Using too much weight']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_curl',
  NULL,
  'Cable Curl',
  'Standing biceps curl with constant cable tension throughout the movement.',
  'Stand facing a low pulley with a straight or EZ bar attachment. Curl the bar to shoulder height keeping elbows pinned at your sides. Lower with control.',
  ARRAY['Keep elbows at your sides throughout','Squeeze at the top','Use a slow controlled tempo']::text[],
  ARRAY['Swinging the torso','Elbows drifting forward','Using too much weight']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'incline_db_curl',
  NULL,
  'Incline Dumbbell Curl',
  'Biceps curl on an incline bench that maximizes the stretched position.',
  'Sit on a bench set to 45-60 degrees. Let dumbbells hang at full extension with palms forward. Curl up without moving upper arms, lower to full stretch.',
  ARRAY['Let arms fully extend for a deep stretch','Keep upper arms perpendicular to the floor','Do not swing or use momentum']::text[],
  ARRAY['Swinging upper arms forward','Setting incline too steep','Not getting a full stretch at the bottom']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'ez_bar_curl',
  NULL,
  'EZ Bar Curl',
  'Biceps curl with an angled EZ bar that reduces wrist strain.',
  'Grip EZ bar on the angled portion at shoulder width. Stand tall and curl the bar up to shoulder height, keeping elbows stationary. Lower slowly.',
  ARRAY['Keep wrists in a neutral position on the angled grips','Avoid swinging the body','Squeeze at the top for one second']::text[],
  ARRAY['Swinging the body','Gripping too narrow or wide','Cutting range of motion short']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'ez_bar'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'spider_curl',
  NULL,
  'Spider Curl',
  'Prone incline curl that maximizes biceps tension in the shortened position.',
  'Lie face down on an incline bench set to about 45 degrees. Let arms hang straight down with dumbbells. Curl up, squeezing hard at the top, lower under control.',
  ARRAY['Keep upper arms vertical throughout','Squeeze and hold at the top','Use a slow tempo for more tension']::text[],
  ARRAY['Swinging the weights','Moving upper arms','Using too much weight']::text[],
  'biceps'::muscle_group,
  ARRAY['forearms'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'overhead_tricep_extension',
  NULL,
  'Overhead Tricep Extension',
  'Dumbbell or cable overhead extension for long head triceps development.',
  'Hold a dumbbell overhead with both hands. Lower it behind your head by bending at the elbows. Extend back to lockout, squeezing triceps.',
  ARRAY['Keep elbows close to your head','Full stretch at the bottom','Lock out fully at the top']::text[],
  ARRAY['Flaring elbows wide','Arching the lower back','Using momentum']::text[],
  'triceps'::muscle_group,
  ARRAY['shoulders'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'close_grip_bench',
  NULL,
  'Close-Grip Bench Press',
  'Bench press variation with narrow grip emphasizing triceps.',
  'Lie on a flat bench, grip the bar with hands shoulder-width or slightly narrower. Lower the bar to your lower chest keeping elbows tucked, press to lockout.',
  ARRAY['Hands should be shoulder-width, not touching','Keep elbows close to body','Focus on locking out with triceps']::text[],
  ARRAY['Grip too narrow causing wrist pain','Flaring elbows out','Bouncing off chest']::text[],
  'triceps'::muscle_group,
  ARRAY['chest'::muscle_group,'shoulders'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-10',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'tricep_kickback',
  NULL,
  'Tricep Kickback',
  'Dumbbell isolation exercise for triceps contraction.',
  'Hinge forward at hips, upper arm parallel to floor. Extend the dumbbell backward until arm is straight. Squeeze triceps, return slowly.',
  ARRAY['Keep upper arm completely still','Squeeze hard at full extension','Use lighter weight for strict form']::text[],
  ARRAY['Swinging the weight','Dropping the upper arm','Using momentum instead of triceps']::text[],
  'triceps'::muscle_group,
  '{}'::muscle_group[],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_overhead_extension',
  NULL,
  'Cable Overhead Tricep Extension',
  'Overhead triceps extension using a rope on a low cable for constant tension.',
  'Face away from a low pulley, hold rope overhead. Extend arms fully overhead by straightening elbows. Return behind head under control.',
  ARRAY['Keep elbows pointing forward','Step forward for stability','Full stretch at the bottom']::text[],
  ARRAY['Flaring elbows out','Arching the back','Using too much weight']::text[],
  'triceps'::muscle_group,
  '{}'::muscle_group[],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'front_squat',
  NULL,
  'Front Squat',
  'Barbell squat with the bar held on the front delts for more quad emphasis.',
  'Rest the barbell on your front deltoids in a clean grip or crossed-arm position. Squat down keeping torso very upright, drive up through your heels.',
  ARRAY['Keep elbows high throughout','Stay as upright as possible','Go to full depth if mobility allows']::text[],
  ARRAY['Elbows dropping causing the bar to roll forward','Leaning too far forward','Not bracing the core']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'core'::muscle_group,'hamstrings'::muscle_group],
  'barbell'::equipment_type,
  'advanced'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-10',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'hack_squat',
  NULL,
  'Hack Squat',
  'Machine squat variation that targets quads with back support.',
  'Position shoulders under pads, feet shoulder-width on the platform. Release the safeties and lower until thighs are parallel, press back up.',
  ARRAY['Place feet lower on platform for more quad emphasis','Do not lock knees at the top','Control the descent']::text[],
  ARRAY['Letting knees cave inward','Using too short a range of motion','Locking knees aggressively']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group],
  'machine'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'sissy_squat',
  NULL,
  'Sissy Squat',
  'Advanced bodyweight quad isolation that mimics a leg extension.',
  'Stand holding a support for balance. Lean your torso back while bending your knees, lowering yourself until your knees travel well forward and thighs are stretched. Push back up through your quads.',
  ARRAY['Hold something sturdy for balance','Keep hips extended throughout','Start with partial range and progress']::text[],
  ARRAY['Bending at the hips instead of keeping them extended','Going too deep too soon','Not using a support for balance']::text[],
  'quadriceps'::muscle_group,
  ARRAY['core'::muscle_group],
  'bodyweight'::equipment_type,
  'advanced'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '8-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'step_up',
  NULL,
  'Step-Up',
  'Unilateral leg exercise building strength and balance.',
  'Stand facing a bench or box at knee height. Step up with one foot, drive through the heel to stand on top, step back down. Alternate or complete one side.',
  ARRAY['Drive through the heel of the working leg','Keep torso upright','Use a height that allows full hip extension']::text[],
  ARRAY['Pushing off the back foot','Leaning too far forward','Using a box that is too high']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '8-12 per leg',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'bulgarian_split_squat',
  NULL,
  'Bulgarian Split Squat',
  'Single-leg squat with rear foot elevated for deep quad and glute work.',
  'Stand in a lunge position with your rear foot elevated on a bench behind you. Lower until your front thigh is parallel to the floor, drive up through the front heel.',
  ARRAY['Keep torso upright','Front shin can travel past the toe','Start with bodyweight to learn balance']::text[],
  ARRAY['Leaning too far forward','Standing too close to the bench','Rear foot bearing too much weight']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group],
  'dumbbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-12 per leg',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'nordic_curl',
  NULL,
  'Nordic Hamstring Curl',
  'Advanced bodyweight eccentric hamstring exercise for injury prevention and strength.',
  'Kneel on a pad with ankles secured. Slowly lower your body forward under control using your hamstrings to resist gravity. Push off the floor lightly to return to the start.',
  ARRAY['Control the descent as slowly as possible','Use hands to push off floor only as needed','Progress by increasing the range you can control']::text[],
  ARRAY['Falling forward uncontrolled','Bending at the hips instead of staying straight','Not securing ankles properly']::text[],
  'hamstrings'::muscle_group,
  ARRAY['glutes'::muscle_group,'calves'::muscle_group],
  'bodyweight'::equipment_type,
  'advanced'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','General Fitness']::text[],
  NULL,
  NULL,
  '3-8',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'stiff_leg_deadlift',
  NULL,
  'Stiff-Leg Deadlift',
  'Deadlift variation with minimal knee bend for maximum hamstring stretch.',
  'Hold a barbell with an overhand grip. With legs nearly straight, hinge at hips and lower the bar toward your feet. Return by driving hips forward.',
  ARRAY['Keep the bar close to your legs','Maintain a neutral spine','Feel a deep stretch in the hamstrings before reversing']::text[],
  ARRAY['Rounding the lower back','Locking knees completely','Going too heavy with poor form']::text[],
  'hamstrings'::muscle_group,
  ARRAY['glutes'::muscle_group,'back'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_pull_through',
  NULL,
  'Cable Pull-Through',
  'Cable hip hinge movement for glutes and hamstrings.',
  'Stand facing away from a low pulley, straddle the cable. Hinge at hips, reach through your legs, then drive hips forward to standing while squeezing glutes.',
  ARRAY['Drive the movement with your hips not your arms','Squeeze glutes hard at lockout','Keep arms straight throughout']::text[],
  ARRAY['Squatting instead of hinging','Pulling with the arms','Not squeezing glutes at the top']::text[],
  'hamstrings'::muscle_group,
  ARRAY['glutes'::muscle_group,'back'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'seated_leg_curl',
  NULL,
  'Seated Leg Curl',
  'Machine hamstring curl performed seated for constant tension.',
  'Sit in the machine with the pad on the back of your lower legs. Curl your legs down and back, squeezing hamstrings. Return slowly.',
  ARRAY['Adjust the back pad so you feel a good stretch','Squeeze at full contraction','Use a slow eccentric']::text[],
  ARRAY['Using momentum','Not adjusting the machine properly','Partial range of motion']::text[],
  'hamstrings'::muscle_group,
  ARRAY['calves'::muscle_group],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'glute_bridge',
  NULL,
  'Glute Bridge',
  'Floor-based glute activation exercise, great for warm-ups or high reps.',
  'Lie on your back, knees bent, feet flat on the floor. Drive hips up by squeezing glutes until body forms a straight line from shoulders to knees. Lower with control.',
  ARRAY['Squeeze glutes at the top for 2 seconds','Drive through your heels','Keep core engaged']::text[],
  ARRAY['Hyperextending the lower back','Pushing through toes instead of heels','Not squeezing at the top']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'core'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_glute_kickback',
  NULL,
  'Cable Glute Kickback',
  'Cable isolation exercise for glutes using an ankle strap.',
  'Attach an ankle strap to a low pulley. Face the machine, kick your leg straight back, squeezing your glute at the top. Return slowly.',
  ARRAY['Keep your core tight and avoid arching your back','Squeeze at full hip extension','Use a controlled tempo']::text[],
  ARRAY['Arching the lower back','Using momentum to swing the leg','Leaning too far forward']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-15 per leg',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'sumo_deadlift',
  NULL,
  'Sumo Deadlift',
  'Wide-stance deadlift variation emphasizing glutes and inner thighs.',
  'Take a wide stance with toes pointed out. Grip the bar between your legs with arms straight. Drive through heels, extending hips and knees to stand tall.',
  ARRAY['Push knees out over toes','Keep chest up and back flat','Drive hips to the bar at lockout']::text[],
  ARRAY['Hips shooting up too fast','Knees caving inward','Rounding the upper back']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'quadriceps'::muscle_group,'back'::muscle_group,'adductors'::muscle_group],
  'barbell'::equipment_type,
  'advanced'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '3-8',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'donkey_kick',
  NULL,
  'Donkey Kick',
  'Bodyweight glute isolation performed on all fours.',
  'Get on all fours, keeping core tight. Kick one leg up and back, driving heel toward the ceiling until hip is fully extended. Lower with control.',
  ARRAY['Keep core braced to prevent arching','Squeeze glute at the top','Use an ankle weight or band for added resistance']::text[],
  ARRAY['Arching the lower back','Using momentum','Not achieving full hip extension']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'core'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20 per leg',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'seated_calf_raise',
  NULL,
  'Seated Calf Raise',
  'Calf raise performed seated to target the soleus muscle.',
  'Sit in the seated calf raise machine with knees under the pad. Raise heels as high as possible, pause at the top, lower with a full stretch at the bottom.',
  ARRAY['Hold the top position for 1-2 seconds','Get a full stretch at the bottom','Use a slow controlled tempo']::text[],
  ARRAY['Bouncing the weight','Partial range of motion','Going too heavy with no control']::text[],
  'calves'::muscle_group,
  '{}'::muscle_group[],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'single_leg_calf_raise',
  NULL,
  'Single-Leg Calf Raise',
  'Unilateral calf raise for balanced calf development.',
  'Stand on one foot on the edge of a step, holding something for balance. Lower heel below the step for a full stretch, then raise as high as possible.',
  ARRAY['Pause at the top for peak contraction','Full range of motion is key','Hold a dumbbell for added resistance']::text[],
  ARRAY['Bouncing through reps','Not getting a full stretch at the bottom','Rushing the tempo']::text[],
  'calves'::muscle_group,
  '{}'::muscle_group[],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20 per leg',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'donkey_calf_raise',
  NULL,
  'Donkey Calf Raise',
  'Calf raise performed in a bent-over position for a greater stretch on the gastrocnemius.',
  'Bend forward at the hips with hands on a support, toes on a raised surface. Lower heels for a deep stretch, then raise as high as possible.',
  ARRAY['Keep legs nearly straight for maximum gastrocnemius activation','Use a partner or machine for added load','Slow and controlled reps']::text[],
  ARRAY['Bending knees too much','Bouncing at the bottom','Partial range of motion']::text[],
  'calves'::muscle_group,
  '{}'::muscle_group[],
  'bodyweight'::equipment_type,
  'intermediate'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'cable_woodchop',
  NULL,
  'Cable Woodchop',
  'Rotational core exercise using a cable for obliques and overall core stability.',
  'Set cable to high position. Stand sideways, grip handle with both hands, rotate torso diagonally down and across your body. Return with control.',
  ARRAY['Rotate from the core not the arms','Keep arms extended throughout','Control the return phase']::text[],
  ARRAY['Pulling with the arms instead of rotating','Moving too fast','Not bracing the core']::text[],
  'obliques'::muscle_group,
  ARRAY['core'::muscle_group,'shoulders'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '10-15 per side',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'dead_bug',
  NULL,
  'Dead Bug',
  'Anti-extension core exercise for deep core stability and coordination.',
  'Lie on your back with arms extended toward ceiling and knees bent at 90 degrees. Simultaneously lower one arm behind your head and extend the opposite leg, keeping your lower back flat. Return and alternate.',
  ARRAY['Press your lower back into the floor throughout','Move slowly and with control','Exhale as you extend']::text[],
  ARRAY['Letting the lower back arch off the floor','Moving too fast','Not coordinating opposite arm and leg']::text[],
  'core'::muscle_group,
  ARRAY['hip_flexors'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness']::text[],
  NULL,
  NULL,
  '8-12 per side',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'hanging_leg_raise',
  NULL,
  'Hanging Leg Raise',
  'Advanced core exercise performed hanging from a pull-up bar.',
  'Hang from a pull-up bar with arms straight. Raise your legs together until they are parallel to the floor or higher. Lower with control.',
  ARRAY['Avoid swinging by bracing your core before lifting','Curl your pelvis up at the top for more ab activation','Bend knees to make it easier']::text[],
  ARRAY['Using momentum to swing legs up','Not controlling the descent','Only lifting from hip flexors without curling pelvis']::text[],
  'core'::muscle_group,
  ARRAY['hip_flexors'::muscle_group,'obliques'::muscle_group],
  'bodyweight'::equipment_type,
  'advanced'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'bicycle_crunch',
  NULL,
  'Bicycle Crunch',
  'Dynamic core exercise combining rotation and flexion for abs and obliques.',
  'Lie on your back, hands behind head. Bring one knee toward your chest while rotating the opposite elbow to meet it. Alternate sides in a pedaling motion.',
  ARRAY['Rotate from the thoracic spine','Do not pull on your neck','Extend the straight leg fully']::text[],
  ARRAY['Pulling the neck with hands','Moving too fast with no control','Not fully rotating the torso']::text[],
  'core'::muscle_group,
  ARRAY['obliques'::muscle_group,'hip_flexors'::muscle_group],
  'bodyweight'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Hypertrophy']::text[],
  NULL,
  NULL,
  '15-20 per side',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'pallof_press',
  NULL,
  'Pallof Press',
  'Anti-rotation core exercise using a cable for functional core stability.',
  'Stand sideways to a cable machine at chest height. Hold the handle at your chest, then press it straight out in front of you. Hold briefly, return to chest. Resist the rotational pull.',
  ARRAY['Brace your core and resist rotation','Press slowly and hold at full extension','Stand with feet shoulder-width apart for stability']::text[],
  ARRAY['Allowing the cable to rotate your torso','Standing too close to the machine','Not bracing the core']::text[],
  'core'::muscle_group,
  ARRAY['obliques'::muscle_group,'shoulders'::muscle_group],
  'cable'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Strength']::text[],
  NULL,
  NULL,
  '10-12 per side',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'ab_wheel_rollout',
  NULL,
  'Ab Wheel Rollout',
  'Advanced anti-extension core exercise using an ab wheel.',
  'Kneel on the floor gripping the ab wheel handles. Roll the wheel forward, extending your body as far as you can while keeping your core braced. Pull back to the starting position using your abs.',
  ARRAY['Tuck your pelvis and brace core before rolling out','Only go as far as you can control','Exhale on the way back']::text[],
  ARRAY['Letting the lower back sag','Going too far out and collapsing','Using hip flexors to pull back instead of abs']::text[],
  'core'::muscle_group,
  ARRAY['shoulders'::muscle_group,'lats'::muscle_group],
  'bodyweight'::equipment_type,
  'advanced'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '6-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'db_shrug',
  NULL,
  'Dumbbell Shrug',
  'Trap isolation using dumbbells for a greater range of motion than a barbell.',
  'Hold dumbbells at your sides. Shrug your shoulders straight up toward your ears, hold for one second, lower with control.',
  ARRAY['Go straight up, do not roll shoulders','Hold at the top for a full contraction','Use straps if grip is limiting']::text[],
  ARRAY['Rolling the shoulders','Using too much momentum','Bending the elbows']::text[],
  'traps'::muscle_group,
  ARRAY['shoulders'::muscle_group,'forearms'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'farmers_walk',
  NULL,
  'Farmer''s Walk',
  'Loaded carry for traps, grip strength, core stability, and overall conditioning.',
  'Pick up heavy dumbbells or farmer''s walk handles. Stand tall and walk with controlled steps for distance or time, keeping shoulders back and core braced.',
  ARRAY['Keep shoulders back and down','Brace core as if bracing for a punch','Take short controlled steps']::text[],
  ARRAY['Letting shoulders round forward','Taking steps that are too long','Holding breath instead of breathing controlled']::text[],
  'traps'::muscle_group,
  ARRAY['forearms'::muscle_group,'core'::muscle_group,'shoulders'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','General Fitness']::text[],
  NULL,
  NULL,
  '30-60s or 40m',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'reverse_curl',
  NULL,
  'Reverse Curl',
  'Overhand grip curl for brachioradialis and forearm extensor development.',
  'Hold a barbell or EZ bar with an overhand grip at shoulder width. Curl the bar up keeping elbows at your sides, lower with control.',
  ARRAY['Keep wrists straight','Use a lighter weight than regular curls','Squeeze forearms at the top']::text[],
  ARRAY['Using too much weight','Swinging the body','Letting wrists bend backward']::text[],
  'forearms'::muscle_group,
  ARRAY['biceps'::muscle_group],
  'ez_bar'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'reverse_wrist_curl',
  NULL,
  'Reverse Wrist Curl',
  'Wrist extension exercise for forearm extensor development.',
  'Rest forearms on thighs or a bench with palms facing down. Extend wrists upward by curling the back of your hands toward you. Lower slowly.',
  ARRAY['Use very light weight','Full range of motion','Control every rep']::text[],
  ARRAY['Going too heavy','Using momentum','Not securing forearms on the support']::text[],
  'forearms'::muscle_group,
  '{}'::muscle_group[],
  'barbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '15-25',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'abductor_machine',
  NULL,
  'Hip Abductor Machine',
  'Machine isolation for outer hip and glute medius.',
  'Sit in the abductor machine with pads on the outside of your knees. Push legs apart against the resistance, hold briefly, return with control.',
  ARRAY['Squeeze at full abduction','Control the return phase','Lean slightly forward for more glute medius activation']::text[],
  ARRAY['Using momentum','Letting legs snap back together','Not using full range of motion']::text[],
  'abductors'::muscle_group,
  ARRAY['glutes'::muscle_group],
  'machine'::equipment_type,
  'beginner'::exercise_difficulty,
  'isolation'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','General Fitness']::text[],
  NULL,
  NULL,
  '12-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'kettlebell_swing',
  NULL,
  'Kettlebell Swing',
  'Explosive hip hinge movement for posterior chain power and conditioning.',
  'Stand with feet wider than shoulder width, kettlebell on the floor in front. Hike the bell back between your legs, then drive hips forward explosively to swing the bell to chest height. Let it swing back and repeat.',
  ARRAY['Power comes from the hips, not the arms','Squeeze glutes hard at the top','Maintain a flat back throughout']::text[],
  ARRAY['Squatting instead of hinging','Lifting with the arms','Rounding the lower back']::text[],
  'glutes'::muscle_group,
  ARRAY['hamstrings'::muscle_group,'core'::muscle_group,'shoulders'::muscle_group,'back'::muscle_group],
  'kettlebell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Strength','Endurance']::text[],
  NULL,
  NULL,
  '10-20',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'trap_bar_deadlift',
  NULL,
  'Trap Bar Deadlift',
  'Deadlift variation using a hex bar for a more quad-dominant and back-friendly pull.',
  'Stand inside the trap bar, grip the handles, and stand up by driving through your feet. Keep your chest up and back flat throughout. Lower under control.',
  ARRAY['Push the floor away rather than pulling the bar','Keep chest up','Grip the high handles to start, low handles for more range']::text[],
  ARRAY['Rounding the back','Locking out knees before hips','Not standing all the way up']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'hamstrings'::muscle_group,'back'::muscle_group,'traps'::muscle_group,'forearms'::muscle_group],
  'trap_bar'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-10',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'chin_up',
  NULL,
  'Chin-Up',
  'Underhand pull-up variation emphasizing biceps and lower lats.',
  'Grip the bar with palms facing you at shoulder width. Pull yourself up until chin clears the bar. Lower under control to a full dead hang.',
  ARRAY['Initiate by depressing and retracting shoulder blades','Full dead hang at the bottom','Keep core braced to avoid swinging']::text[],
  ARRAY['Half reps','Kipping or swinging','Not going to full extension at the bottom']::text[],
  'lats'::muscle_group,
  ARRAY['biceps'::muscle_group,'back'::muscle_group,'forearms'::muscle_group],
  'bodyweight'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Strength','Hypertrophy']::text[],
  NULL,
  NULL,
  '5-12',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'goblet_squat',
  NULL,
  'Goblet Squat',
  'Beginner-friendly squat holding a dumbbell or kettlebell at chest level.',
  'Hold a dumbbell vertically at chest height with both hands. Squat down keeping your elbows between your knees, go to full depth, drive up through heels.',
  ARRAY['Keep the weight close to your chest','Use elbows to push knees out at the bottom','Keep torso as upright as possible']::text[],
  ARRAY['Leaning too far forward','Not going deep enough','Letting knees cave inward']::text[],
  'quadriceps'::muscle_group,
  ARRAY['glutes'::muscle_group,'core'::muscle_group],
  'dumbbell'::equipment_type,
  'beginner'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['General Fitness','Hypertrophy']::text[],
  NULL,
  NULL,
  '10-15',
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO exercises (
  id, user_id, name, description, instructions,
  tips, common_mistakes, primary_muscle, secondary_muscles,
  equipment, difficulty, category,
  video_url, image_url, best_for_goals,
  setup_instructions, safety_tips, suggested_rep_range,
  is_custom
) VALUES (
  'landmine_press',
  NULL,
  'Landmine Press',
  'Angled pressing movement using a barbell in a landmine for shoulder-friendly pressing.',
  'Hold the end of a barbell anchored in a landmine at shoulder height. Press the bar up and forward at an angle until your arm is fully extended. Lower with control.',
  ARRAY['Stagger your stance for stability','Press at an angle, not straight up','Keep core braced throughout']::text[],
  ARRAY['Leaning back too much','Pressing straight up instead of at an angle','Not bracing the core']::text[],
  'shoulders'::muscle_group,
  ARRAY['chest'::muscle_group,'triceps'::muscle_group,'core'::muscle_group],
  'barbell'::equipment_type,
  'intermediate'::exercise_difficulty,
  'compound'::exercise_category,
  NULL,
  NULL,
  ARRAY['Hypertrophy','Strength']::text[],
  NULL,
  NULL,
  '8-12',
  false
) ON CONFLICT (id) DO NOTHING;

COMMIT;