import '../services/api_service.dart';

class UserModel {
  final int     id;
  final String  name;
  final String  email;
  final String? phone;
  final String? avatar;
  final String  role;
  final String  apiToken;
  final String? jobTitle;   // ✅ field nyata
  final String? company;    // ✅ field nyata
  final String? bio;        // ✅ field nyata

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.apiToken,
    this.jobTitle,
    this.company,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:       json['id'],
      name:     json['name']      ?? '',
      email:    json['email']     ?? '',
      phone:    json['phone'],
      avatar:   json['avatar'],
      role:     json['role']      ?? 'user',
      apiToken: json['api_token'] ?? '',
      jobTitle: json['job_title'], // ✅ sesuai kolom di database (snake_case)
      company:  json['company'],
      bio:      json['bio'],
    );
  }

  /// ✅ URL lengkap untuk ditampilkan di Image widget
  /// Contoh: avatars/abc.jpg → http://10.0.2.2:8000/storage/avatars/abc.jpg
  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    if (avatar!.startsWith('http')) return avatar;
    
    // Ikuti baseUrl dari ApiService
    final base = ApiService.baseUrl.replaceAll('/api', '/storage/');
    return '$base$avatar';
  }
}