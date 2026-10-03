import 'package:flutter/material.dart';

import 'menu_screen.dart';
import 'table_setup_screen.dart';
import 'data_settings_screen.dart';

import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your restaurant from one place.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _SettingCard(
            icon: Icons.restaurant_menu,
            iconColor: Colors.orange,
            title: 'Manage Items & Stock',
            subtitle: 'Products, prices and remaining stock',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MenuScreen(),
                ),
              );
            },
          ),
          _SettingCard(
            icon: Icons.table_bar,
            iconColor: primary,
            title: 'Table Setup',
            subtitle: 'Add, rename and delete restaurant tables',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TableSetupScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Data',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.storage,
            iconColor: Colors.blue,
            title: 'Local Database',
            subtitle: 'SQLite • Offline • Stored on device',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocalDatabaseScreen(),
                ),
              );
            },
          ),
          _SettingCard(
            icon: Icons.backup_outlined,
            iconColor: accent,
            title: 'Backup Database',
            subtitle: 'Create a local backup of your data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackupDatabaseScreen(),
                ),
              );
            },
          ),
          _SettingCard(
            icon: Icons.restore,
            iconColor: Colors.teal,
            title: 'Restore Backup',
            subtitle: 'Restore your restaurant data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestoreDatabaseScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'App',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.wifi_off,
            iconColor: Colors.green,
            title: 'Offline Mode',
            subtitle: 'Core operations work without internet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineModeScreen(),
                ),
              );
            },
          ),
          _SettingCard(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: 'About Gavthan',
            subtitle: 'Gavthan Bar and Restro • Version 1.0',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black38,
        ),
      ),
    );
  }
}
