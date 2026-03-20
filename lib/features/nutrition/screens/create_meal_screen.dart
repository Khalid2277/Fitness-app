import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/core/utils/haptics.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/food_search_providers.dart';

/// Screen for creating a custom meal by combining multiple food items.
class CreateMealScreen extends ConsumerStatefulWidget {
  const CreateMealScreen({super.key});

  @override
  ConsumerState<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends ConsumerState<CreateMealScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  MealType _selectedMealType = MealType.lunch;
  bool _saving = false;

  /// Foods added to this custom meal, each with its quantity multiplier.
  final List<_MealItem> _items = [];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Computed totals ──────────────────────────────────────────────────────

  double get _totalCalories =>
      _items.fold(0, (sum, i) => sum + i.food.calories * i.quantity);

  double get _totalProtein =>
      _items.fold(0, (sum, i) => sum + i.food.protein * i.quantity);

  double get _totalCarbs =>
      _items.fold(0, (sum, i) => sum + i.food.carbs * i.quantity);

  double get _totalFats =>
      _items.fold(0, (sum, i) => sum + i.food.fat * i.quantity);

  double get _totalFiber =>
      _items.fold(0, (sum, i) => sum + (i.food.fiber ?? 0) * i.quantity);

  // ── Add food ─────────────────────────────────────────────────────────────

  void _addFood(FoodSearchResult food) {
    setState(() {
      // Check if already added — increment quantity
      final existing = _items.indexWhere((i) => i.food.id == food.id);
      if (existing >= 0) {
        _items[existing] = _items[existing].copyWith(
          quantity: _items[existing].quantity + 1,
        );
      } else {
        _items.add(_MealItem(food: food, quantity: 1));
      }
    });

    // Clear search
    _searchController.clear();
    ref.read(foodSearchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();

    // Log as recently used
    ref.read(foodSearchServiceProvider).logFoodToRecent(food);
    ref.invalidate(recentFoodsProvider);

    Haptics.light();
  }

  void _removeItem(int index) {
    Haptics.light();
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, double qty) {
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      _items[index] = _items[index].copyWith(quantity: qty);
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_items.isEmpty) return;

    final name = _nameController.text.trim().isEmpty
        ? 'Custom Meal'
        : _nameController.text.trim();

    setState(() => _saving = true);

    final date = ref.read(selectedDateProvider);
    final meal = Meal(
      id: const Uuid().v4(),
      name: name,
      mealType: _selectedMealType,
      calories: _totalCalories,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fats: _totalFats,
      fiber: _totalFiber,
      dateTime: DateTime(
        date.year, date.month, date.day,
        DateTime.now().hour, DateTime.now().minute,
      ),
      servingSize: 1,
      servingUnit: 'meal',
      notes: _items.map((i) => '${i.quantity}x ${i.food.displayName}').join(', '),
    );

    final source = ref.read(dataSourceProvider);
    if (source == DataSourceType.supabase) {
      final sbRepo = ref.read(sbNutritionRepositoryProvider);
      await sbRepo.addMeal(meal);
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
      Haptics.medium();
      context.pop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasQuery = _searchController.text.trim().length >= 2;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Top Bar ─────────────────────────────────────────
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
                          'CUSTOM MEAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Create Meal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_items.isNotEmpty)
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
                                'Log Meal',
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

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: AppSpacing.screenPadding,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.surfaceLight1,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.dividerLight,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: theme.textTheme.bodyMedium,
                  onChanged: (value) {
                    ref.read(foodSearchQueryProvider.notifier).state = value;
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search foods to add...',
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

            const SizedBox(height: AppSpacing.sm),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: hasQuery
                  ? _SearchResults(onSelect: _addFood)
                  : _MealBuilder(
                      items: _items,
                      nameController: _nameController,
                      selectedMealType: _selectedMealType,
                      onMealTypeChanged: (type) =>
                          setState(() => _selectedMealType = type),
                      totalCalories: _totalCalories,
                      totalProtein: _totalProtein,
                      totalCarbs: _totalCarbs,
                      totalFats: _totalFats,
                      totalFiber: _totalFiber,
                      onRemoveItem: _removeItem,
                      onUpdateQuantity: _updateQuantity,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Meal item model
// ═════════════════════════════════════════════════════════════════════════════

class _MealItem {
  final FoodSearchResult food;
  final double quantity;

  const _MealItem({required this.food, this.quantity = 1});

  _MealItem copyWith({FoodSearchResult? food, double? quantity}) {
    return _MealItem(
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Search results list (reuses existing provider)
// ═════════════════════════════════════════════════════════════════════════════

class _SearchResults extends ConsumerWidget {
  final ValueChanged<FoodSearchResult> onSelect;

  const _SearchResults({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resultsAsync = ref.watch(foodSearchResultsProvider);

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Text(
                'No foods found. Try a different search.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.xxxl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final food = results[index];
            return _FoodResultTile(
              food: food,
              onTap: () => onSelect(food),
              isDark: isDark,
              theme: theme,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Search failed. Try again.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Food result tile
// ═════════════════════════════════════════════════════════════════════════════

class _FoodResultTile extends StatelessWidget {
  final FoodSearchResult food;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _FoodResultTile({
    required this.food,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Image or icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: food.imageUrl != null
                  ? ClipRRect(
                      borderRadius: AppSpacing.borderRadiusSm,
                      child: Image.network(
                        food.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.restaurant_rounded,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.restaurant_rounded,
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
                    food.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${food.calories.round()} kcal · ${food.servingSize.round()}${food.servingUnit}',
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
              Icons.add_circle_rounded,
              size: 24,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Meal Builder — shows added items and totals
// ═════════════════════════════════════════════════════════════════════════════

class _MealBuilder extends StatelessWidget {
  final List<_MealItem> items;
  final TextEditingController nameController;
  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeChanged;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final double totalFiber;
  final void Function(int) onRemoveItem;
  final void Function(int, double) onUpdateQuantity;

  const _MealBuilder({
    required this.items,
    required this.nameController,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.totalFiber,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // ── Meal name field ────────────────────────────────────────────
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Meal Name',
            hintText: 'e.g. Post-Workout Meal',
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: AppSpacing.lg),

        // ── Meal type chips ────────────────────────────────────────────
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
              label: Text(type.displayName),
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
        ),

        const SizedBox(height: AppSpacing.xxl),

        // ── Nutrition summary ──────────────────────────────────────────
        if (items.isNotEmpty) ...[
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                  AppColors.accent.withValues(alpha: isDark ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${totalCalories.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  'TOTAL CALORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroChip(
                      label: 'Protein',
                      value: totalProtein,
                      color: AppColors.primaryBlue,
                    ),
                    _MacroChip(
                      label: 'Carbs',
                      value: totalCarbs,
                      color: AppColors.accent,
                    ),
                    _MacroChip(
                      label: 'Fats',
                      value: totalFats,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.xxl),
        ],

        // ── Items header ───────────────────────────────────────────────
        Text(
          'ITEMS (${items.length})',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : AppColors.surfaceLight1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.dividerLight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 28,
                    color: AppColors.success.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Search and add foods above',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Combine multiple items into one meal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

        // ── Item cards ─────────────────────────────────────────────────
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _MealItemCard(
            item: item,
            isDark: isDark,
            theme: theme,
            onRemove: () => onRemoveItem(index),
            onQuantityChanged: (qty) => onUpdateQuantity(index, qty),
          ).animate().fadeIn(duration: 200.ms, delay: (50 * index).ms);
        }),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Meal item card
// ═════════════════════════════════════════════════════════════════════════════

class _MealItemCard extends StatelessWidget {
  final _MealItem item;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChanged;

  const _MealItemCard({
    required this.item,
    required this.isDark,
    required this.theme,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final food = item.food;
    final cals = (food.calories * item.quantity).round();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$cals kcal · P:${(food.protein * item.quantity).round()}g '
                  'C:${(food.carbs * item.quantity).round()}g '
                  'F:${(food.fat * item.quantity).round()}g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(
                icon: Icons.remove_rounded,
                onTap: () => onQuantityChanged(item.quantity - 1),
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  item.quantity == item.quantity.roundToDouble()
                      ? item.quantity.round().toString()
                      : item.quantity.toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add_rounded,
                onTap: () => onQuantityChanged(item.quantity + 1),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.sm),

          // Delete
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quantity button
// ═════════════════════════════════════════════════════════════════════════════

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Macro chip
// ═════════════════════════════════════════════════════════════════════════════

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${value.round()}g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
