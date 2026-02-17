import 'package:flutter/material.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/riwayat_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  // Kunci global untuk mengakses state RiwayatTab
  final GlobalKey<RiwayatTabState> _riwayatKey = GlobalKey<RiwayatTabState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      BerandaTab(userId: widget.userId),
      RiwayatTab(key: _riwayatKey, userId: widget.userId),
      ProfilTab(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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

          // Refresh Riwayat setiap kali tab diklik
          if (index == 1) {
            // Delay sedikit agar state IndexedStack stabil (opsional, tapi aman)
            Future.microtask(() => _riwayatKey.currentState?.loadHistory());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'SAPA HEBAT';
      case 1:
        return 'Riwayat Aktivitas';
      case 2:
        return 'Profil Siswa';
      default:
        return 'SAPA HEBAT';
    }
  }
}
