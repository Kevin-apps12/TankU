import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/tank_repository.dart';
import '../domain/habitat.dart';
import '../domain/tank.dart';

/// Sub-type options offered per habitat.
const _tankTypesByHabitat = <String, List<String>>{
  Habitat.saltwater: [
    'Mixed Reef',
    'SPS Dominant',
    'LPS Dominant',
    'Soft Coral',
    'FOWLR',
    'Fish Only',
    'Nano',
    'Quarantine',
  ],
  Habitat.freshwater: [
    'Community',
    'Planted',
    'Cichlid',
    'Betta',
    'Shrimp',
    'Goldfish',
    'Nano',
    'Quarantine',
  ],
  Habitat.pond: [
    'Koi',
    'Goldfish',
    'Mixed',
    'Wildlife',
  ],
};

class TankFormScreen extends ConsumerStatefulWidget {
  const TankFormScreen({super.key, this.tankId});
  final String? tankId;

  bool get isEditing => tankId != null;

  @override
  ConsumerState<TankFormScreen> createState() => _TankFormScreenState();
}

class _TankFormScreenState extends ConsumerState<TankFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _volume = TextEditingController();
  final _notes = TextEditingController();
  String _habitat = Habitat.saltwater;
  String? _type;
  DateTime? _startedOn;
  bool _useGallons = false;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _volume.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Tank tank) {
    if (_initialized) return;
    _initialized = true;
    _name.text = tank.name;
    _volume.text = tank.volumeLiters.toStringAsFixed(0);
    _notes.text = tank.notes ?? '';
    _habitat = tank.habitat;
    _type = tank.tankType;
    _startedOn = tank.startedOn;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final entered = double.parse(_volume.text.trim());
    final liters = _useGallons ? entered / 0.264172 : entered;
    try {
      final repo = ref.read(tankRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateTank(widget.tankId!, {
          'name': _name.text.trim(),
          'volume_liters': liters,
          'habitat': _habitat,
          'tank_type': _type,
          'started_on': _startedOn?.toIso8601String(),
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        });
        ref.invalidate(tankProvider(widget.tankId!));
      } else {
        await repo.createTank(Tank(
          id: '',
          name: _name.text.trim(),
          volumeLiters: liters,
          habitat: _habitat,
          tankType: _type,
          startedOn: _startedOn,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ));
      }
      ref.invalidate(tanksProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // When editing, load the tank to prefill once.
    if (widget.isEditing && !_initialized) {
      final async = ref.watch(tankProvider(widget.tankId!));
      return async.when(
        loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator())),
        error: (e, _) =>
            Scaffold(body: Center(child: Text('$e'))),
        data: (tank) {
          _hydrate(tank);
          return _form(context);
        },
      );
    }
    return _form(context);
  }

  Widget _form(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit tank' : 'New tank'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tank name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _volume,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                          labelText:
                              'Volume (${_useGallons ? 'gal' : 'L'})'),
                      validator: (v) {
                        final d = double.tryParse(v?.trim() ?? '');
                        return (d == null || d <= 0) ? 'Enter a number' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    isSelected: [!_useGallons, _useGallons],
                    onPressed: (i) => setState(() => _useGallons = i == 1),
                    borderRadius: BorderRadius.circular(8),
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 48),
                    children: const [Text('L'), Text('gal')],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Habitat',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: Habitat.freshwater,
                    icon: Icon(Icons.water_drop_outlined),
                    label: Text('Freshwater'),
                  ),
                  ButtonSegment(
                    value: Habitat.saltwater,
                    icon: Icon(Icons.waves),
                    label: Text('Saltwater'),
                  ),
                  ButtonSegment(
                    value: Habitat.pond,
                    icon: Icon(Icons.forest_outlined),
                    label: Text('Pond'),
                  ),
                ],
                selected: {_habitat},
                onSelectionChanged: (s) => setState(() {
                  _habitat = s.first;
                  // Drop a sub-type that doesn't belong to the new habitat.
                  final allowed = _tankTypesByHabitat[_habitat] ?? const [];
                  if (_type != null && !allowed.contains(_type)) _type = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tank type'),
                items: (_tankTypesByHabitat[_habitat] ?? const [])
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline)),
                title: const Text('Started on'),
                subtitle: Text(_startedOn == null
                    ? 'Not set'
                    : _startedOn!.toLocal().toString().split(' ').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startedOn ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _startedOn = picked);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditing ? 'Save changes' : 'Create tank'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
