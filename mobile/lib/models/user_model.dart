class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int streakDays;
  final int xp;
  final int coins;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.streakDays = 0,
    this.xp = 0,
    this.coins = 0,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 1,
      name: json['name'] ?? 'Learner',
      email: json['email'] ?? '',
      role: json['role'] ?? 'learner',
      streakDays: json['streak_days'] ?? json['streak'] ?? 0,
      xp: json['xp'] ?? json['xp_points'] ?? 0,
      coins: json['coins'] ?? json['gems'] ?? 0,
      avatar: json['avatar'] ?? json['profile_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'streak_days': streakDays,
      'streak': streakDays,
      'xp': xp,
      'xp_points': xp,
      'coins': coins,
      'gems': coins,
      'avatar': avatar,
    };
  }
}
