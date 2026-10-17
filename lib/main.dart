import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/core/services/crash_reporting.dart';
import 'core/constants/service_locator.dart' as di;
import 'app.dart';

Future<void> main() async {
  await CrashReporting.run(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://luhrfxruyybhjygbjvqa.supabase.co',
      anonKey: 'sb_publishable_6QYZMKz_Sw_rhJ9PndbC1w_RUU2Nrrb',
    );
    await di.init();
    runApp(const MyApp());
  });
}
