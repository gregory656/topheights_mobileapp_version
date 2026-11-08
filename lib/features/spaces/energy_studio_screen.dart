import 'package:flutter/material.dart';
import '../../app/top_heights_theme.dart';
import '../../data/energy_calculator.dart';
import '../../data/energy_repository.dart';

class EnergyStudioScreen extends StatefulWidget {
  const EnergyStudioScreen({super.key});
  @override
  State<EnergyStudioScreen> createState() => _EnergyStudioScreenState();
}

class _EnergyStudioScreenState extends State<EnergyStudioScreen>
    with SingleTickerProviderStateMixin {
  final _repo = EnergyRepository();
  final _form = GlobalKey<FormState>();
  final _location = TextEditingController(),
      _budget = TextEditingController(),
      _bill = TextEditingController(),
      _scenarioName = TextEditingController(text: 'My first energy picture');
  late final _tabs = TabController(length: 2, vsync: this);
  List<EnergyLoad> _loads = [];
  List<AppliancePreset> _presets = [];
  List<SavedAssessment> _saved = [];
  String _property = 'Home',
      _useCase = 'Everyday living',
      _grid = 'Connected to grid',
      _billBasis = 'Not entered';
  int _backupHours = 8;
  double _nightShare = .55;
  bool _busy = true;
  String? _editingId;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _location.dispose();
    _budget.dispose();
    _bill.dispose();
    _scenarioName.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final a = await Future.wait([_repo.presets(), _repo.assessments()]);
    if (mounted) {
      setState(() {
        _presets = a[0] as List<AppliancePreset>;
        _saved = a[1] as List<SavedAssessment>;
        _busy = false;
      });
    }
  }

  EnergyCalculation get _result => calculateEnergy(
    _loads,
    backupHours: _backupHours,
    nighttimeShare: _nightShare,
  );
  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();
  void _toast(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Map<String, Object?> _payload() => {
    'property': _property,
    'useCase': _useCase,
    'grid': _grid,
    'location': _location.text.trim(),
    'budget': _budget.text.trim(),
    'bill': _bill.text.trim(),
    'billBasis': _billBasis,
    'backupHours': _backupHours,
    'nightShare': _nightShare,
    'loads': _loads.map((l) => l.toJson()).toList(),
  };
  void _resume(SavedAssessment a) {
    final p = a.payload;
    setState(() {
      _editingId = a.id;
      _scenarioName.text = a.name;
      _property = p['property'] as String? ?? 'Home';
      _useCase = p['useCase'] as String? ?? 'Everyday living';
      _grid = p['grid'] as String? ?? 'Connected to grid';
      _location.text = p['location'] as String? ?? '';
      _budget.text = p['budget'] as String? ?? '';
      _bill.text = p['bill'] as String? ?? '';
      _billBasis = p['billBasis'] as String? ?? 'Not entered';
      _backupHours = p['backupHours'] as int? ?? 8;
      _nightShare = (p['nightShare'] as num? ?? .55).toDouble();
      _loads = a.loads;
    });
    _tabs.animateTo(0);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      _tabs.animateTo(0);
      return;
    }
    if (_loads.isEmpty) {
      _toast('Add at least one appliance to save a useful scenario.');
      return;
    }
    try {
      calculateEnergy(
        _loads,
        backupHours: _backupHours,
        nighttimeShare: _nightShare,
      );
      await _repo.save(
        id: _editingId,
        name: _scenarioName.text,
        payload: _payload(),
      );
      setState(() => _editingId = null);
      await _reload();
      _tabs.animateTo(1);
      _toast('Scenario saved on this device.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  Future<void> _addLoad([EnergyLoad? old]) async {
    final name = TextEditingController(text: old?.name ?? ''),
        watts = TextEditingController(text: old?.watts.toString() ?? ''),
        qty = TextEditingController(text: old?.quantity.toString() ?? '1'),
        hours = TextEditingController(text: old?.hoursPerDay.toString() ?? '4');
    var basis = old?.basis ?? WattageBasis.userEstimated;
    var critical = old?.critical ?? false;
    final preset = await showModalBottomSheet<EnergyLoad>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  old == null ? 'Add a load' : 'Tune this load',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Every number has a source. Defaults are prompts to replace, never measurements.',
                ),
                const SizedBox(height: 14),
                if (old == null && _presets.isNotEmpty)
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _presets
                        .map(
                          (p) => ActionChip(
                            label: Text('${p.name} · ${p.watts} W'),
                            onPressed: () => setD(() {
                              name.text = p.name;
                              watts.text = '${p.watts}';
                              basis = p.basis;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Appliance name',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: watts,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rated power (W)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hours,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Hours used per day',
                    helperText: '0 to 24 hours',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<WattageBasis>(
                  initialValue: basis,
                  decoration: const InputDecoration(
                    labelText: 'Wattage source',
                  ),
                  items: WattageBasis.values
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(basisLabel(b)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => basis = v!),
                ),
                CheckboxListTile(
                  value: critical,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep this running during an outage'),
                  subtitle: const Text('Include in the critical-load view'),
                  onChanged: (v) => setD(() => critical = v == true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final w = int.tryParse(watts.text),
                          q = int.tryParse(qty.text),
                          h = double.tryParse(hours.text);
                      if (name.text.trim().isEmpty ||
                          w == null ||
                          q == null ||
                          h == null ||
                          w < 1 ||
                          w > 100000 ||
                          q < 1 ||
                          q > 999 ||
                          h < 0 ||
                          h > 24) {
                        _toast(
                          'Use a name, 1–100,000 W, quantity 1–999, and hours from 0 to 24.',
                        );
                        return;
                      }
                      Navigator.pop(
                        ctx,
                        EnergyLoad(
                          name: name.text.trim(),
                          quantity: q,
                          watts: w,
                          hoursPerDay: h,
                          critical: critical,
                          basis: basis,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Add to energy picture'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (preset != null) {
      setState(() {
        if (old == null) {
          _loads.add(preset);
        } else {
          _loads[_loads.indexOf(old)] = preset;
        }
      });
    }
  }

  Future<void> _editPreset([AppliancePreset? old]) async {
    final n = TextEditingController(text: old?.name ?? ''),
        w = TextEditingController(text: old?.watts.toString() ?? '');
    var basis = old?.basis ?? WattageBasis.userEstimated;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          title: Text(
            old == null ? 'Create an appliance card' : 'Edit appliance card',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: n,
                decoration: const InputDecoration(labelText: 'Appliance'),
              ),
              TextField(
                controller: w,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Typical watts (W)',
                ),
              ),
              DropdownButtonFormField<WattageBasis>(
                initialValue: basis,
                items: WattageBasis.values
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(basisLabel(b)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => sd(() => basis = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save card'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await _repo.savePreset(
          AppliancePreset(old?.id ?? _uid(), n.text, int.parse(w.text), basis),
        );
        await _reload();
      } catch (e) {
        _toast(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F4),
    appBar: AppBar(
      title: const Text('Energy Studio'),
      actions: [
        IconButton(
          tooltip: 'Edit appliance library',
          onPressed: _manageLibrary,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(icon: Icon(Icons.bolt_rounded), text: 'Build a picture'),
          Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Saved scenarios'),
        ],
      ),
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [_builder(), _scenarioList()],
          ),
  );
  Widget _builder() {
    final c = _result;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandColors.forestDeep,
                  BrandColors.forest,
                  Color(0xFF347253),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENERGY STUDIO · FIELD NOTES',
                  style: TextStyle(
                    color: BrandColors.leaf,
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'Start with the life\nyour energy supports.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'A transparent first sketch. Every estimate stays editable.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      color: BrandColors.leaf,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Private to this device',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            '01',
            'Place & purpose',
            'A little context makes the load list make sense.',
          ),
          const SizedBox(height: 10),
          _profileCard(),
          const SizedBox(height: 21),
          _section(
            '02',
            'Appliance constellation',
            'Name the things that make your place work.',
          ),
          const SizedBox(height: 4),
          _loadList(),
          const SizedBox(height: 21),
          _section(
            '03',
            'Shape the scenario',
            'Try a gentler night or a longer backup window.',
          ),
          const SizedBox(height: 10),
          _assumptionCard(),
          const SizedBox(height: 20),
          _section(
            '04',
            'The working, shown',
            'Simple screening arithmetic; no hidden efficiency factor.',
          ),
          const SizedBox(height: 10),
          _resultsCard(c),
          const SizedBox(height: 11),
          _confidenceCard(),
          const SizedBox(height: 21),
          _section(
            '05',
            'Keep this version',
            'Save a named snapshot; make another to compare what-if changes.',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _scenarioName,
            decoration: const InputDecoration(labelText: 'Scenario name'),
            validator: (v) => v!.trim().isEmpty ? 'Name this scenario' : null,
          ),
          const SizedBox(height: 11),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(
              _editingId == null
                  ? 'Save this scenario'
                  : 'Update saved scenario',
            ),
          ),
          if (_editingId != null)
            TextButton(
              onPressed: () => setState(() {
                _editingId = null;
                _scenarioName.text = 'What if…';
              }),
              child: const Text('Save as a new version instead'),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _profileCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _property,
            decoration: const InputDecoration(labelText: 'Property type'),
            items: const [
              'Home',
              'Shop or office',
              'Farm',
              'Workshop',
              'School or clinic',
              'Other',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => _property = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _useCase,
            decoration: const InputDecoration(
              labelText: 'What should energy support?',
            ),
            items: const [
              'Everyday living',
              'Reliable backup',
              'Reduce grid use',
              'New build',
              'Business continuity',
              'Other',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => _useCase = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _grid,
            decoration: const InputDecoration(labelText: 'Grid access'),
            items: const [
              'Connected to grid',
              'No grid connection',
              'Connection uncertain',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => _grid = v!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location entered by you',
              hintText: 'Town, county, or site area',
              helperText:
                  'No location lookup or solar-resource estimate is used.',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _budget,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Budget range (optional)',
              hintText: 'KES, or a range you have in mind',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _billBasis,
            decoration: const InputDecoration(
              labelText: 'Current electricity use',
            ),
            items: const [
              'Not entered',
              'Known from bill',
              'Estimated by me',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => _billBasis = v!),
          ),
          if (_billBasis != 'Not entered') ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _bill,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'kWh per month',
                suffixText: 'kWh / month',
                helperText: 'Enter a value only if you know or estimate it.',
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _loadList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '${_loads.length} entries · sources kept with every watt value',
              style: const TextStyle(color: BrandColors.muted, fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: () => _editPreset(),
            icon: const Icon(Icons.library_add_outlined),
            label: const Text('New library card'),
          ),
        ],
      ),
      if (_loads.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 32,
                  color: BrandColors.forest,
                ),
                const SizedBox(height: 8),
                const Text('Your first appliance is the beginning.'),
                const SizedBox(height: 6),
                const Text(
                  'Pick a library prompt, then tune it to the label or your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BrandColors.muted),
                ),
                const SizedBox(height: 11),
                OutlinedButton.icon(
                  onPressed: () => _addLoad(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add an appliance'),
                ),
              ],
            ),
          ),
        )
      else
        ..._loads.map(
          (l) => Card(
            child: ListTile(
              onTap: () => _addLoad(l),
              leading: CircleAvatar(
                backgroundColor: l.critical
                    ? const Color(0xFFFFF0D7)
                    : BrandColors.paleGreen,
                child: Icon(
                  l.critical
                      ? Icons.bolt_rounded
                      : Icons.electrical_services_rounded,
                  color: BrandColors.forest,
                ),
              ),
              title: Text(
                '${l.quantity} × ${l.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${l.watts} W · ${l.hoursPerDay} h/day · ${basisLabel(l.basis)}${l.critical ? ' · critical' : ''}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${l.dailyWh} Wh',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _loads.remove(l)),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (_loads.isNotEmpty)
        OutlinedButton.icon(
          onPressed: () => _addLoad(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add another load'),
        ),
    ],
  );

  Widget _assumptionCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nights_stay_outlined, color: BrandColors.forest),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Backup duration · $_backupHours hours',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Slider(
            value: _backupHours.toDouble(),
            min: 0,
            max: 72,
            divisions: 24,
            label: '$_backupHours h',
            onChanged: (v) => setState(() => _backupHours = v.round()),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.brightness_4_outlined,
                color: BrandColors.forest,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Energy placed at night · ${(_nightShare * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Slider(
            value: _nightShare,
            min: 0,
            max: 1,
            divisions: 20,
            label: '${(_nightShare * 100).round()}%',
            onChanged: (v) => setState(() => _nightShare = v),
          ),
          const Text(
            'Editable planning assumption. Backup energy scales the critical loads’ daily energy by this share and by backup hours ÷ 24.',
            style: TextStyle(color: BrandColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
  Widget _section(String n, String title, String sub) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: BrandColors.forest,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(
              sub,
              style: const TextStyle(color: BrandColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _resultsCard(EnergyCalculation c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions_rounded, color: BrandColors.forest),
              const SizedBox(width: 8),
              Text(
                'YOUR FIELD CALCULATION',
                style: TextStyle(
                  color: BrandColors.forest,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric(
                  c.dailyKwh.toStringAsFixed(2),
                  'kWh / day',
                  Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _metric(
                  c.peakWatts.toString(),
                  'W simultaneous*',
                  Icons.bolt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _metric(
                  (c.criticalDailyWh / 1000).toStringAsFixed(2),
                  'critical kWh / day',
                  Icons.health_and_safety_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _metric(
                  '${c.backupEnergyWh} Wh',
                  'backup energy*',
                  Icons.battery_charging_full_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Daily Wh = quantity × watts × hours for each load. Peak assumes every listed appliance runs at once; it is a conservative sum, not a measured peak. Backup Wh = critical daily Wh × night share × backup hours ÷ 24.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: BrandColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '* Energy estimates are not inverter, battery, panel or safety specifications.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: BrandColors.forest,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _metric(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: BrandColors.paper,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BrandColors.forest, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: BrandColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: BrandColors.muted),
        ),
      ],
    ),
  );
  Widget _confidenceCard() {
    final unknowns = <String>[];
    if (_loads.any(
      (l) =>
          l.basis == WattageBasis.illustrativeDefault ||
          l.basis == WattageBasis.userEstimated,
    )) {
      unknowns.add('Some wattages are illustrative or estimated');
    }
    if (_loads.any((l) => l.critical)) {
      unknowns.add('Starting surge is not captured');
    } else {
      unknowns.add('Critical loads have not been marked');
    }
    if (_location.text.trim().isEmpty) {
      unknowns.add('Location is missing; solar resource is unknown');
    }
    unknowns.add('Roof area, orientation and shading have not been assessed');
    unknowns.add('A qualified professional should review the site and design');
    return Card(
      color: const Color(0xFFFFFBF1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.radar_rounded, color: Color(0xFF9D6825)),
                SizedBox(width: 8),
                Text(
                  'CONFIDENCE & OPEN QUESTIONS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final note in unknowns)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: Color(0xFF9D6825),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(note, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const Text(
              'Treat this as a conversation starter, not a recommendation or certified design.',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioList() {
    if (_saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 31,
                backgroundColor: BrandColors.paleGreen,
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: BrandColors.forest,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your energy atlas is blank',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Save a scenario to begin comparing possibilities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BrandColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _tabs.animateTo(0),
                icon: const Icon(Icons.add),
                label: const Text('Build a scenario'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: BrandColors.forestDeep,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'SCENARIO ATLAS\nCompare daily demand, simultaneous load and assumptions. Each card is a saved snapshot on this device.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 13),
        for (final a in _saved) _scenarioCard(a),
      ],
    );
  }

  Widget _scenarioCard(SavedAssessment a) {
    final p = a.payload;
    final calc = calculateEnergy(
      a.loads,
      backupHours: p['backupHours'] as int? ?? 8,
      nighttimeShare: (p['nightShare'] as num? ?? .55).toDouble(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'open') _resume(a);
                    if (v == 'delete') {
                      await _repo.delete(a.id);
                      await _reload();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'open', child: Text('Open and edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete scenario'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${p['property'] ?? 'Place'} · ${p['useCase'] ?? 'Use case'} · ${a.loads.length} loads',
              style: const TextStyle(color: BrandColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    calc.dailyKwh.toStringAsFixed(2),
                    'kWh/day',
                    Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    '${calc.peakWatts} W',
                    'peak sum',
                    Icons.bolt_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    '${p['backupHours'] ?? 8} h',
                    'backup setting',
                    Icons.battery_4_bar_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              'Saved ${a.updatedAt.substring(0, 16).replaceFirst('T', ' ')} UTC · ${p['grid'] ?? 'Grid access not entered'}',
              style: const TextStyle(color: BrandColors.muted, fontSize: 10),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _resume(a),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Open scenario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageLibrary() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .76,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Appliance library',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editPreset();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Illustrative watts are starting prompts only. Edit them with measured or label values for your site.',
                  style: TextStyle(color: BrandColors.muted),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: _presets
                      .map(
                        (p) => ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.watts} W · ${basisLabel(p.basis)}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                Navigator.pop(ctx);
                                _editPreset(p);
                              }
                              if (v == 'delete') {
                                await _repo.deletePreset(p.id);
                                await _reload();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) _manageLibrary();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Remove'),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _reload();
  }
}
