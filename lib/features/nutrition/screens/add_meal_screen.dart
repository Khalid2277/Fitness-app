import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/food_search_providers.dart';
import 'package:alfanutrition/features/nutrition/widgets/quick_food_chip.dart';

/// Common serving unit options for the food logger.
const _kServingUnits = <String>[
  'g',
  'serving',
  'piece',
  'cup',
  'bowl',
  'slice',
  'burger',
  'sandwich',
  'wrap',
  'plate',
  'meal',
  'can',
  'bottle',
  'glass',
  'ml',
  'oz',
  'scoop',
  'tbsp',
  'tsp',
  'bar',
];

/// Units that represent a weight/volume amount (scale relative to original
/// gram-based serving size). All other units are "count-based" where 1 unit
/// equals one full serving of the food.
const _kGramLikeUnits = {'g', 'ml', 'oz'};

/// Screen for adding / editing a food item — with integrated food search.
class AddMealScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen opens in edit mode with fields pre-filled.
  final Meal? editingMeal;

  const AddMealScreen({super.key, this.editingMeal});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  MealType _selectedMealType = MealType.breakfast;
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'serving');
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showNotes = false;
  bool _saving = false;
  bool _showManualEntry = false;

  /// Tracks whether the current food came from a database search result.
  /// When true, macro fields are read-only and serving size drives recalculation.
  bool _isFromDatabase = false;

  /// The original search result used to scale nutrition when serving changes.
  FoodSearchResult? _selectedSearchFood;

  bool get _isEditing => widget.editingMeal != null;

  @override
  void initState() {
    super.initState();
    _servingSizeController.addListener(_onServingSizeChanged);

    // If editing, pre-fill all fields from the existing meal
    if (widget.editingMeal != null) {
      final meal = widget.editingMeal!;
      _nameController.text = meal.name;
      _selectedMealType = meal.mealType;
      _calorieController.text = meal.calories.toStringAsFixed(0);
      _proteinController.text = meal.protein.toStringAsFixed(0);
      _carbsController.text = meal.carbs.toStringAsFixed(0);
      _fatsController.text = meal.fats.toStringAsFixed(0);
      _fiberController.text = meal.fiber.toStringAsFixed(0);
      _servingSizeController.text =
          meal.servingSize.toStringAsFixed(meal.servingSize == meal.servingSize.roundToDouble() ? 0 : 1);
      _servingUnitController.text = meal.servingUnit ?? 'serving';
      if (meal.notes != null && meal.notes!.isNotEmpty) {
        _notesController.text = meal.notes!;
        _showNotes = true;
      }
      _showManualEntry = true;
    }

    // Clear previous search state when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodSearchQueryProvider.notifier).state = '';
    });
  }

  /// Recalculates all nutrition fields when serving size changes and the food
  /// came from a database (search result or quick food).
  void _onServingSizeChanged() {
    if (!_isFromDatabase || _selectedSearchFood == null) return;

    final newSize = double.tryParse(_servingSizeController.text);
    if (newSize == null || newSize <= 0) return;

    final currentUnit = _servingUnitController.text;
    final food = _selectedSearchFood!;

    double ratio;
    if (_kGramLikeUnits.contains(currentUnit)) {
      // Gram-like unit: scale relative to original serving size in grams.
      ratio = food.servingSize > 0 ? newSize / food.servingSize : 1.0;
    } else {
      // Count-based unit (burger, serving, piece, etc.): 1 unit = full
      // original serving. newSize = number of servings.
      ratio = newSize;
    }

    _calorieController.text = (food.calories * ratio).toInt().toString();
    _proteinController.text = (food.protein * ratio).toStringAsFixed(1);
    _carbsController.text = (food.carbs * ratio).toStringAsFixed(1);
    _fatsController.text = (food.fat * ratio).toStringAsFixed(1);
    _fiberController.text =
        ((food.fiber ?? 0) * ratio).toStringAsFixed(1);
  }

  /// Called when the serving unit dropdown changes.
  void _onServingUnitChanged(String newUnit) {
    if (!_isFromDatabase || _selectedSearchFood == null) return;

    // Temporarily remove the size listener to avoid double-recalculation.
    _servingSizeController.removeListener(_onServingSizeChanged);

    if (_kGramLikeUnits.contains(newUnit)) {
      // Switching to gram-like unit: restore the original gram serving size.
      _servingSizeController.text =
          _selectedSearchFood!.servingSize.toStringAsFixed(0);
    } else {
      // Switching to a count-based unit: set to 1 (= one full serving).
      _servingSizeController.text = '1';
    }

    _servingUnitController.text = newUnit;

    // Re-add listener and trigger recalculation.
    _servingSizeController.addListener(_onServingSizeChanged);
    _onServingSizeChanged();
  }

  @override
  void dispose() {
    _servingSizeController.removeListener(_onServingSizeChanged);
    _nameController.dispose();
    _calorieController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _fiberController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _fillFromQuickFood(QuickFood food) {
    // Convert to FoodSearchResult so serving-size scaling works uniformly.
    _selectedSearchFood = FoodSearchResult(
      id: 'quick_${food.name.hashCode}',
      name: food.name,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fats,
      fiber: food.fiber,
      servingSize: 1,
      servingUnit: 'serving',
      source: 'quick',
    );
    _isFromDatabase = true;

    _nameController.text = food.name;
    _calorieController.text = food.calories.toInt().toString();
    _proteinController.text = food.protein.toStringAsFixed(1);
    _carbsController.text = food.carbs.toStringAsFixed(1);
    _fatsController.text = food.fats.toStringAsFixed(1);
    _fiberController.text = food.fiber.toStringAsFixed(1);
    _servingSizeController.removeListener(_onServingSizeChanged);
    _servingSizeController.text = '1';
    _servingUnitController.text = 'serving';
    _servingSizeController.addListener(_onServingSizeChanged);
    setState(() => _showManualEntry = true);
  }

  void _fillFromSearchResult(FoodSearchResult food) {
    // Store original food for serving-size scaling.
    _selectedSearchFood = food;
    _isFromDatabase = true;

    _nameController.text = food.displayName;
    _calorieController.text = food.calories.toInt().toString();
    _proteinController.text = food.protein.toStringAsFixed(1);
    _carbsController.text = food.carbs.toStringAsFixed(1);
    _fatsController.text = food.fat.toStringAsFixed(1);
    _fiberController.text = (food.fiber ?? 0).toStringAsFixed(1);
    _servingSizeController.removeListener(_onServingSizeChanged);
    _servingSizeController.text = food.servingSize.toStringAsFixed(0);
    _servingUnitController.text = food.servingUnit;
    _servingSizeController.addListener(_onServingSizeChanged);

    // Log as recently used.
    ref.read(foodSearchServiceProvider).logFoodToRecent(food);
    ref.invalidate(recentFoodsProvider);

    // Clear search and show manual entry form.
    _searchController.clear();
    ref.read(foodSearchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();
    setState(() => _showManualEntry = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final date = ref.read(selectedDateProvider);
    final meal = Meal(
      id: _isEditing ? widget.editingMeal!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      mealType: _selectedMealType,
      calories: double.tryParse(_calorieController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fats: double.tryParse(_fatsController.text) ?? 0,
      fiber: double.tryParse(_fiberController.text) ?? 0,
      dateTime: _isEditing
          ? widget.editingMeal!.dateTime
          : DateTime(date.year, date.month, date.day,
              DateTime.now().hour, DateTime.now().minute),
      servingSize: double.tryParse(_servingSizeController.text) ?? 1,
      servingUnit: _servingUnitController.text.trim(),
      notes: _showNotes && _notesController.text.isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final source = ref.read(dataSourceProvider);
    if (source == DataSourceType.supabase) {
      final sbRepo = ref.read(sbNutritionRepositoryProvider);
      if (_isEditing) {
        await sbRepo.updateMeal(meal);
      } else {
        await sbRepo.addMeal(meal);
      }
    } else {
      final repo = ref.read(nutritionRepositoryProvider);
      final map = meal.toJson();
      map['date'] = meal.dateTime.toIso8601String();
      map['mealType'] = meal.mealType.index;
      await repo.saveMeal(map);
    }

    ref.invalidate(dailyNutritionProvider);
    ref.invalidate(todaysNutritionProvider);

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quickFoods = ref.watch(quickFoodsProvider);
    final searchQuery = ref.watch(foodSearchQueryProvider);
    final hasQuery = searchQuery.trim().length >= 2;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'EDIT FOOD' : 'ADD FOOD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _isEditing ? 'Edit Food' : 'Log Nutrition',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showManualEntry)
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surfaceLight1,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        ref.read(foodSearchQueryProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search foods...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(foodSearchQueryProvider.notifier).state =
                                      '';
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _BarcodeScanButton(onResult: _fillFromSearchResult),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: hasQuery
                ? _SearchResultsList(
                    onSelect: _fillFromSearchResult,
                  )
                : _showManualEntry
                    ? _ManualEntryForm(
                        formKey: _formKey,
                        selectedMealType: _selectedMealType,
                        onMealTypeChanged: (type) =>
                            setState(() => _selectedMealType = type),
                        nameController: _nameController,
                        calorieController: _calorieController,
                        proteinController: _proteinController,
                        carbsController: _carbsController,
                        fatsController: _fatsController,
                        fiberController: _fiberController,
                        servingSizeController: _servingSizeController,
                        servingUnitController: _servingUnitController,
                        notesController: _notesController,
                        showNotes: _showNotes,
                        onToggleNotes: () =>
                            setState(() => _showNotes = !_showNotes),
                        quickFoods: quickFoods,
                        onQuickFoodTap: _fillFromQuickFood,
                        nutritionReadOnly: _isFromDatabase,
                        onServingUnitChanged: _onServingUnitChanged,
                      )
                    : _BrowseView(
                        quickFoods: quickFoods,
                        onQuickFoodTap: _fillFromQuickFood,
                        onSearchResultTap: _fillFromSearchResult,
                        onManualEntry: () =>
                            setState(() => _showManualEntry = true),
                        onBarcodeScan: _fillFromSearchResult,
                        selectedMealType: _selectedMealType,
                        onMealTypeChanged: (type) =>
                            setState(() => _selectedMealType = type),
                      ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Browse View — shown when no search query and no manual entry
// ═══════════════════════════════════════════════════════════════════════════════

class _BrowseView extends ConsumerWidget {
  final List<QuickFood> quickFoods;
  final ValueChanged<QuickFood> onQuickFoodTap;
  final ValueChanged<FoodSearchResult> onSearchResultTap;
  final VoidCallback onManualEntry;
  final ValueChanged<FoodSearchResult> onBarcodeScan;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;

  const _BrowseView({
    required this.quickFoods,
    required this.onQuickFoodTap,
    required this.onSearchResultTap,
    required this.onManualEntry,
    required this.onBarcodeScan,
    required this.selectedMealType,
    required this.onMealTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recentFoodsAsync = ref.watch(recentFoodsProvider);
    final frequentFoodsAsync = ref.watch(frequentFoodsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // ── Meal Type Chips ───────────────────────────────────────────────
        Text(
          'MEAL TYPE',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          children: MealType.values.map((type) {
            final isSelected = type == selectedMealType;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onMealTypeChanged(type),
              selectedColor: isDark
                  ? AppColors.primaryBlueSurface
                  : AppColors.primaryBlueSurface.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.3)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.dividerLight,
              ),
            );
          }).toList(),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: AppSpacing.xxl),

        // ── Manual entry button ───────────────────────────────────────────
        GestureDetector(
          onTap: onManualEntry,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.surfaceLight1,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Entry',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Enter nutrition values manually',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

        const SizedBox(height: AppSpacing.md),

        // ── Scan Barcode button ─────────────────────────────────────────
        GestureDetector(
          onTap: () async {
            final result = await context.push<FoodSearchResult>('/barcode-scan');
            if (result != null) {
              onBarcodeScan(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Barcode',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Scan a food product barcode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

        const SizedBox(height: AppSpacing.md),

        // ── Create Meal button ──────────────────────────────────────────
        GestureDetector(
          onTap: () => context.push('/create-meal'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.playlist_add_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Meal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Combine multiple foods into one meal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

        const SizedBox(height: AppSpacing.xxl),

        // ── Recent foods ──────────────────────────────────────────────────
        recentFoodsAsync.when(
          data: (recentFoods) {
            if (recentFoods.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...recentFoods.take(5).map((food) => _FoodResultTile(
                      food: food,
                      onTap: () => onSearchResultTap(food),
                    )),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // ── Frequent foods ────────────────────────────────────────────────
        frequentFoodsAsync.when(
          data: (frequentFoods) {
            if (frequentFoods.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREQUENTLY LOGGED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...frequentFoods.take(5).map((food) => _FoodResultTile(
                      food: food,
                      onTap: () => onSearchResultTap(food),
                    )),
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // ── Quick Add ─────────────────────────────────────────────────────
        Text(
          'QUICK ADD',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to fill values instantly',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickFoods.map((food) {
            return QuickFoodChip(
              food: food,
              onTap: () => onQuickFoodTap(food),
            );
          }).toList(),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: AppSpacing.xxxxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Search Results List
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchResultsList extends ConsumerWidget {
  final ValueChanged<FoodSearchResult> onSelect;

  const _SearchResultsList({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resultsAsync = ref.watch(foodSearchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxxxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Search failed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check your connection and try again',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No results found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Try a different search term',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final food = results[index];
            return _FoodResultTile(
              food: food,
              onTap: () => onSelect(food),
            ).animate().fadeIn(
                  duration: 250.ms,
                  delay: (index * 30).ms,
                );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Food Result Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _FoodResultTile extends StatelessWidget {
  final FoodSearchResult food;
  final VoidCallback onTap;

  const _FoodResultTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.surfaceLight1,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (food.brand != null && food.brand!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      food.brand!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _MacroChip(
                        label: 'P',
                        value: '${food.protein.toInt()}g',
                        color: AppColors.primaryBlue,
                        isDark: isDark,
                        theme: theme,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _MacroChip(
                        label: 'C',
                        value: '${food.carbs.toInt()}g',
                        color: AppColors.accent,
                        isDark: isDark,
                        theme: theme,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _MacroChip(
                        label: 'F',
                        value: '${food.fat.toInt()}g',
                        color: AppColors.warning,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Calories badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food.calories.toInt()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  'kcal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.servingSize.toInt()} ${food.servingUnit}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Macro Chip (compact label for search results)
// ═══════════════════════════════════════════════════════════════════════════════

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Manual Entry Form
// ═══════════════════════════════════════════════════════════════════════════════

class _ManualEntryForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final TextEditingController nameController;
  final TextEditingController calorieController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;
  final TextEditingController fiberController;
  final TextEditingController servingSizeController;
  final TextEditingController servingUnitController;
  final TextEditingController notesController;
  final bool showNotes;
  final VoidCallback onToggleNotes;
  final List<QuickFood> quickFoods;
  final ValueChanged<QuickFood> onQuickFoodTap;
  final bool nutritionReadOnly;
  final ValueChanged<String>? onServingUnitChanged;

  const _ManualEntryForm({
    required this.formKey,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.nameController,
    required this.calorieController,
    required this.proteinController,
    required this.carbsController,
    required this.fatsController,
    required this.fiberController,
    required this.servingSizeController,
    required this.servingUnitController,
    required this.notesController,
    required this.showNotes,
    required this.onToggleNotes,
    required this.quickFoods,
    required this.onQuickFoodTap,
    this.nutritionReadOnly = false,
    this.onServingUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // -- Meal Type Chips --
          Text(
            'MEAL TYPE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: MealType.values.map((type) {
              final isSelected = type == selectedMealType;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(type.displayName),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => onMealTypeChanged(type),
                selectedColor: isDark
                    ? AppColors.primaryBlueSurface
                    : AppColors.primaryBlueSurface.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.3)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.dividerLight,
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.xxl),

          // -- Food Name --
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Food Name',
              hintText: 'e.g. Chicken Breast',
              prefixIcon: const Icon(Icons.restaurant_menu),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a food name' : null,
          ),

          const SizedBox(height: AppSpacing.xl),

          // -- Calories (prominent) --
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Column(
              children: [
                Text(
                  'CALORIES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: calorieController,
                  readOnly: nutritionReadOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter calories';
                    if ((double.tryParse(v) ?? 0) <= 0) return 'Invalid';
                    return null;
                  },
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.54),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.05),

          const SizedBox(height: AppSpacing.xl),

          // -- Macros Grid --
          Text(
            'MACRONUTRIENTS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MacroInput(
                  controller: proteinController,
                  label: 'Protein',
                  unit: 'g',
                  color: AppColors.primaryBlue,
                  readOnly: nutritionReadOnly,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroInput(
                  controller: carbsController,
                  label: 'Carbs',
                  unit: 'g',
                  color: AppColors.accent,
                  readOnly: nutritionReadOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MacroInput(
                  controller: fatsController,
                  label: 'Fats',
                  unit: 'g',
                  color: AppColors.warning,
                  readOnly: nutritionReadOnly,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MacroInput(
                  controller: fiberController,
                  label: 'Fiber',
                  unit: 'g',
                  color: AppColors.success,
                  readOnly: nutritionReadOnly,
                ),
              ),
            ],
          ),
          if (nutritionReadOnly) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Change the serving size to adjust nutrition values',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primaryBlue,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // -- Serving Size & Unit --
          Text(
            'SERVING',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: servingSizeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Size',
                    hintText: '1',
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _kServingUnits.contains(servingUnitController.text)
                      ? servingUnitController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 250,
                  items: _kServingUnits.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      if (onServingUnitChanged != null) {
                        onServingUnitChanged!(value);
                      } else {
                        servingUnitController.text = value;
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // -- Notes (collapsible) --
          GestureDetector(
            onTap: onToggleNotes,
            child: Row(
              children: [
                Icon(
                  showNotes
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Notes (optional)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (showNotes) ...[
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes about this food...',
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(duration: 200.ms),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // -- Quick Add Section --
          Text(
            'QUICK ADD',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to fill values instantly',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickFoods.map((food) {
              return QuickFoodChip(
                food: food,
                onTap: () => onQuickFoodTap(food),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: AppSpacing.xxxxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _MacroInput extends StatelessWidget {
  const _MacroInput({
    required this.controller,
    required this.label,
    required this.unit,
    required this.color,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final Color color;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceLight1,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: readOnly
                  ? theme.textTheme.titleLarge?.color?.withValues(alpha: 0.6)
                  : null,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: unit,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Barcode Scan Button — shown next to the search bar
// ═══════════════════════════════════════════════════════════════════════════════

class _BarcodeScanButton extends StatelessWidget {
  final ValueChanged<FoodSearchResult> onResult;

  const _BarcodeScanButton({required this.onResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final result = await context.push<FoodSearchResult>('/barcode-scan');
        if (result != null) {
          onResult(result);
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surfaceLight1,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.dividerLight,
          ),
        ),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 22,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
