import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _colorWork = Color(0xFFE3620F);
  static const _cardBg = Color(0xFF161616);
  static const _muted = Color(0xFF8A8A86);

  final _settings = SettingsService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _muted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Настройки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _switchTile(
                icon: Icons.volume_up_outlined,
                title: 'Звук',
                value: _settings.soundEnabled,
                onChanged: (v) async {
                  await _settings.setSoundEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _switchTile(
                icon: Icons.vibration,
                title: 'Вибрация',
                value: _settings.vibrationEnabled,
                onChanged: (v) async {
                  await _settings.setVibrationEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _switchTile(
                icon: Icons.notifications_none,
                title: 'Уведомления',
                subtitle: 'только когда приложение свёрнуто',
                value: _settings.notificationsEnabled,
                onChanged: (v) async {
                  await _settings.setNotificationsEnabled(v);
                  setState(() {});
                },
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'Interval Timer · версия 1.0.0\n'
                  'Приложение не является медицинским изделием\n'
                  'и не заменяет консультацию врача',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5A5A56),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок раздела — понадобится, когда настроек станет много.
  // ignore: unused_element
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _colorWork,
            inactiveThumbColor: _muted,
            inactiveTrackColor: const Color(0xFF2A2A28),
          ),
        ],
      ),
    );
  }
}
