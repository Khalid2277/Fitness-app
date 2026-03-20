# AlfaNutrition

A production-quality iOS fitness tracking app built with Flutter. Track workouts, nutrition, body metrics, and muscle balance — all in one polished, offline-first experience.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-iOS-000000?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Features

### Dashboard
- Daily calorie ring with consumed/remaining display
- Macro progress bars (protein, carbs, fats)
- Today's workout status and weekly training dots
- Muscle coverage summary
- Recent workout cards
- Quick actions (Start Workout, Log Meal, Log Weight)

### Workout Tracking
- Log exercises with sets, reps, weight, and RPE
- Live workout timer with elapsed duration
- Exercise picker with search, muscle group, and equipment filters
- Workout history grouped by date with muscle chips
- Personal records tracking
- Swipe-to-delete sets with confirmation

### Nutrition Logging
- Log meals by type (breakfast, lunch, dinner, snack)
- Track calories, protein, carbs, fats, and fiber
- Daily calorie ring and macro progress bars
- Quick-add presets for 10 common foods
- 7-day horizontal date selector
- Architecture ready for food API and barcode scanning

### Body Metrics & Progress
- Log weight, body fat %, and 7 body measurements
- Weight trend chart with period selector (1W / 1M / 3M / 6M / 1Y / All)
- Personal records and training stats overview
- Body metric history with trend arrows
- Designed for future progress photo support

### Interactive Muscle Map
- Tappable front/back body visualization (CustomPainter)
- Color intensity reflects weekly training volume per muscle group
- 3D flip animation between front and back views
- Tap any muscle to see exercises, volume, and training status
- 14 distinct muscle regions per view

### Muscle Analysis
- Weekly volume tracking per muscle group
- Balance score (0-100) based on research-backed volume thresholds
- Undertrained / optimal / overtrained status per muscle
- Actionable suggestions to improve training balance
- Color-coded volume bars with status indicators

### Workout Plan Generator
- 5 split types: Push/Pull/Legs, Upper/Lower, Bro Split, Full Body, Arnold Split
- Goals: fat loss, hypertrophy, strength, endurance, general fitness
- Adjust experience level, training days (2-6), equipment, and location
- Goal-specific rep schemes and rest periods
- Save, activate, and manage multiple plans

### Exercise Library
- 90 exercises across 14 muscle groups
- Detailed info: instructions, tips, common mistakes, safety notes
- Equipment type, difficulty level, and rep range guidance
- Video tutorial link support (curated now, API-ready)
- Search, filter by muscle group/equipment, and sort

### Onboarding
- 4-step wizard: Welcome, Profile Info, Goal Selection, Experience Level
- Animated progress dots and smooth page transitions
- Profile saved to Hive, skipped on subsequent launches

### Additional
- Full dark mode support
- Frosted glass bottom navigation bar
- Smooth entrance animations on every screen (flutter_animate)
- Pull-to-refresh on the dashboard
- Clean empty states, loading shimmer, and error handling

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x+ ([install](https://docs.flutter.dev/get-started/install))
- Xcode 15+ with iOS Simulator
- CocoaPods (`sudo gem install cocoapods`)

### Install & Run

```bash
git clone <repo-url>
cd Fitness_app
flutter pub get
flutter run
```

### iCloud Desktop Workaround

If your project folder is on an iCloud-synced Desktop, codesigning will fail due to extended attributes. Build from a local path:

```bash
rsync -a --delete ~/Desktop/Fitness_app/ /tmp/AlfaNutrition/
xattr -cr /tmp/AlfaNutrition
cd /tmp/AlfaNutrition && flutter run
```

### Running on a Physical Device

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your signing team under **Runner > Signing & Capabilities**
3. Run from Xcode or use `flutter run -d <device-id>`

---

## Architecture

```
lib/
  core/                    # Design system & shared utilities
    constants/             #   App-wide constants (targets, limits, box names)
    theme/                 #   AppColors, AppSpacing, AppTextStyles, AppTheme
    widgets/               #   Reusable components (AppCard, EmptyState, etc.)
  data/                    # Data layer
    models/                #   Hive-backed models with manual TypeAdapters
    repositories/          #   CRUD over Hive boxes (5 repositories)
    seed/                  #   Exercise database (90 exercises)
    services/              #   Business logic (muscle analysis, plan gen, video)
  features/                # Feature modules (9 features)
    exercises/             #   Exercise library & detail
    home/                  #   Dashboard
    muscles/               #   Body map & muscle analysis
    nutrition/             #   Calorie & macro tracking
    onboarding/            #   First-run setup wizard
    plans/                 #   Workout plan generator
    profile/               #   User profile & settings
    progress/              #   Weight chart, PRs, training stats
    workouts/              #   Workout logging, active workout, history
  routing/                 # GoRouter config & AppShell (bottom nav)
  main.dart                # Entry point
```

### Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| State management | Riverpod | Type-safe, testable, no BuildContext in providers |
| Navigation | GoRouter | Declarative, ShellRoute for tabs, deep link ready |
| Local storage | Hive | Fast, no native deps, simple key-value boxes |
| Model serialization | Manual TypeAdapters | No build_runner, full control, zero codegen |
| Animations | flutter_animate | Declarative, chainable, minimal boilerplate |
| Charts | fl_chart | Highly customizable, pure Dart, good perf |

---

## Dependencies

```yaml
flutter_riverpod: ^2.6.1    # State management
hive_flutter: ^1.1.0        # Local persistence
go_router: ^14.8.1          # Routing
fl_chart: ^0.70.2           # Charts
flutter_animate: ^4.5.2     # Animations
percent_indicator: ^4.2.3   # Calorie rings
shimmer: ^3.0.0             # Loading skeletons
flutter_svg: ^2.0.17        # SVG support
uuid: ^4.5.1                # Unique IDs
intl: ^0.20.2               # Date formatting
url_launcher: ^6.3.1        # External links (exercise videos)
```

---

## Data Models

| Model | TypeId | Description |
|-------|--------|-------------|
| Enums (MuscleGroup, EquipmentType, etc.) | 0-7 | 8 enums with Hive adapters |
| Exercise | 8 | 17 fields, seed database |
| ExerciseSet | 9 | Weight, reps, RPE, rest, warmup |
| WorkoutExercise | 10 | Exercise within a workout session |
| Workout | 11 | Full session with duration, notes |
| Meal | 12 | Food entry with full macros |
| DailyNutrition | 13 | Aggregated daily totals |
| BodyMetric | 14 | Weight, body fat, measurements |
| WorkoutPlan | 15 | Generated plan with metadata |
| PlanDay | 16 | Day within a plan |
| PlanExercise | 17 | Planned exercise details |
| UserProfile | 18 | Name, goals, targets |

Next available typeId: **19**

---

## Future Roadmap

- [ ] Food database API integration (Nutritionix / OpenFoodFacts)
- [ ] Barcode scanner for food logging
- [ ] YouTube Data API for exercise video search
- [ ] Backend sync (Firebase / REST API)
- [ ] Progress photo capture and gallery
- [ ] Rest timer with local notifications
- [ ] Apple Health / Google Fit integration
- [ ] Achievements and streak rewards
- [ ] Weekly review summary screen
- [ ] Export data as CSV
- [ ] iOS home screen widget

---

## Contributing

See [CLAUDE.md](CLAUDE.md) for architecture conventions, naming rules, design system tokens, route map, and the quality checklist to follow before submitting changes.

---

## License

MIT
