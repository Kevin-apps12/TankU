import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../tanks/data/tank_repository.dart';
import '../domain/parameter_reading.dart';
import '../domain/parameter_type.dart';

class ParameterRepository {
  ParameterRepository(this._client);
  final SupabaseClient _client;

  /// Readings for a tank, optionally filtered to one parameter, newest first.
  Future<List<ParameterReading>> listReadings(
    String tankId, {
    String? parameterKey,
    int limit = 500,
  }) async {
    var query = _client.from('parameter_readings').select().eq('tank_id', tankId);
    if (parameterKey != null) {
      query = query.eq('parameter_key', parameterKey);
    }
    final rows = await query.order('measured_at', ascending: false).limit(limit);
    return rows.map(ParameterReading.fromJson).toList();
  }

  Future<ParameterReading> addReading(ParameterReading reading) async {
    final row = await _client
        .from('parameter_readings')
        .insert(reading.toInsert())
        .select()
        .single();
    return ParameterReading.fromJson(row);
  }

  Future<void> deleteReading(String id) =>
      _client.from('parameter_readings').delete().eq('id', id);

  // ---- Custom parameter types ----
  Future<List<ParameterType>> listCustomTypes() async {
    final rows = await _client.from('parameter_types').select().order('label');
    return rows.map(ParameterType.fromJson).toList();
  }

  Future<ParameterType> addCustomType(ParameterType type) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('parameter_types')
        .insert({...type.toInsert(), 'user_id': userId})
        .select()
        .single();
    return ParameterType.fromJson(row);
  }
}

final parameterRepositoryProvider = Provider<ParameterRepository>((ref) {
  return ParameterRepository(ref.watch(supabaseClientProvider));
});

/// Custom parameter types defined by the user.
final customParameterTypesProvider =
    FutureProvider<List<ParameterType>>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(parameterRepositoryProvider).listCustomTypes();
});

/// Built-in (saltwater) + custom parameter types merged into one list.
/// Prefer [tankParameterTypesProvider], which respects the tank's habitat.
final allParameterTypesProvider = FutureProvider<List<ParameterType>>((ref) async {
  final custom = await ref.watch(customParameterTypesProvider.future);
  return [...ParameterCatalog.builtIns, ...custom];
});

/// The parameter set for a specific tank: its habitat's defaults plus any
/// user-defined custom types. This is what the log, chart and detail screens
/// should use so freshwater / saltwater / pond tanks track the right things.
final tankParameterTypesProvider =
    FutureProvider.family<List<ParameterType>, String>((ref, tankId) async {
  final tank = await ref.watch(tankProvider(tankId).future);
  final custom = await ref.watch(customParameterTypesProvider.future);
  return [...ParameterCatalog.forHabitat(tank.habitat), ...custom];
});

/// Readings for a tank filtered to one parameter (or all when key is null).
typedef ReadingsQuery = ({String tankId, String? parameterKey});

final readingsProvider =
    FutureProvider.family<List<ParameterReading>, ReadingsQuery>((ref, q) async {
  return ref
      .watch(parameterRepositoryProvider)
      .listReadings(q.tankId, parameterKey: q.parameterKey);
});
