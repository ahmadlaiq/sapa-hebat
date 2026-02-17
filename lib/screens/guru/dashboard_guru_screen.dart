import 'package:flutter/material.dart';
import 'tabs/verifikasi_tab.dart';
import 'tabs/monitoring_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardGuruScreen extends StatefulWidget {
  final int userId;

  const DashboardGuruScreen({super.key, required this.userId});

  @override
  State<DashboardGuruScreen> createState() => _DashboardGuruScreenState();
}

class _DashboardGuruScreenState extends State<DashboardGuruScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      VerifikasiTab(userId: widget.userId),
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
            icon: Icon(Icons.verified_user),
            label: 'Verifikasi',
          ),
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
        return 'Verifikasi Aktivitas';
      case 1:
        return 'Monitoring Siswa';
      case 2:
        return 'Profil Guru';
      default:
        return 'SAPA HEBAT - Guru';
    }
  }
}
