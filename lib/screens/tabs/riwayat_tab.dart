import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../database/database_helper.dart';

class RiwayatTab extends StatefulWidget {
  final int userId;

  const RiwayatTab({super.key, required this.userId});

  @override
  State<RiwayatTab> createState() => RiwayatTabState();
}

class RiwayatTabState extends State<RiwayatTab> {
  List<Map<String, dynamic>> _allHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final activities = await DatabaseHelper.instance.getActivities(
        widget.userId,
      );
      final timeRecords = await DatabaseHelper.instance.getAllTimeRecords(
        widget.userId,
      );

      // Gabungkan data
      List<Map<String, dynamic>> combined = [];

      // Process Activities
      for (var item in activities) {
        combined.add({
          'type': 'activity',
          'title': _formatActivityTitle(item['activity_type']),
          'subtitle': _formatActivitySubtitle(item),
          'date': item['created_at'],
          'status_guru': item['status_guru'] ?? 'pending',
          'status_ortu': item['status_ortu'] ?? 'pending',
          'original_data': item,
        });
      }

      // Process Time Records
      for (var item in timeRecords) {
        combined.add({
          'type': 'time',
          'title': _formatTimeTitle(item['record_type']),
          'subtitle': 'Pukul: ${item['time_value']}',
          'date': item['created_at'],
          'status_guru': item['status_guru'] ?? 'pending',
          'status_ortu': item['status_ortu'] ?? 'pending',
          'original_data': item,
        });
      }

      // Sort by date descending
      combined.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date']);
        DateTime dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _allHistory = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatActivityTitle(String type) {
    switch (type) {
      case 'beribadah':
        return 'Beribadah';
      case 'makan_sehat':
        return 'Makan Sehat';
      case 'olahraga':
        return 'Olahraga';
      case 'sekolah':
        return 'Sekolah';
      case 'gemar_belajar':
        return 'Gemar Belajar';
      case 'bermasyarakat':
        return 'Bermasyarakat';
      default:
        return type;
    }
  }

  String _formatTimeTitle(String type) {
    switch (type) {
      case 'bangun_pagi':
        return 'Bangun Pagi';
      case 'tidur_cepat':
        return 'Tidur Cepat';
      default:
        return type;
    }
  }

  String _formatActivitySubtitle(Map<String, dynamic> item) {
    try {
      String itemsText = '';
      if (item['items'] != null) {
        List<dynamic> items = jsonDecode(item['items']);
        itemsText = items.join(', ');
      }

      String notes = item['notes'] ?? '';
      if (notes.isNotEmpty) {
        if (itemsText.isNotEmpty) {
          return '$itemsText\nCatatan: $notes';
        }
        return 'Catatan: $notes';
      }
      return itemsText;
    } catch (e) {
      return '';
    }
  }

  IconData _getIcon(String title) {
    switch (title) {
      case 'Bangun Pagi':
        return Icons.wb_sunny;
      case 'Beribadah':
        return Icons.book;
      case 'Makan Sehat':
        return Icons.restaurant;
      case 'Olahraga':
        return Icons.directions_run;
      case 'Sekolah':
        return Icons.school;
      case 'Gemar Belajar':
        return Icons.menu_book;
      case 'Bermasyarakat':
        return Icons.groups;
      case 'Tidur Cepat':
        return Icons.bedtime;
      default:
        return Icons.history;
    }
  }

  Color _getColor(String title) {
    switch (title) {
      case 'Bangun Pagi':
        return Colors.orange;
      case 'Beribadah':
        return Colors.purple;
      case 'Makan Sehat':
        return Colors.green;
      case 'Olahraga':
        return Colors.red;
      case 'Sekolah':
        return Colors.blue;
      case 'Gemar Belajar':
        return Colors.teal;
      case 'Bermasyarakat':
        return Colors.amber;
      case 'Tidur Cepat':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String label, String status) {
    Color color;
    IconData icon;
    String text;

    if (status == 'verified') {
      color = Colors.green;
      icon = Icons.check_circle;
      text = 'Diterima';
    } else if (status == 'rejected') {
      color = Colors.red;
      icon = Icons.cancel;
      text = 'Ditolak';
    } else {
      color = Colors.grey;
      icon = Icons.access_time;
      text = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $text',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat aktivitas',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allHistory.length,
        itemBuilder: (context, index) {
          final item = _allHistory[index];
          final date = DateTime.parse(item['date']);
          final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColor(item['title']).withOpacity(0.1),
                  child: Icon(
                    _getIcon(item['title']),
                    color: _getColor(item['title']),
                    size: 20,
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['subtitle'] != null && item['subtitle'].isNotEmpty)
                      Text(
                        item['subtitle'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('Guru', item['status_guru']),
                        const SizedBox(width: 8),
                        _buildStatusChip('Ortu', item['status_ortu']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
