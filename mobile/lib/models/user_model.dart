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
    this.streakDays = 5,
    this.xp = 340,
    this.coins = 120,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 1,
      name: json['name'] ?? 'Learner',
      email: json['email'] ?? '',
      role: json['role'] ?? 'learner',
      streakDays: json['streak_days'] ?? 5,
      xp: json['xp'] ?? 340,
      coins: json['coins'] ?? 120,
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
      'xp': xp,
      'coins': coins,
      'avatar': avatar,
    };
  }
}
