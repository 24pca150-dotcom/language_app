import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'assessment_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  // Daily Reminder Settings State
  bool _reminderEnabled = true;
  String _reminderTime = '07:00 PM';
  int _dailyGoalMinutes = 10;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReminderSettings();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.getUserProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _reminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
        _reminderTime = prefs.getString('daily_reminder_time') ?? '07:00 PM';
        _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 10;
      });
    }
  }

  Future<void> _saveReminderSettings(bool enabled, String time, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);
    await prefs.setString('daily_reminder_time', time);
    await prefs.setInt('daily_goal_minutes', minutes);

    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        _reminderTime = time;
        _dailyGoalMinutes = minutes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '🔔 Daily $minutes-min practice reminder set for $time!'
                : '🔕 Daily practice reminders turned off.',
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.name ?? '');
    final emailController = TextEditingController(text: _user?.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset > 0 ? bottomInset + 20 : 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  hintText: 'Enter your email',
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newEmail = emailController.text.trim();
                    if (newName.isEmpty) return;

                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    final updated = await AuthService.updateUserProfile(
                      name: newName,
                      email: newEmail,
                    );
                    if (mounted) {
                      setState(() => _user = updated);
                      nav.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Profile updated successfully!'),
                          backgroundColor: AppTheme.secondary,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Profile Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

  void _showDailyReminderDialog() {
    bool tempEnabled = _reminderEnabled;
    String tempTime = _reminderTime;
    int tempGoal = _dailyGoalMinutes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Practice Reminder',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'Build a consistent 10-minute daily learning habit',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Motivation Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Spending just 10 minutes a day on LangNest boosts vocabulary retention by 80% and keeps your streak alive!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notification Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily Notification Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Receive a reminder notification every day', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                value: tempEnabled,
                activeThumbColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() => tempEnabled = val);
                },
              ),
              const Divider(height: 24),

              // Daily Goal Selection (10 min use requested by user)
              const Text('Daily Goal (Minutes / Day):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 15, 20].map((mins) {
                  final isSelected = tempGoal == mins;
                  return ChoiceChip(
                    label: Text(
                      mins == 10 ? '⭐ $mins Mins (Recommended)' : '$mins Mins',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setModalState(() => tempGoal = mins),
                    selectedColor: const Color(0xFFD97706),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? const Color(0xFFD97706) : AppTheme.cardBorder),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Reminder Time Selection
              const Text('Reminder Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['07:00 AM', '01:00 PM', '07:00 PM', '08:30 PM', '09:00 PM'].map((t) {
                  final isSelected = tempTime == t;
                  return ChoiceChip(
                    label: Text(
                      t,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setModalState(() => tempTime = t),
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.cardBorder),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveReminderSettings(tempEnabled, tempTime, tempGoal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Reminder & Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showLearningProgressDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Color(0xFF10B981), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Learning Progress & Analytics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Comprehensive breakdown of your English learning journey',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Progress Summary Cards
            Row(
              children: [
                _buildProgressMetric('14', 'Lessons Done', const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                _buildProgressMetric('92%', 'Quiz Accuracy', const Color(0xFF10B981)),
                const SizedBox(width: 10),
                _buildProgressMetric('$_dailyGoalMinutes min', 'Daily Target', const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 20),

            // Level Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Course Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('85% (Level 1 Cleared)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close Report', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetric(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.danger),
            SizedBox(width: 10),
            Text('Logout Confirmation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of LangNest mobile app?',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AuthService.logout();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Yes, Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final user = _user!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.navBarGreen,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.navBarGreenBorder, width: 1.2),
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF14361F)),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Color(0xFF14361F), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF14361F)),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile identity
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.boxColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.boxBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit Profile Button
                      OutlinedButton.icon(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                _buildStatItem('🔥 ${user.streakDays}', 'Day Streak'),
                const SizedBox(width: 10),
                _buildStatItem('⚡ ${user.xp}', 'Total XP'),
                const SizedBox(width: 10),
                _buildStatItem('🪙 ${user.coins}', 'Coins'),
              ],
            ),
            const SizedBox(height: 24),

            // Profile settings
            Container(
              decoration: BoxDecoration(
                color: AppTheme.boxColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.boxBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOptionTile(
                    icon: Icons.history_edu_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Assessment History',
                    subtitle: 'View your quiz & exam scores, past attempts & reports',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssessmentHistoryScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),

                  _buildOptionTile(
                    icon: Icons.insights_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Learning Progress & Reports',
                    subtitle: 'Track completed lessons, accuracy % & XP growth',
                    onTap: _showLearningProgressDialog,
                  ),
                  const Divider(height: 1, indent: 60),

                  _buildOptionTile(
                    icon: Icons.alarm_on_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: 'Daily Practice Reminders',
                    subtitle: '$_dailyGoalMinutes-Min Daily Habit • Daily at $_reminderTime',
                    badge: '${_dailyGoalMinutes}M / DAY',
                    onTap: _showDailyReminderDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 🔴 LOGOUT BUTTON AT THE BOTTOM
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.danger.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.boxBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    String? badge,
  }) {
    final color = iconColor ?? AppTheme.textPrimary;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}
