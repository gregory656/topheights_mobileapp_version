/// Source of a wattage entry. Defaults are examples, never measurements.
enum WattageBasis { measured, labelRead, userEstimated, illustrativeDefault }

String basisLabel(WattageBasis basis) => switch (basis) {
  WattageBasis.measured => 'Measured',
  WattageBasis.labelRead => 'Read from label',
  WattageBasis.userEstimated => 'Your estimate',
  WattageBasis.illustrativeDefault => 'Illustrative default',
};

class EnergyLoad {
  const EnergyLoad({
    required this.name,
    required this.quantity,
    required this.watts,
    required this.hoursPerDay,
    required this.critical,
    required this.basis,
  });
  final String name;
  final int quantity, watts;
  final double hoursPerDay;
  final bool critical;
  final WattageBasis basis;
  int get dailyWh => (quantity * watts * hoursPerDay).round();
  Map<String, Object?> toJson() => {
    'name': name,
    'quantity': quantity,
    'watts': watts,
    'hoursPerDay': hoursPerDay,
    'critical': critical,
    'basis': basis.name,
  };
  factory EnergyLoad.fromJson(Map<String, Object?> map) => EnergyLoad(
    name: map['name'] as String,
    quantity: map['quantity'] as int,
    watts: map['watts'] as int,
    hoursPerDay: (map['hoursPerDay'] as num).toDouble(),
    critical: map['critical'] as bool,
    basis: WattageBasis.values.firstWhere(
      (v) => v.name == map['basis'],
      orElse: () => WattageBasis.illustrativeDefault,
    ),
  );
}

class EnergyCalculation {
  const EnergyCalculation({
    required this.dailyWh,
    required this.peakWatts,
    required this.criticalPeakWatts,
    required this.criticalDailyWh,
    required this.backupEnergyWh,
  });
  final int dailyWh,
      peakWatts,
      criticalPeakWatts,
      criticalDailyWh,
      backupEnergyWh;
  double get dailyKwh => dailyWh / 1000;
}

/// Deterministic screening arithmetic, intentionally not a system-sizing tool.
/// Daily energy = quantity × rated W × hours/day for each entry.
/// Peak assumes every listed appliance could run at once (no diversity factor).
/// Critical backup energy = critical loads' daily Wh × nighttime share × backup days.
EnergyCalculation calculateEnergy(
  List<EnergyLoad> loads, {
  required int backupHours,
  required double nighttimeShare,
}) {
  if (backupHours < 0 || backupHours > 168) {
    throw ArgumentError('Backup duration must be between 0 and 168 hours.');
  }
  if (nighttimeShare < 0 || nighttimeShare > 1) {
    throw ArgumentError('Nighttime share must be from 0% to 100%.');
  }
  for (final load in loads) {
    if (load.name.trim().isEmpty ||
        load.quantity < 1 ||
        load.quantity > 999 ||
        load.watts < 1 ||
        load.watts > 100000 ||
        !load.hoursPerDay.isFinite ||
        load.hoursPerDay < 0 ||
        load.hoursPerDay > 24) {
      throw ArgumentError(
        'Each load needs a name, valid quantity, watts and hours (0–24).',
      );
    }
  }
  final daily = loads.fold<int>(0, (sum, l) => sum + l.dailyWh);
  final peak = loads.fold<int>(0, (sum, l) => sum + l.quantity * l.watts);
  final critical = loads.where((l) => l.critical).toList();
  final criticalWh = critical.fold<int>(0, (sum, l) => sum + l.dailyWh);
  final criticalPeak = critical.fold<int>(
    0,
    (sum, l) => sum + l.quantity * l.watts,
  );
  final backup = (criticalWh * nighttimeShare * (backupHours / 24)).round();
  return EnergyCalculation(
    dailyWh: daily,
    peakWatts: peak,
    criticalPeakWatts: criticalPeak,
    criticalDailyWh: criticalWh,
    backupEnergyWh: backup,
  );
}
