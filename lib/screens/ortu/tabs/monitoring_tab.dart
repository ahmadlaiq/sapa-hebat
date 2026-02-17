import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/database_helper.dart';

class MonitoringTab extends StatefulWidget {
  final int userId;

  const MonitoringTab({super.key, required this.userId});

  @override
  State<MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<MonitoringTab> {
  bool _isLoading = true;
  int _verifiedCount = 0;
  int _rejectedCount = 0;
  int _pendingCount = 0;
  List<Map<String, dynamic>> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final students = await DatabaseHelper.instance.getStudentsByOrtu(
        widget.userId,
      );
      final studentIds = students.map((s) => s['id'] as int).toList();

      final allData = await DatabaseHelper.instance
          .getAllActivitiesForMonitoring('ortu', studentIds);

      int verified = 0;
      int rejected = 0;
      int pending = 0;
      List<Map<String, dynamic>> history = [];

      for (var item in allData) {
        // Ortu memantau status VERIFIKASI GURU
        final status = item['status_guru'] ?? 'pending';

        if (status == 'verified') {
          verified++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }

        if (status != 'pending') {
          history.add({
            ...item,
            'status_display': status,
          }); // Simpan status guru
        }
      }

      if (mounted) {
        setState(() {
          _verifiedCount = verified;
          _rejectedCount = rejected;
          _pendingCount = pending;
          _recentHistory = history.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTitle(Map<String, dynamic> item) {
    String type = item['data_type'] == 'time'
        ? item['record_type']
        : item['activity_type'];
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatSubtitle(Map<String, dynamic> item) {
    try {
      final date = DateTime.parse(item['created_at']);
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (e) {
      return item['created_at'].toString();
    }
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    String title = _formatTitle(item);
    String subtitle = _formatSubtitle(item);
    String status = item['status_display'] ?? 'pending';

    Color color;
    IconData icon;
    String statusText;

    if (status == 'verified') {
      color = Colors.green;
      icon = Icons.check_circle;
      statusText = 'Disetujui Guru';
    } else {
      color = Colors.red;
      icon = Icons.cancel;
      statusText = 'Ditolak Guru';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          statusText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda sedang memantau status verifikasi yang dilakukan oleh Guru.',
                    style: TextStyle(color: Colors.blue[800], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const Text(
            'Statistik Verifikasi Guru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Disetujui',
                _verifiedCount,
                Colors.green,
                Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Ditolak',
                _rejectedCount,
                Colors.red,
                Icons.cancel,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Menunggu',
                _pendingCount,
                Colors.orange,
                Icons.hourglass_empty,
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'Riwayat Diproses Guru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_recentHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Belum ada aktivitas yang diproses Guru',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ..._recentHistory.map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }
}
