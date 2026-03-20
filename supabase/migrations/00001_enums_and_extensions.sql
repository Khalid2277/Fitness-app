-- 00001_enums_and_extensions.sql
-- Create extensions and all custom enum types for AlfaNutrition

-- ============================================================
-- Extensions
-- ============================================================
create extension if not exists "uuid-ossp" with schema public;
create extension if not exists "pgcrypto" with schema public;

-- ============================================================
-- Enum Types
-- ============================================================

create type muscle_group as enum (
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'forearms',
  'quadriceps',
  'hamstrings',
  'glutes',
  'calves',
  'core',
  'traps',
  'lats',
  'obliques',
  'hip_flexors',
  'adductors',
  'abductors'
);

create type equipment_type as enum (
  'barbell',
  'dumbbell',
  'cable',
  'machine',
  'bodyweight',
  'kettlebell',
  'resistance_band',
  'smith_machine',
  'ez_bar',
  'trap_bar'
);

create type exercise_difficulty as enum (
  'beginner',
  'intermediate',
  'advanced'
);

create type exercise_category as enum (
  'compound',
  'isolation'
);

create type meal_type as enum (
  'breakfast',
  'lunch',
  'dinner',
  'snack'
);

create type workout_goal as enum (
  'fat_loss',
  'hypertrophy',
  'strength',
  'general_fitness',
  'endurance'
);

create type experience_level as enum (
  'beginner',
  'intermediate',
  'advanced'
);

create type split_type as enum (
  'push_pull_legs',
  'upper_lower',
  'bro_split',
  'full_body',
  'arnold_split',
  'custom'
);

create type gender_type as enum (
  'male',
  'female',
  'other'
);

create type activity_level as enum (
  'sedentary',
  'lightly_active',
  'moderately_active',
  'very_active',
  'extremely_active'
);

create type food_category as enum (
  'protein',
  'dairy',
  'grains',
  'fruits',
  'vegetables',
  'fats',
  'beverages',
  'snacks',
  'meals',
  'custom'
);

-- ============================================================
-- Helper: auto-update updated_at trigger function
-- ============================================================
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;
