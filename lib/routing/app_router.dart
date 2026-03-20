import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/routing/app_shell.dart';
import 'package:alfanutrition/features/auth/screens/auth_screen.dart';
import 'package:alfanutrition/features/home/screens/home_screen.dart';
import 'package:alfanutrition/features/workouts/screens/workouts_screen.dart';
import 'package:alfanutrition/features/workouts/screens/workout_detail_screen.dart';
import 'package:alfanutrition/features/workouts/screens/active_workout_screen.dart';
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/features/nutrition/screens/nutrition_screen.dart';
import 'package:alfanutrition/features/nutrition/screens/add_meal_screen.dart';
import 'package:alfanutrition/features/nutrition/screens/barcode_scan_screen.dart';
import 'package:alfanutrition/features/nutrition/screens/create_meal_screen.dart';
import 'package:alfanutrition/features/muscles/screens/muscles_screen.dart';
import 'package:alfanutrition/features/progress/screens/progress_screen.dart';
import 'package:alfanutrition/features/exercises/screens/exercise_library_screen.dart';
import 'package:alfanutrition/features/exercises/screens/exercise_detail_screen.dart';
import 'package:alfanutrition/features/plans/screens/plans_screen.dart';
import 'package:alfanutrition/features/plans/screens/generate_plan_screen.dart';
import 'package:alfanutrition/features/plans/screens/plan_detail_screen.dart';
import 'package:alfanutrition/features/profile/screens/profile_screen.dart';
import 'package:alfanutrition/features/profile/screens/edit_profile_screen.dart';
import 'package:alfanutrition/features/progress/screens/add_body_metric_screen.dart';
import 'package:alfanutrition/features/progress/screens/progress_photos_screen.dart';
import 'package:alfanutrition/features/progress/screens/capture_progress_photo_screen.dart';
import 'package:alfanutrition/features/progress/screens/body_analysis_screen.dart';
import 'package:alfanutrition/features/progress/screens/photo_set_detail_screen.dart';
import 'package:alfanutrition/features/onboarding/screens/onboarding_screen.dart';
import 'package:alfanutrition/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:alfanutrition/features/reminders/screens/reminders_screen.dart';
import 'package:alfanutrition/features/splash/screens/splash_screen.dart';
import 'package:alfanutrition/features/workouts/screens/workout_calendar_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // Let splash screen play without redirect
    if (state.matchedLocation == '/splash') return null;

    // If Supabase is not configured, skip auth (offline/dev mode)
    if (!SupabaseConfig.isConfigured) {
      if (state.matchedLocation == '/auth') return '/onboarding';
      return null;
    }

    final isAuthenticated =
        Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (!isAuthenticated && !isAuthRoute) return '/auth';
    if (isAuthenticated && isAuthRoute) return '/onboarding';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/nutrition',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NutritionScreen(),
          ),
        ),
        GoRoute(
          path: '/workouts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkoutsScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/ai-coach',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiCoachScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/muscles',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MusclesScreen(),
    ),
    GoRoute(
      path: '/workout/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => WorkoutDetailScreen(
        workoutId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/active-workout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ActiveWorkoutScreen(),
    ),
    GoRoute(
      path: '/add-meal',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // If a Meal is passed as extra, open in edit mode
        final meal = state.extra;
        if (meal is Meal) {
          return AddMealScreen(editingMeal: meal);
        }
        return const AddMealScreen();
      },
    ),
    GoRoute(
      path: '/barcode-scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BarcodeScanScreen(),
    ),
    GoRoute(
      path: '/create-meal',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateMealScreen(),
    ),
    GoRoute(
      path: '/exercises',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExerciseLibraryScreen(),
    ),
    GoRoute(
      path: '/exercise/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ExerciseDetailScreen(
        exerciseId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/plans',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PlansScreen(),
    ),
    GoRoute(
      path: '/generate-plan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GeneratePlanScreen(),
    ),
    GoRoute(
      path: '/plan/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PlanDetailScreen(
        planId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/add-body-metric',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddBodyMetricScreen(),
    ),
    GoRoute(
      path: '/progress-photos',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProgressPhotosScreen(),
    ),
    GoRoute(
      path: '/capture-progress-photo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CaptureProgressPhotoScreen(),
    ),
    GoRoute(
      path: '/photo-set/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PhotoSetDetailScreen(
        photoSetId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/body-analysis/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BodyAnalysisScreen(
        photoSetId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/workout-calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WorkoutCalendarScreen(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemindersScreen(),
    ),
  ],
);
