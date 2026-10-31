import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class DailyRemindersScreen extends StatefulWidget {
  const DailyRemindersScreen({super.key});

  @override
  State<DailyRemindersScreen> createState() => _DailyRemindersScreenState();
}

class _DailyRemindersScreenState extends State<DailyRemindersScreen> {
  bool _reminderEnabled = true;
  String _reminderTime = '07:00 PM';
  int _dailyGoalMinutes = 10;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  String _selectedFrequency = 'Everyday';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _reminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
        _reminderTime = prefs.getString('daily_reminder_time') ?? '07:00 PM';
        _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 10;
        _vibrationEnabled = prefs.getBool('reminder_vibration') ?? true;
        _soundEnabled = prefs.getBool('reminder_sound') ?? true;
        _selectedFrequency = prefs.getString('reminder_frequency') ?? 'Everyday';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _reminderEnabled);
    await prefs.setString('daily_reminder_time', _reminderTime);
    await prefs.setInt('daily_goal_minutes', _dailyGoalMinutes);
    await prefs.setBool('reminder_vibration', _vibrationEnabled);
    await prefs.setBool('reminder_sound', _soundEnabled);
    await prefs.setString('reminder_frequency', _selectedFrequency);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _reminderEnabled
                      ? '🔔 Daily $_dailyGoalMinutes-min reminder saved for $_reminderTime ($_selectedFrequency)!'
                      : '🔕 Daily reminders turned off.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickCustomTime() async {
    TimeOfDay initial = const TimeOfDay(hour: 19, minute: 0);
    try {
      final parts = _reminderTime.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      initial = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _reminderTime = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Daily Practice Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Motivation Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF78350F), Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('🔥', style: TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Protect Your Learning Streak!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Practicing just 10 minutes a day boosts retention by 80% and unlocks exclusive championship badges.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFEF3C7),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Master Toggle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Practice Alerts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Send friendly reminders on your phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          activeThumbColor: AppTheme.accent,
                          onChanged: (val) {
                            setState(() => _reminderEnabled = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_reminderEnabled) ...[
                    // Daily Learning Goal Section
                    const Text(
                      'DAILY LEARNING GOAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How much time would you like to dedicate each day?',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildGoalChip(5, '5 Mins', 'Casual'),
                              _buildGoalChip(10, '10 Mins', 'Recommended ⭐'),
                              _buildGoalChip(15, '15 Mins', 'Regular'),
                              _buildGoalChip(20, '20 Mins', 'Dedicated'),
                              _buildGoalChip(30, '30 Mins', 'Intensive'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reminder Time Section
                    const Text(
                      'REMINDER TIME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected Alarm Time',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  Text(
                                    _reminderTime,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickCustomTime,
                                icon: const Icon(Icons.access_time_rounded, size: 18),
                                label: const Text('Custom Time'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  side: const BorderSide(color: AppTheme.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppTheme.cardBorder),
                          const SizedBox(height: 12),
                          const Text(
                            'Quick Time Presets:',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              '07:00 AM',
                              '08:30 AM',
                              '01:00 PM',
                              '06:00 PM',
                              '07:00 PM',
                              '08:30 PM',
                              '09:00 PM',
                            ].map((time) {
                              final isSelected = _reminderTime == time;
                              return ChoiceChip(
                                label: Text(time),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _reminderTime = time);
                                },
                                selectedColor: AppTheme.primary,
                                backgroundColor: const Color(0xFF1E293B),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Frequency & Alert Preferences
                    const Text(
                      'ALERT PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.repeat_rounded, color: AppTheme.primary),
                            title: const Text('Reminder Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            trailing: DropdownButton<String>(
                              value: _selectedFrequency,
                              dropdownColor: const Color(0xFF1E293B),
                              underline: const SizedBox(),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              items: ['Everyday', 'Weekdays (Mon-Fri)', 'Weekends Only']
                                  .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFrequency = val);
                              },
                            ),
                          ),
                          const Divider(color: AppTheme.cardBorder, height: 1),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.volume_up_rounded, color: Color(0xFF10B981)),
                            title: const Text('Sound Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Play gentle chime when alert triggers', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            value: _soundEnabled,
                            activeThumbColor: const Color(0xFF10B981),
                            onChanged: (val) => setState(() => _soundEnabled = val),
                          ),
                          const Divider(color: AppTheme.cardBorder, height: 1),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.vibration_rounded, color: Color(0xFF00D2FC)),
                            title: const Text('Vibration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Vibrate phone on reminder', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            value: _vibrationEnabled,
                            activeThumbColor: const Color(0xFF00D2FC),
                            onChanged: (val) => setState(() => _vibrationEnabled = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Save Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Save Reminder & Learning Goal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalChip(int mins, String label, String badge) {
    final isSelected = _dailyGoalMinutes == mins;
    return InkWell(
      onTap: () => setState(() => _dailyGoalMinutes = mins),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD97706).withValues(alpha: 0.2)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : AppTheme.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFFFDE68A) : AppTheme.textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFD97706)),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.amber[200] : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
