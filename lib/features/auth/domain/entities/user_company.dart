/// Empresa a la que tiene acceso el usuario (`companies[]` del login).
class UserCompany {
  final String id;
  final String name;
  const UserCompany({required this.id, required this.name});

  factory UserCompany.fromJson(Map<String, dynamic> json) => UserCompany(
        id: (json['id'] ?? json['Id'] ?? '').toString(),
        name: (json['name'] ?? json['Name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
