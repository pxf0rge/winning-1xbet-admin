import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

class ArchiveSupabaseDatasource {
  final SupabaseClient client;

  ArchiveSupabaseDatasource(this.client);

  Future<List<SignalModel>> getArchive() async {
    final res = await client
        .from("signals")
        .select()
        .inFilter("status", ["WIN", "LOSE", "VOID"])
        .order("created_at", ascending: false);

    return (res as List).map((e) => SignalModel.fromJson(e)).toList();
  }
}
