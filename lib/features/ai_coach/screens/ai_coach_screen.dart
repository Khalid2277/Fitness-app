import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/core/utils/haptics.dart';
import 'package:alfanutrition/data/models/chat_session.dart';
import 'package:alfanutrition/data/services/food_image_service.dart';
import 'package:alfanutrition/features/ai_coach/providers/ai_coach_providers.dart';
import 'package:alfanutrition/features/ai_coach/widgets/chat_bubble.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiChatMessagesProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Quick action handlers ─────────────────────────────────────────────

  Future<void> _onScanFood() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (photo == null) return;

    _sendMessage(
      '📸 I just took a photo of my food. Please analyze it and tell me the estimated nutrition.',
    );

    final service = LocalFoodImageService();
    final result = await service.analyzeImage(photo.path);

    if (result.confidence > 0.3) {
      ref.read(aiChatMessagesProvider.notifier).sendMessage(
        'The food in my photo looks like ${result.foodName}. '
        'Estimated: ${result.calories.toInt()} kcal, '
        '${result.protein.toStringAsFixed(1)}g protein, '
        '${result.carbs.toStringAsFixed(1)}g carbs, '
        '${result.fats.toStringAsFixed(1)}g fat. '
        'Can you confirm and help me log this?',
      );
    } else {
      ref.read(aiChatMessagesProvider.notifier).sendMessage(
        'I took a photo of my meal but the automatic recognition could not identify it confidently. '
        'Can you help me estimate the nutrition? It looks like a typical meal. '
        'Please suggest what it might be and the approximate macros so I can log it.',
      );
    }
    _scrollToBottom();
  }

  void _startNewChat() {
    Haptics.light();
    ref.read(aiChatMessagesProvider.notifier).startNewSession();
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _loadSession(ChatSession session) {
    Haptics.light();
    ref.read(aiChatMessagesProvider.notifier).loadSession(session.id);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = ref.watch(aiChatMessagesProvider);
    final agentType = ref.watch(aiAgentTypeProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Only count real conversation messages (skip the seeded welcome)
    final hasConversation = messages.length > 1;

    ref.listen<List<ChatMessage>>(aiChatMessagesProvider, (previous, next) {
      if (previous != null && next.length > previous.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: _ChatHistoryDrawer(
        onNewChat: _startNewChat,
        onSessionTap: _loadSession,
      ),
      body: Column(
        children: [
          // ── App Bar ───────────────────────────────────────────────────
          _PremiumAppBar(
            agentType: agentType,
            onAgentSwitch: (type) {
              Haptics.selection();
              ref.read(aiChatMessagesProvider.notifier).switchAgent(type);
            },
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onNewChatTap: _startNewChat,
          ),

          // ── Chat area ────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
              child: hasConversation
                  ? ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: 100 + bottomPadding,
                      ),
                      itemCount: messages.length - 1, // skip welcome seed
                      itemBuilder: (context, index) {
                        final message = messages[index + 1];
                        return ChatBubble(
                          message: message,
                          onSuggestionTap: _sendMessage,
                        );
                      },
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        bottom: 100 + bottomPadding,
                      ),
                      child: _WelcomeView(
                        agentType: agentType,
                        onSuggestionTap: _sendMessage,
                        onScanFood: _onScanFood,
                      ),
                    ),
            ),
          ),

          // ── Frosted glass input bar ────────────────────────────────────
          _FrostedInputBar(
            controller: _textController,
            focusNode: _focusNode,
            hasText: _hasText,
            onSend: () => _sendMessage(_textController.text),
            onScanFood: _onScanFood,
            bottomPadding: bottomPadding,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Premium App Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumAppBar extends StatelessWidget {
  final AiAgentType agentType;
  final ValueChanged<AiAgentType> onAgentSwitch;
  final VoidCallback onMenuTap;
  final VoidCallback onNewChatTap;

  const _PremiumAppBar({
    required this.agentType,
    required this.onAgentSwitch,
    required this.onMenuTap,
    required this.onNewChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            topPadding + AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.85)
                : AppColors.surfaceLight.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: onMenuTap,
                    icon: Icon(
                      Icons.menu_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    iconSize: 24,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),

                  // AI avatar mini
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Title + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: Text(
                            'AI Coach',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Online',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // New chat button
                  _GlassIconButton(
                    icon: Icons.edit_square,
                    onTap: onNewChatTap,
                    isDark: isDark,
                    theme: theme,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Agent toggle ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _AgentToggle(
                  agentType: agentType,
                  onSwitch: onAgentSwitch,
                  isDark: isDark,
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ── Glass-morphism icon button ─────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.primaryBlueLight,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Agent toggle (TRAINER / NUTRITIONIST)
// ═══════════════════════════════════════════════════════════════════════════════

class _AgentToggle extends StatelessWidget {
  final AiAgentType agentType;
  final ValueChanged<AiAgentType> onSwitch;
  final bool isDark;
  final ThemeData theme;

  const _AgentToggle({
    required this.agentType,
    required this.onSwitch,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _ToggleTab(
            label: 'TRAINER',
            icon: Icons.fitness_center_rounded,
            isSelected: agentType == AiAgentType.trainer,
            onTap: () => onSwitch(AiAgentType.trainer),
            isDark: isDark,
            theme: theme,
          ),
          _ToggleTab(
            label: 'NUTRITIONIST',
            icon: Icons.restaurant_rounded,
            isSelected: agentType == AiAgentType.nutritionist,
            onTap: () => onSwitch(AiAgentType.nutritionist),
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusPill,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Welcome View (empty state)
// ═══════════════════════════════════════════════════════════════════════════════

class _WelcomeView extends StatelessWidget {
  final AiAgentType agentType;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onScanFood;

  const _WelcomeView({
    required this.agentType,
    required this.onSuggestionTap,
    required this.onScanFood,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isTrainer = agentType == AiAgentType.trainer;
    final suggestions = isTrainer
        ? [
            _SuggestionData(
              icon: Icons.analytics_rounded,
              text: 'Analyze my workout',
              color: AppColors.primaryBlue,
            ),
            _SuggestionData(
              icon: Icons.fitness_center_rounded,
              text: 'Recommend a workout split',
              color: AppColors.warning,
            ),
            _SuggestionData(
              icon: Icons.trending_up_rounded,
              text: 'How do I progressively overload?',
              color: AppColors.accent,
            ),
            _SuggestionData(
              icon: Icons.self_improvement_rounded,
              text: 'Form check tips',
              color: AppColors.primaryBlueLight,
            ),
          ]
        : [
            _SuggestionData(
              icon: Icons.restaurant_menu_rounded,
              text: 'Help with my diet',
              color: AppColors.accent,
            ),
            _SuggestionData(
              icon: Icons.receipt_long_rounded,
              text: 'Create a meal plan',
              color: AppColors.warning,
            ),
            _SuggestionData(
              icon: Icons.pie_chart_rounded,
              text: 'What should my macros be?',
              color: AppColors.primaryBlue,
            ),
            _SuggestionData(
              icon: Icons.camera_alt_rounded,
              text: 'Scan my food',
              color: AppColors.success,
            ),
          ];

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxxl),

          // ── Animated AI avatar with premium gradient ring ──────────────
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scaleXY(
                begin: 1.0,
                end: 1.05,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Headline with gradient ─────────────────────────────────────
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              'Your Personal AI Coach',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.sm),

          Text(
            isTrainer
                ? 'Expert guidance on training, recovery, and performance'
                : 'Personalized nutrition advice, meal plans, and macro tracking',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 300.ms)
              .slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.xxxl),

          // ── Suggestion chips ─────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),

          const SizedBox(height: AppSpacing.md),

          ...List.generate(
            suggestions.length,
            (index) {
              final s = suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SuggestionCard(
                  icon: s.icon,
                  text: s.text,
                  color: s.color,
                  isDark: isDark,
                  theme: theme,
                  onTap: () {
                    Haptics.light();
                    if (s.text == 'Scan my food') {
                      onScanFood();
                    } else {
                      onSuggestionTap(s.text);
                    }
                  },
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 450 + (index * 80)),
                  )
                  .slideX(
                    begin: 0.06,
                    duration: 400.ms,
                    delay: Duration(milliseconds: 450 + (index * 80)),
                    curve: Curves.easeOut,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionData {
  final IconData icon;
  final String text;
  final Color color;

  const _SuggestionData({
    required this.icon,
    required this.text,
    required this.color,
  });
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            width: 0.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  ...AppColors.cardShadowLight,
                  BoxShadow(
                    color: color.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: isDark ? 0.2 : 0.12),
                    color.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.1 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Frosted Glass Input Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _FrostedInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onScanFood;
  final double bottomPadding;

  const _FrostedInputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onSend,
    required this.onScanFood,
    required this.bottomPadding,
  });

  @override
  State<_FrostedInputBar> createState() => _FrostedInputBarState();
}

class _FrostedInputBarState extends State<_FrostedInputBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + (widget.bottomPadding > 0 ? widget.bottomPadding : AppSpacing.sm),
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark.withValues(alpha: 0.82)
                : AppColors.backgroundLight.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Camera button ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: GestureDetector(
                  onTap: () {
                    Haptics.light();
                    widget.onScanFood();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Text field with gradient border on focus ──────────────
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  constraints: const BoxConstraints(
                    minHeight: 42,
                    maxHeight: 140,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: _isFocused
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                    gradient: _isFocused ? null : null,
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: isDark ? 0.2 : 0.12),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  foregroundDecoration: _isFocused
                      ? BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                          border: GradientBoxBorder(
                            gradient: AppColors.primaryGradient,
                            borderWidth: 1.5,
                          ),
                        )
                      : null,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    style: theme.textTheme.bodyMedium,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach anything...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm + 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Gradient send button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: GestureDetector(
                  onTap: () {
                    if (widget.hasText) {
                      Haptics.light();
                      widget.onSend();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          widget.hasText ? AppColors.primaryGradient : null,
                      color: widget.hasText
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06)),
                      boxShadow: widget.hasText
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        key: ValueKey(widget.hasText),
                        size: 21,
                        color: widget.hasText
                            ? Colors.white
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A decoration that paints a gradient border.
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double borderWidth;

  const GradientBoxBorder({required this.gradient, this.borderWidth = 1.0});

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  bool get isUniform => true;

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, borderWidth: borderWidth * t);

  @override
  void paint(Canvas canvas, Rect rect,
      {ui.TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    if (shape == BoxShape.circle) {
      canvas.drawCircle(rect.center, (rect.shortestSide - borderWidth) / 2, paint);
    } else if (borderRadius != null) {
      canvas.drawRRect(
        borderRadius
            .resolve(textDirection)
            .toRRect(rect)
            .deflate(borderWidth / 2),
        paint,
      );
    } else {
      canvas.drawRect(rect.deflate(borderWidth / 2), paint);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Chat History Drawer
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatHistoryDrawer extends ConsumerWidget {
  final VoidCallback onNewChat;
  final ValueChanged<ChatSession> onSessionTap;

  const _ChatHistoryDrawer({
    required this.onNewChat,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final memoriesAsync = ref.watch(userMemoriesProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      width: 320,
      child: Drawer(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // ── Drawer header ─────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                topPadding + AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surfaceDark1,
                          AppColors.surfaceDark.withValues(alpha: 0.95),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surfaceLight,
                          AppColors.surfaceLight1.withValues(alpha: 0.95),
                        ],
                      ),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Drawer avatar
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: Text(
                            'Chat History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Memory badge
                      memoriesAsync.when(
                        data: (memories) {
                          if (memories.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: AppSpacing.borderRadiusPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.psychology_rounded,
                                  size: 12,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${memories.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // New Chat button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.borderRadiusMd,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onNewChat,
                        icon: const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          'New Chat',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Session list ──────────────────────────────────────────
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _EmptySessionsState(theme: theme, isDark: isDark);
                  }

                  final grouped = _groupSessions(sessions);

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: bottomPadding + AppSpacing.lg,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return _SessionGroup(
                        label: group.label,
                        sessions: group.sessions,
                        activeSessionId: activeSessionId,
                        onSessionTap: onSessionTap,
                        onDeleteSession: (session) =>
                            _deleteSession(ref, session),
                        isDark: isDark,
                        theme: theme,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxxl),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Could not load history',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSession(WidgetRef ref, ChatSession session) async {
    final repo = ref.read(chatHistoryRepositoryProvider);
    await repo.deleteSession(session.id);

    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == session.id) {
      ref.read(aiChatMessagesProvider.notifier).startNewSession();
    }

    ref.invalidate(chatSessionsProvider);
  }

  List<_SessionGroupData> _groupSessions(List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final todayList = <ChatSession>[];
    final yesterdayList = <ChatSession>[];
    final lastWeekList = <ChatSession>[];
    final olderList = <ChatSession>[];

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.lastMessageAt.year,
        session.lastMessageAt.month,
        session.lastMessageAt.day,
      );
      if (sessionDate.isAtSameMomentAs(today) || sessionDate.isAfter(today)) {
        todayList.add(session);
      } else if (sessionDate.isAtSameMomentAs(yesterday) ||
          (sessionDate.isAfter(yesterday) && sessionDate.isBefore(today))) {
        yesterdayList.add(session);
      } else if (sessionDate.isAfter(lastWeek)) {
        lastWeekList.add(session);
      } else {
        olderList.add(session);
      }
    }

    final groups = <_SessionGroupData>[];
    if (todayList.isNotEmpty) {
      groups.add(_SessionGroupData(label: 'Today', sessions: todayList));
    }
    if (yesterdayList.isNotEmpty) {
      groups
          .add(_SessionGroupData(label: 'Yesterday', sessions: yesterdayList));
    }
    if (lastWeekList.isNotEmpty) {
      groups.add(
          _SessionGroupData(label: 'Last 7 Days', sessions: lastWeekList));
    }
    if (olderList.isNotEmpty) {
      groups.add(_SessionGroupData(label: 'Older', sessions: olderList));
    }

    return groups;
  }
}

class _SessionGroupData {
  final String label;
  final List<ChatSession> sessions;

  const _SessionGroupData({required this.label, required this.sessions});
}

// ── Empty sessions state ──────────────────────────────────────────────────

class _EmptySessionsState extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _EmptySessionsState({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start a chat with your AI Coach',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session group with label and tiles ──────────────────────────────────────

class _SessionGroup extends StatelessWidget {
  final String label;
  final List<ChatSession> sessions;
  final String? activeSessionId;
  final ValueChanged<ChatSession> onSessionTap;
  final ValueChanged<ChatSession> onDeleteSession;
  final bool isDark;
  final ThemeData theme;

  const _SessionGroup({
    required this.label,
    required this.sessions,
    required this.activeSessionId,
    required this.onSessionTap,
    required this.onDeleteSession,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ),
        ...sessions.map((session) => _SessionTile(
              session: session,
              isActive: session.id == activeSessionId,
              onTap: () => onSessionTap(session),
              onDelete: () => onDeleteSession(session),
              isDark: isDark,
              theme: theme,
            )),
      ],
    );
  }
}

// ── Individual session tile ────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDark;
  final ThemeData theme;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isTrainer = session.agentType == 'trainer';
    final agentIcon =
        isTrainer ? Icons.fitness_center_rounded : Icons.restaurant_rounded;
    final agentColor = isTrainer ? AppColors.primaryBlue : AppColors.accent;
    final timeStr = _formatSessionTime(session.lastMessageAt);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.error.withValues(alpha: 0.15),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.error,
          size: 20,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppColors.primaryBlueSurface.withValues(alpha: 0.5)
                  : AppColors.primaryBlue.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2.5,
                  ),
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: agentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(agentIcon, size: 14, color: agentColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? AppColors.primaryBlueLight
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$timeStr  ·  ${session.messageCount} msgs',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSessionTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(time);
  }
}
