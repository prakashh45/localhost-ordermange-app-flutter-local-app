import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/common.dart';

import 'tables_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final dashboardKey = GlobalKey<_DashboardTabState>();

  late final pages = [
    DashboardTab(key: dashboardKey),
    TablesScreen(),
    HistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
          if (value == 0) {
            dashboardKey.currentState?.load();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_bar_outlined),
            selectedIcon: Icon(Icons.table_bar),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? summary;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await DatabaseService.instance.todaySummary();

    if (!mounted) return;

    setState(() {
      summary = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 18,
        title: const Row(
          children: [
            Icon(Icons.local_bar_rounded),
            SizedBox(width: 10),
            Text(
              'Gavthan Bar and Restro',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            25,
          ),
          children: [
            const SectionTitle(
              title: "Today's Dashboard",
              subtitle: 'Finalized bills only',
            ),
            const SizedBox(height: 4),
            Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final crossAxisCount = width >= 700 ? 4 : 2;

                final aspectRatio = width >= 700 ? 1.6 : 1.35;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                  children: [
                    StatCard(
                      title: "Today's Revenue",
                      value: money(
                        data?['sales'] ?? 0,
                      ),
                      icon: Icons.currency_rupee,
                      background: softGreen,
                    ),
                    StatCard(
                      title: 'Active Tables',
                      value: '${data?['open'] ?? 0}',
                      icon: Icons.table_bar,
                      background: softBlue,
                    ),
                    StatCard(
                      title: 'Draft Orders',
                      value: '${data?['draft'] ?? 0}',
                      icon: Icons.edit_note,
                      background: softOrange,
                    ),
                    StatCard(
                      title: 'Low Stock',
                      value: '${data?['low'] ?? 0}',
                      icon: Icons.inventory_2_outlined,
                      background: softRed,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const SectionTitle(
              title: 'Quick Actions',
              subtitle: 'Common staff operations',
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.table_bar,
              iconColor: primary,
              title: 'Open Tables',
              subtitle: 'Open table → customer → start order',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TablesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.restaurant_menu,
              iconColor: accent,
              title: 'Menu & Stock',
              subtitle: 'Manage items, prices and stock',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MenuScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.receipt_long,
              iconColor: Colors.orange,
              title: 'Sales History',
              subtitle: 'View previous bills and revenue',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.bar_chart,
              iconColor: Colors.purple,
              title: 'Reports',
              subtitle: 'Day, week and month revenue',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
