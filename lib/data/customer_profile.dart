class CustomerProfile {
  const CustomerProfile({
    required this.displayName,
    required this.businessName,
    required this.useTopBossGreeting,
  });
  final String displayName;
  final String businessName;
  final bool useTopBossGreeting;

  factory CustomerProfile.fromMap(Map<String, Object?> map) => CustomerProfile(
    displayName: map['display_name'] as String? ?? '',
    businessName: map['business_name'] as String? ?? '',
    useTopBossGreeting: (map['use_top_boss_greeting'] as int? ?? 1) == 1,
  );

  Map<String, Object?> toMap({required String updatedAt}) => {
    'id': 1,
    'display_name': displayName.trim(),
    'business_name': businessName.trim(),
    'use_top_boss_greeting': useTopBossGreeting ? 1 : 0,
    'updated_at': updatedAt,
  };

  String get greetingName =>
      displayName.trim().isEmpty ? 'there' : displayName.trim();
}
