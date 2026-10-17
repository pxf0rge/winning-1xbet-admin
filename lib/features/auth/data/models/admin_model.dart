import '../../domain/entities/admin.dart';

class AdminModel extends Admin {
  const AdminModel({required super.username});

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(username: json['username'] ?? '');
  }
}
