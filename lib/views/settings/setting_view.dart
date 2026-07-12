import 'package:flutter/material.dart';
import 'package:marketing/constants/routes.dart';
import 'package:marketing/services/auth_service.dart';
import 'package:marketing/services/provider/current_user.dart';
import 'package:marketing/views/settings/subpages/new_pass.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Account'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordView(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionLabel('Support'),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () {
                  // TODO: navigate to help center
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () {
                  // TODO: navigate to about page
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.logout,
                label: 'Log Out',
                iconColor: Colors.redAccent,
                labelColor: Colors.redAccent,
                onTap: () {
                  _logout(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.blueAccent,
    Color labelColor = Colors.black87,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 60, endIndent: 16);
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((16)),
        ),
        title: Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: (16)),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: (14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.black45, fontSize: (14)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: (14),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      CurrentUser.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (r) => false);
      }
    }
  }
}
