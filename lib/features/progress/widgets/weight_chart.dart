import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';

/// Period filter for the weight chart.
enum ChartPeriod {
  oneWeek('1W', 7),
  oneMonth('1M', 30),
  threeMonths('3M', 90),
  sixMonths('6M', 180),
  oneYear('1Y', 365),
  all('All', 0);

  final String label;
  final int days;
  const ChartPeriod(this.label, this.days);
}

class WeightChart extends StatefulWidget {
  final List<WeightDataPoint> dataPoints;

  const WeightChart({super.key, required this.dataPoints});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  ChartPeriod _selectedPeriod = ChartPeriod.oneMonth;
  int? _touchedIndex;

  List<WeightDataPoint> get _filteredData {
    if (widget.dataPoints.isEmpty) return [];
    if (_selectedPeriod == ChartPeriod.all) return widget.dataPoints;

    final cutoff =
        DateTime.now().subtract(Duration(days: _selectedPeriod.days));
    return widget.dataPoints.where((d) => d.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _filteredData;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEIGHT TREND',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              if (data.isNotEmpty)
                Text(
                  '${data.last.weight.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Period selector
          _PeriodSelector(
            selected: _selectedPeriod,
            onChanged: (p) => setState(() {
              _selectedPeriod = p;
              _touchedIndex = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chart or empty state
          if (data.isEmpty)
            _EmptyChartState()
          else
            SizedBox(
              height: 200,
              child: _buildChart(data, theme, isDark),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildChart(
      List<WeightDataPoint> data, ThemeData theme, bool isDark) {
    final minWeight =
        data.map((d) => d.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        data.map((d) => d.weight).reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.15;
    final yMin = (minWeight - padding).clamp(0.0, double.infinity);
    final yMax = maxWeight + padding;

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].weight));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(yMin, yMax),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.surfaceLight2,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: _calculateInterval(yMin, yMax),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _calculateBottomInterval(data.length),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    DateFormat('M/d').format(data[idx].date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              setState(() {
                _touchedIndex =
                    response.lineBarSpots!.first.spotIndex;
              });
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? AppColors.surfaceDark3
                : AppColors.surfaceLight,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final idx = spot.spotIndex;
                final dp = data[idx];
                return LineTooltipItem(
                  '${dp.weight.toStringAsFixed(1)} kg\n',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d, yyyy').format(dp.date),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: AppColors.primaryBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isSelected = index == _touchedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 5 : 0,
                  color: AppColors.primaryBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.15),
                  AppColors.primaryBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 5) return 1;
    if (range <= 15) return 3;
    if (range <= 30) return 5;
    return 10;
  }

  double _calculateBottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    if (count <= 90) return 15;
    return 30;
  }
}

class _PeriodSelector extends StatelessWidget {
  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceLight1,
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChartPeriod.values.map((period) {
          final isSelected = period == selected;
          return GestureDetector(
            onTap: () => onChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusPill,
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No weight data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Log your first body metric to see trends',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
