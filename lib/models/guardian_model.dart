class Guardian {
  final String name;
  final String phone;

  Guardian({required this.name, required this.phone});

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      name: json['guardian_name'] ?? "",
      phone: json['guardian_phone'] ?? "",
    );
  }
}
