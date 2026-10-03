import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_service.dart';
import '../widgets/common.dart';

class LocalDatabaseScreen extends StatefulWidget {
  const LocalDatabaseScreen({super.key});

  @override
  State<LocalDatabaseScreen> createState() => _LocalDatabaseScreenState();
}

class _LocalDatabaseScreenState extends State<LocalDatabaseScreen> {
  Map<String, int>? counts;
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await DatabaseService.instance.getDatabaseCounts();
      if (!mounted) return;
      setState(() {
        counts = result;
        error = null;
      });
    } catch (value) {
      if (!mounted) return;
      setState(() => error = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = counts;
    return Scaffold(
      appBar: AppBar(title: const Text('Local Database')),
      body: data == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Text('Unable to read database: $error'),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                const _StatusPanel(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: 'Connected / Available',
                  subtitle: 'SQLite • Offline • Stored on device',
                ),
                const SizedBox(height: 14),
                const Text('Database Information',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _InfoRow(label: 'Tables', value: '${data['tables'] ?? 0}'),
                _InfoRow(label: 'Products', value: '${data['products'] ?? 0}'),
                _InfoRow(
                    label: 'Customers', value: '${data['customers'] ?? 0}'),
                _InfoRow(label: 'Orders', value: '${data['orders'] ?? 0}'),
                _InfoRow(label: 'Bills', value: '${data['payments'] ?? 0}'),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Information'),
                ),
              ],
            ),
    );
  }
}

class BackupDatabaseScreen extends StatefulWidget {
  const BackupDatabaseScreen({super.key});

  @override
  State<BackupDatabaseScreen> createState() => _BackupDatabaseScreenState();
}

class _BackupDatabaseScreenState extends State<BackupDatabaseScreen> {
  bool busy = false;

  Future<void> backup() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final stamp = _timestamp();
      final path = '${Directory.systemTemp.path}/gavthan_backup_$stamp.db';
      final file = await DatabaseService.instance.createDatabaseBackup(path);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        text: 'Gavthan Bar and Restro database backup',
      );
      if (!mounted) return;
      _message('Backup created. Choose where to save or share it.');
    } catch (value) {
      if (mounted) _message('Backup failed: $value');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ActionScreen(
        title: 'Backup Database',
        icon: Icons.backup_outlined,
        description: 'Create a complete SQLite backup of your restaurant data.',
        buttonLabel: 'Create Backup',
        busy: busy,
        onPressed: backup,
      );

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class RestoreDatabaseScreen extends StatefulWidget {
  const RestoreDatabaseScreen({super.key});

  @override
  State<RestoreDatabaseScreen> createState() => _RestoreDatabaseScreenState();
}

class _RestoreDatabaseScreenState extends State<RestoreDatabaseScreen> {
  bool busy = false;

  Future<void> restore() async {
    if (busy) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content:
            const Text('Current data will be replaced by the selected backup.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => busy = true);
    try {
      await DatabaseService.instance.restoreDatabase(path);
      if (!mounted) return;
      _message('Database restored successfully.');
    } catch (value) {
      if (mounted) _message('Restore failed: $value');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ActionScreen(
        title: 'Restore Backup',
        icon: Icons.restore,
        description:
            'Select a valid Gavthan .db backup to replace current data.',
        buttonLabel: 'Choose Backup File',
        busy: busy,
        onPressed: restore,
      );

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Offline Mode')),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: const [
            _StatusPanel(
              icon: Icons.wifi_off,
              color: Colors.green,
              title: 'Offline Mode: ON',
              subtitle: 'Core operations work without internet',
            ),
            SizedBox(height: 14),
            Text('Available Offline',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            _Bullet(text: 'Table management'),
            _Bullet(text: 'Customer management'),
            _Bullet(text: 'Orders and billing'),
            _Bullet(text: 'Revenue and stock'),
            _Bullet(text: 'Reports and PDF generation'),
            SizedBox(height: 14),
            Text('Data is stored in the local SQLite database on this device.'),
          ],
        ),
      );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About Gavthan')),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: const [
            _StatusPanel(
              icon: Icons.local_bar,
              color: primary,
              title: 'Gavthan Bar and Restro',
              subtitle: 'Version 1.0',
            ),
            SizedBox(height: 18),
            Text('Offline-first restaurant POS',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            _Bullet(text: 'Table management'),
            _Bullet(text: 'Customer-wise orders'),
            _Bullet(text: 'Billing'),
            _Bullet(text: 'Revenue tracking'),
            _Bullet(text: 'Stock management'),
            _Bullet(text: 'Local SQLite database'),
          ],
        ),
      );
}

class _ActionScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onPressed;

  const _ActionScreen({
    required this.title,
    required this.icon,
    required this.description,
    required this.buttonLabel,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _StatusPanel(
                icon: icon, color: accent, title: title, subtitle: description),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: busy ? null : onPressed,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(icon),
              label: Text(busy ? 'Please wait...' : buttonLabel),
            ),
          ],
        ),
      );
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusPanel(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54))
                ])),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text(text),
      );
}

String _timestamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
}
