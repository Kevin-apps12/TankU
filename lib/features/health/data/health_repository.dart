import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/health_log.dart';

class HealthRepository {
  HealthRepository(this._client);
  final SupabaseClient _client;

  Future<List<HealthLog>> listLogs(String tankId, {int limit = 200}) async {
    final rows = await _client
        .from('health_logs')
        .select()
        .eq('tank_id', tankId)
        .order('observed_at', ascending: false)
        .limit(limit);
    return rows.map(HealthLog.fromJson).toList();
  }

  Future<HealthLog> addLog(HealthLog log) async {
    final row =
        await _client.from('health_logs').insert(log.toInsert()).select().single();
    return HealthLog.fromJson(row);
  }

  Future<void> deleteLog(String id) =>
      _client.from('health_logs').delete().eq('id', id);
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.watch(supabaseClientProvider));
});

/// Health journal entries for a tank, newest first.
final healthLogsProvider =
    FutureProvider.family<List<HealthLog>, String>((ref, tankId) async {
  return ref.watch(healthRepositoryProvider).listLogs(tankId);
});
