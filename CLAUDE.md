# AlfaNutrition - Project Guidance

## What This Is

AlfaNutrition is a production-quality iOS fitness tracking app built with Flutter. It covers calorie/nutrition logging, workout tracking, body metrics, workout plan generation, muscle analysis, an interactive body map, and a full exercise library with 90+ exercises.

## Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter 3.x (Dart 3.11+) | iOS-first, Material 3 |
| State management | flutter_riverpod 2.x | Providers, FutureProviders, StateNotifiers |
| Navigation | go_router 14.x | ShellRoute for tab nav, standalone routes for modals |
| Local storage | Hive (hive_flutter) | All models stored as `Map<String, dynamic>` (no codegen) |
| Charts | fl_chart | Weight trends, macro bars |
| Animations | flutter_animate | Entrance animations, transitions |
| UI helpers | percent_indicator, shimmer, flutter_svg | Calorie rings, loading states |

## Architecture

**Feature-first folder structure.** Each feature is self-contained:

```
lib/
  core/              # Shared design system and utilities
    constants/       # AppConstants (targets, durations, limits)
    theme/           # AppColors, AppSpacing, AppTextStyles, AppTheme
    widgets/         # Reusable widgets (AppCard, EmptyState, MetricCard, etc.)
  data/              # Data layer (shared across features)
    models/          # Hive-backed models with manual TypeAdapters
    repositories/    # CRUD operations over Hive boxes
    seed/            # Exercise database (90 exercises)
    services/        # Business logic (muscle analysis, plan generator, video)
  features/          # Feature modules
    exercises/       # Exercise library, detail screen, search/filter
    home/            # Dashboard with calorie ring, macros, weekly dots
    muscles/         # Interactive body map + muscle analysis
    nutrition/       # Calorie & macro tracking, add meal
    onboarding/      # 4-step first-run setup wizard
    plans/           # Workout plan generator (5 split types)
    profile/         # User profile, settings, theme toggle
    progress/        # Weight chart, body metrics, PRs, stats
    workouts/        # Workout logging, active workout, history
  routing/           # GoRouter config + AppShell (bottom nav)
  main.dart          # Entry point
```

### Feature Module Structure

Every feature folder follows this structure:
```
features/<name>/
  providers/     # Riverpod providers for this feature
  screens/       # Full-page screens (ConsumerWidget or ConsumerStatefulWidget)
  widgets/       # Feature-specific widgets (private or public)
```

## Key Conventions

### Naming
- **Files:** `snake_case.dart` always
- **Classes:** `PascalCase` — screens end with `Screen`, widgets are descriptive (`CalorieRingCard`, `MacroBar`)
- **Providers:** `camelCaseProvider` — e.g. `workoutHistoryProvider`, `dailyNutritionProvider`
- **Private widgets:** Prefixed with `_` and defined in the same file as their parent screen
- **Repositories:** `<Name>Repository` — one per Hive box
- **Services:** `<Name>Service` — business logic, no UI dependency

### State Management Patterns
- **Read-only data:** `FutureProvider` (loads from Hive repository)
- **Mutable app state:** `StateNotifierProvider` (e.g. `activeWorkoutProvider`, `themeModeProvider`)
- **Simple toggles/selections:** `StateProvider` (e.g. `selectedDateProvider`, `selectedMuscleProvider`)
- **Static/computed data:** `Provider` (e.g. `quickFoodsProvider`, `exerciseListProvider`)
- **Refreshing data:** Call `ref.invalidate(provider)` — never manually refetch
- **Cross-feature providers:** Import from the canonical feature. Never duplicate provider definitions across features.

### Models & Storage
- All Hive models use **manual TypeAdapters** (no build_runner / code generation)
- TypeIds 0-18 are assigned — next available is **19**
- Models have `toJson()` / `fromJson()` for repository serialization
- Repositories store raw `Map<String, dynamic>` — no generated adapters needed
- Hive box names are in `AppConstants` (workouts, meals, bodyMetrics, plans, userProfile, exercises)

### Navigation
- **Onboarding:** `/onboarding` is the initial route. It checks for an existing profile and redirects to `/home` if found.
- **Tab routes** (`/home`, `/workouts`, `/nutrition`, `/muscles`, `/progress`) live inside `ShellRoute` with `AppShell` providing the bottom nav bar
- **Modal/detail routes** (`/active-workout`, `/add-meal`, `/exercise/:id`, `/profile`, etc.) use `parentNavigatorKey: _rootNavigatorKey` to push above the tab bar
- Use `context.go()` for tab switches, `context.push()` for stacked screens, `context.pop()` to go back

### Design System — Non-Negotiable Rules
- **Never hardcode colors.** Use `AppColors.*` or `Theme.of(context).colorScheme.*`
- **Never hardcode spacing.** Use `AppSpacing.*` constants
- **Never hardcode text styles.** Use `theme.textTheme.*` (displaySmall, titleLarge, bodyMedium, labelSmall, etc.)
- **Dark mode:** Every widget must handle `isDark = theme.brightness == Brightness.dark` — use ternaries for surfaces, shadows, and tints
- **Card pattern:** `Container` with `theme.colorScheme.surface` background, `AppSpacing.borderRadiusLg`, and `AppColors.cardShadowLight/Dark`
- **Screen padding:** `AppSpacing.screenPadding` (20px horizontal) for all full-width content
- **Card padding:** `AppSpacing.cardPadding` (16px all sides)
- **Animations:** Use `flutter_animate` for entrance effects. Standard pattern: `.animate().fadeIn(duration: 400.ms).slideY(begin: 0.05)`
- **Muscle colors:** Use `AppColors.colorForMuscle(MuscleGroup)` — never define local `_muscleColor` helpers
- **Gradient buttons:** Use `DecoratedBox` with `AppColors.primaryGradient` wrapping a transparent `ElevatedButton`
- **Selection cards:** Use `AnimatedContainer` with border, shadow, and color transitions on selection state

### Key Color Tokens
| Token | Use |
|---|---|
| `AppColors.primaryBlue` | Primary actions, protein bars, interactive elements |
| `AppColors.accent` | Teal — success states, carbs, secondary CTAs |
| `AppColors.warning` | Orange — fats, streaks, caution states |
| `AppColors.success` | Green — positive feedback, fiber, plans icon |
| `AppColors.error` | Red — destructive actions, over-limit states |
| `AppColors.muscleGlutes` | Pink — used for fats in some contexts |
| `AppColors.primaryGradient` | Primary CTA gradient (blue to purple) |
| `AppColors.surfaceLight` / `surfaceDark1` | Card backgrounds |
| `AppColors.backgroundLight` / `backgroundDark` | Screen backgrounds |
| `AppColors.dividerLight` / `dividerDark` | Card borders, dividers |
| `AppColors.textSecondaryLight` / `textSecondaryDark` | Subtitles, descriptions |
| `AppColors.textTertiaryLight` / `textTertiaryDark` | Hints, inactive states |
| `AppColors.cardShadowLight` / `cardShadowDark` | Card drop shadows |

### Key Spacing Tokens
| Token | Value |
|---|---|
| `AppSpacing.xs` | 4px |
| `AppSpacing.sm` | 8px |
| `AppSpacing.md` | 12px |
| `AppSpacing.lg` | 16px |
| `AppSpacing.xl` | 20px |
| `AppSpacing.xxl` | 24px |
| `AppSpacing.xxxl` | 32px |
| `AppSpacing.xxxxl` | 40px |
| `AppSpacing.borderRadiusSm` | 8px radius |
| `AppSpacing.borderRadiusMd` | 12px radius |
| `AppSpacing.borderRadiusLg` | 16px radius |
| `AppSpacing.borderRadiusXl` | 20px radius |
| `AppSpacing.borderRadiusPill` | 100px radius |
| `AppSpacing.screenPadding` | EdgeInsets.symmetric(horizontal: 20) |
| `AppSpacing.cardPadding` | EdgeInsets.all(16) |

### Reusable Core Widgets
Before creating new widgets, check if these exist in `lib/core/widgets/`:
| Widget | Use |
|---|---|
| `AppCard` | Standard card with optional gradient header, shadows, onTap |
| `MetricCard` | Metric display with value, unit, trend indicator |
| `SectionHeader` | Section title with optional "See All" button |
| `EmptyState` | Centered empty view with icon, title, subtitle, CTA |
| `ShimmerLoading` | Factory constructors for card, list, and metric skeletons |
| `ProgressRing` | Animated circular progress with gradient stroke |
| `AlfaNutritionAppBar` | Custom app bar with title/subtitle and actions |

## Build Instructions

The project lives on an iCloud-synced Desktop which breaks iOS codesigning due to `com.apple.fileprovider` extended attributes. To build:

```bash
# Sync to a non-iCloud location
rsync -a --delete /Users/khalid/Desktop/Fitness_app/ /tmp/AlfaNutrition/
xattr -cr /tmp/AlfaNutrition

# Build for simulator
cd /tmp/AlfaNutrition && flutter build ios --debug --simulator

# Or run directly
cd /tmp/AlfaNutrition && flutter run -d <simulator-id>

# Install to already-booted simulator
xcrun simctl install <device-id> /tmp/AlfaNutrition/build/ios/iphonesimulator/Runner.app
xcrun simctl launch <device-id> com.alfatechlabs.nutrition
```

For device builds, open `ios/Runner.xcworkspace` in Xcode and set your signing team first.

## Adding a New Feature

1. Create folder: `lib/features/<name>/` with `providers/`, `screens/`, `widgets/` subdirs
2. Define providers in `providers/<name>_providers.dart`
3. Build screens as `ConsumerWidget` or `ConsumerStatefulWidget`
4. Add route in `lib/routing/app_router.dart`:
   - Tab route: inside `ShellRoute.routes` with `NoTransitionPage`
   - Detail route: standalone `GoRoute` with `parentNavigatorKey: _rootNavigatorKey`
5. Use existing `core/widgets/` (AppCard, EmptyState, SectionHeader, etc.) before creating new ones
6. Add entrance animations using `flutter_animate` (fadeIn + slideY)
7. Handle empty, loading, and error states
8. Test both light and dark mode

## Adding a New Model

1. Create in `lib/data/models/<name>.dart`
2. Assign the next available Hive `typeId` (currently **19**)
3. Write a manual `TypeAdapter` class (no codegen)
4. Include `toJson()`, `fromJson()`, and `copyWith()`
5. Register the adapter in `lib/data/services/storage_service.dart`
6. Create a repository in `lib/data/repositories/` if CRUD is needed
7. Update this file's typeId counter after adding

## Adding a New Exercise

Add to `lib/data/seed/exercise_database.dart`. Follow the exact pattern:
```dart
Exercise(
  id: 'unique-id',
  name: 'Exercise Name',
  primaryMuscle: MuscleGroup.chest,
  secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
  equipment: EquipmentType.barbell,
  difficulty: ExerciseDifficulty.intermediate,
  category: ExerciseCategory.compound,
  instructions: 'Step-by-step instructions...',
  tips: ['Tip 1', 'Tip 2', 'Tip 3'],
  commonMistakes: ['Mistake 1', 'Mistake 2'],
  safetyTips: 'Safety guidance...',
  recommendedRepRange: '8-12',
  bestFor: 'Hypertrophy',
  videoUrl: null, // Or a curated YouTube URL
),
```

## Existing Route Map

| Path | Screen | Type |
|---|---|---|
| `/onboarding` | OnboardingScreen | Standalone (initial) |
| `/home` | HomeScreen | Tab |
| `/workouts` | WorkoutsScreen | Tab |
| `/nutrition` | NutritionScreen | Tab |
| `/muscles` | MusclesScreen | Tab |
| `/progress` | ProgressScreen | Tab |
| `/workout/:id` | WorkoutDetailScreen | Modal |
| `/active-workout` | ActiveWorkoutScreen | Modal |
| `/add-meal` | AddMealScreen | Modal |
| `/exercises` | ExerciseLibraryScreen | Modal |
| `/exercise/:id` | ExerciseDetailScreen | Modal |
| `/plans` | PlansScreen | Modal |
| `/generate-plan` | GeneratePlanScreen | Modal |
| `/plan/:id` | PlanDetailScreen | Modal |
| `/profile` | ProfileScreen | Modal |
| `/add-body-metric` | AddBodyMetricScreen | Modal |

## Future Integration Points

These are architected but not yet connected to real backends:

| Feature | Current | Future |
|---|---|---|
| Food search | Quick-add presets only | Food API (Nutritionix, OpenFoodFacts) + barcode scanning |
| Exercise videos | Curated YouTube links via `VideoService` | YouTube Data API search or custom video hosting |
| Backend sync | Hive local only | REST API / Firebase with repository swap |
| Progress photos | Placeholder support | Camera + local gallery storage |
| Social/sharing | Not implemented | Share workout summaries, challenge friends |
| Rest timer | Placeholder in active workout | Local notifications + background timer |

The repository/service layer is designed so you can swap implementations without touching UI code. `VideoService` has an abstract base class with `CuratedVideoService` (current) and `YouTubeVideoService` (stub) implementations.

## Quality Checklist (Before Shipping Any Change)

- [ ] `flutter analyze` shows 0 errors, 0 warnings
- [ ] No hardcoded colors, spacing, or text styles
- [ ] Dark mode works (check `isDark` ternaries)
- [ ] Empty states are handled (no blank screens)
- [ ] Loading states use shimmer or CircularProgressIndicator
- [ ] Error states show user-friendly messages
- [ ] Entrance animations are present but subtle
- [ ] Screen padding uses `AppSpacing.screenPadding`
- [ ] Cards use consistent shadow/radius pattern
- [ ] New Hive typeIds don't conflict with existing ones (0-18 taken)
- [ ] No duplicate provider definitions across features
- [ ] New routes added to the route map table above
- [ ] Muscle colors use `AppColors.colorForMuscle()`, not local helpers
- [ ] Build from `/tmp/AlfaNutrition` to verify iOS build succeeds
