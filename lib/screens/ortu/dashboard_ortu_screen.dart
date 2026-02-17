import 'package:flutter/material.dart';
import 'tabs/monitoring_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardOrtuScreen extends StatefulWidget {
  final int userId;

  const DashboardOrtuScreen({super.key, required this.userId});

  @override
  State<DashboardOrtuScreen> createState() => _DashboardOrtuScreenState();
}

class _DashboardOrtuScreenState extends State<DashboardOrtuScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      MonitoringTab(userId: widget.userId),
      ProfilTab(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_currentIndex)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Monitoring Anak';
      case 1:
        return 'Profil Orang Tua';
      default:
        return 'SAPA HEBAT - Orang Tua';
    }
  }
}
