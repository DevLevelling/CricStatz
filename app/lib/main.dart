import 'package:cricstatz/app.dart';
import 'package:cricstatz/config/supabase_config.dart';
import 'package:cricstatz/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('Initializing Supabase...', tag: 'App');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  AppLogger.info('Supabase initialized', tag: 'App');

  runApp(const CricStatzApp());
}
