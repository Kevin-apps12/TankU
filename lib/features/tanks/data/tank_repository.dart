import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/dosing.dart';
import '../domain/equipment.dart';
import '../domain/feeding.dart';
import '../domain/livestock.dart';
import '../domain/tank.dart';

class TankRepository {
  TankRepository(this._client);
  final SupabaseClient _client;

  // ---- Tanks ----
  Future<List<Tank>> listTanks() async {
    final rows = await _client
        .from('tanks')
        .select()
        .order('created_at', ascending: false);
    return rows.map(Tank.fromJson).toList();
  }

  Future<Tank> getTank(String id) async {
    final row = await _client.from('tanks').select().eq('id', id).single();
    return Tank.fromJson(row);
  }

  Future<Tank> createTank(Tank tank) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('tanks')
        .insert({...tank.toInsert(), 'user_id': userId})
        .select()
        .single();
    return Tank.fromJson(row);
  }

  Future<Tank> updateTank(String id, Map<String, dynamic> changes) async {
    final row =
        await _client.from('tanks').update(changes).eq('id', id).select().single();
    return Tank.fromJson(row);
  }

  Future<void> deleteTank(String id) =>
      _client.from('tanks').delete().eq('id', id);

  // ---- Equipment ----
  Future<List<Equipment>> listEquipment(String tankId) async {
    final rows =
        await _client.from('equipment').select().eq('tank_id', tankId).order('name');
    return rows.map(Equipment.fromJson).toList();
  }

  Future<Equipment> addEquipment(Equipment e) async {
    final row =
        await _client.from('equipment').insert(e.toInsert()).select().single();
    return Equipment.fromJson(row);
  }

  Future<void> deleteEquipment(String id) =>
      _client.from('equipment').delete().eq('id', id);

  // ---- Livestock ----
  Future<List<Livestock>> listLivestock(String tankId) async {
    final rows =
        await _client.from('livestock').select().eq('tank_id', tankId).order('name');
    return rows.map(Livestock.fromJson).toList();
  }

  Future<Livestock> addLivestock(Livestock l) async {
    final row =
        await _client.from('livestock').insert(l.toInsert()).select().single();
    return Livestock.fromJson(row);
  }

  Future<void> deleteLivestock(String id) =>
      _client.from('livestock').delete().eq('id', id);

  // ---- Dosing ----
  Future<List<Dosing>> listDosing(String tankId) async {
    final rows =
        await _client.from('dosing').select().eq('tank_id', tankId).order('product');
    return rows.map(Dosing.fromJson).toList();
  }

  Future<Dosing> addDosing(Dosing d) async {
    final row = await _client.from('dosing').insert(d.toInsert()).select().single();
    return Dosing.fromJson(row);
  }

  Future<void> deleteDosing(String id) =>
      _client.from('dosing').delete().eq('id', id);

  // ---- Feeding ----
  Future<List<Feeding>> listFeeding(String tankId) async {
    final rows =
        await _client.from('feedings').select().eq('tank_id', tankId).order('food');
    return rows.map(Feeding.fromJson).toList();
  }

  Future<Feeding> addFeeding(Feeding f) async {
    final row =
        await _client.from('feedings').insert(f.toInsert()).select().single();
    return Feeding.fromJson(row);
  }

  Future<void> deleteFeeding(String id) =>
      _client.from('feedings').delete().eq('id', id);
}

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  return TankRepository(ref.watch(supabaseClientProvider));
});

/// All tanks for the current user. Auto-refetches when auth changes.
final tanksProvider = FutureProvider<List<Tank>>((ref) async {
  ref.watch(currentUserProvider); // rebuild on login/logout
  return ref.watch(tankRepositoryProvider).listTanks();
});

final tankProvider = FutureProvider.family<Tank, String>((ref, id) async {
  return ref.watch(tankRepositoryProvider).getTank(id);
});

final equipmentProvider =
    FutureProvider.family<List<Equipment>, String>((ref, tankId) async {
  return ref.watch(tankRepositoryProvider).listEquipment(tankId);
});

final livestockProvider =
    FutureProvider.family<List<Livestock>, String>((ref, tankId) async {
  return ref.watch(tankRepositoryProvider).listLivestock(tankId);
});

final dosingProvider =
    FutureProvider.family<List<Dosing>, String>((ref, tankId) async {
  return ref.watch(tankRepositoryProvider).listDosing(tankId);
});

final feedingProvider =
    FutureProvider.family<List<Feeding>, String>((ref, tankId) async {
  return ref.watch(tankRepositoryProvider).listFeeding(tankId);
});
