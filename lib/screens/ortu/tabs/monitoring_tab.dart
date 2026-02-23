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
        // Now parents monitor THEIR OWN status
        final status = item['status_ortu'] ?? 'pending';

        if (status == 'verified') {
          verified++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }

        if (status != 'pending') {
          history.add(item);
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
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
    String status = item['status_ortu'] ?? 'pending';

    Color color = status == 'verified' ? Colors.green : Colors.red;
    IconData icon = status == 'verified' ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status == 'verified' ? 'Disetujui' : 'Ditolak',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
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
      color: Colors.orange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Info - More Premium
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Verifikasi Orang Tua',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pantau dan verifikasi aktivitas harian anak Anda secara langsung.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Text(
            'Statistik Verifikasi Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Disetujui',
                _verifiedCount,
                Colors.green,
                Icons.task_alt,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Ditolak',
                _rejectedCount,
                Colors.red,
                Icons.highlight_off,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Pending',
                _pendingCount,
                Colors.orange,
                Icons.history,
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Verifikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {}, // Future: Link to full history
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_recentHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat verifikasi',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
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
