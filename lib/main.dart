import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alfanutrition/core/theme/app_theme.dart';
import 'package:alfanutrition/data/services/storage_service.dart';
import 'package:alfanutrition/data/services/notification_service.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';
import 'package:alfanutrition/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables (.env file) — fail-safe if missing
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env file not found — app works without it (uses local AI fallback)
  }

  // Initialize Supabase if configured
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Initialize Hive (local cache / offline fallback)
  await StorageService.initialize();

  // Initialize local notifications
  await NotificationService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: AlfaNutritionApp(),
    ),
  );
}

class AlfaNutritionApp extends ConsumerWidget {
  const AlfaNutritionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'AlfaNutrition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
