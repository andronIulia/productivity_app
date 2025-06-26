class AppUsage {
  final String packageName;
  final String name;
  final int minutes;
  final String? iconBase64;

  AppUsage({
    required this.packageName,
    required this.name,
    required this.minutes,
    this.iconBase64,
  });

  factory AppUsage.fromMap(String packageName, Map<String, dynamic> map) {
    return AppUsage(
      packageName: packageName,
      name: map['name'] ?? packageName,
      minutes: map['minutes'] ?? 0,
      iconBase64: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'minutes': minutes, 'icon': iconBase64};
  }
}
