import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';
import '../services/score_service.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  static const s = S();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('설정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (_, __) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionHeader('게임'),
            _SettingTile(
              icon: Icons.volume_up,
              iconColor: Colors.blueAccent,
              title: s.soundFx,
              subtitle: s.soundFxDesc,
              trailing: Switch(
                value: _settings.soundEnabled,
                onChanged: (v) => _settings.setSoundEnabled(v),
                activeColor: Colors.blueAccent,
              ),
            ),
            _SettingTile(
              icon: Icons.palette_outlined,
              iconColor: Colors.tealAccent,
              title: s.colorBlind,
              subtitle: s.colorBlindDesc,
              trailing: Switch(
                value: _settings.colorBlindMode,
                onChanged: (v) => _settings.setColorBlindMode(v),
                activeColor: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('데이터'),
            _SettingTile(
              icon: Icons.refresh,
              iconColor: Colors.orangeAccent,
              title: s.tutorialReset,
              subtitle: s.tutorialResetDesc,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('tutorial_done_v2');
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => _buildDialog(
                      context,
                      title: s.tutorialResetTitle,
                      content: s.tutorialResetMsg,
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(s.confirm),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            _SettingTile(
              icon: Icons.delete_outline,
              iconColor: Colors.redAccent,
              title: s.resetRecords,
              subtitle: s.resetRecordsDesc,
              onTap: () => _confirmReset(context),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('앱 정보'),
            _SettingTile(
              icon: Icons.info_outline,
              iconColor: Colors.white38,
              title: s.version,
              subtitle: s.versionDesc,
              onTap: () => showDialog(
                context: context,
                builder: (_) => _buildDialog(
                  context,
                  title: s.appName,
                  titleBold: true,
                  content: '${s.version}: 1.0.0\n\n${s.versionDialogDesc}',
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.close, style: const TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context, {
    required String title,
    required String content,
    required List<Widget> actions,
    bool titleBold = false,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: TextStyle(color: Colors.white, fontWeight: titleBold ? FontWeight.bold : FontWeight.normal)),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: actions,
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.resetRecords, style: const TextStyle(color: Colors.white)),
        content: Text(s.resetConfirmMsg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ScoreService.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.resetDone),
                    backgroundColor: const Color(0xFF16213E),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(s.resetRecords),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing!
            else if (onTap != null) const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
