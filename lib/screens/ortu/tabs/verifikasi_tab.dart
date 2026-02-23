import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/database_helper.dart';
import '../../guru/detail_verifikasi_screen.dart'; // Menggunakan Detail Screen yang sama

class VerifikasiTab extends StatefulWidget {
  final int userId;

  const VerifikasiTab({super.key, required this.userId});

  @override
  State<VerifikasiTab> createState() => _VerifikasiTabState();
}

class _VerifikasiTabState extends State<VerifikasiTab> {
  List<Map<String, dynamic>> _groupedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Students managed by this Ortu
      final students = await DatabaseHelper.instance.getStudentsByOrtu(
        widget.userId,
      );
      final studentIds = students.map((s) => s['id'] as int).toList();

      if (studentIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final activities = await DatabaseHelper.instance.getPendingActivities(
        'ortu',
        studentIds,
      );
      final timeRecords = await DatabaseHelper.instance.getPendingTimeRecords(
        'ortu',
        studentIds,
      );

      List<Map<String, dynamic>> allPending = [...activities, ...timeRecords];

      // 2. Group by User & Date
      Map<String, Map<String, dynamic>> groups = {};

      for (var item in allPending) {
        final userId = item['user_id'];
        final date = item['created_at'].toString().substring(0, 10);
        final key = '$userId-$date';

        if (!groups.containsKey(key)) {
          groups[key] = {'user_id': userId, 'date': date, 'count': 0};
        }
        groups[key]!['count'] = (groups[key]!['count'] as int) + 1;
      }

      // 3. Update User Names
      Set<int> userIds = groups.values.map((e) => e['user_id'] as int).toSet();
      Map<int, String> userNames = {};

      for (var uid in userIds) {
        final user = await DatabaseHelper.instance.getUserById(uid);
        if (user != null) {
          String name = user['username'];
          name = name[0].toUpperCase() + name.substring(1);
          userNames[uid] = name;
        } else {
          userNames[uid] = 'Anak $uid';
        }
      }

      // 4. Final List
      List<Map<String, dynamic>> finalList = [];
      groups.forEach((key, value) {
        finalList.add({
          'user_id': value['user_id'],
          'date': value['date'],
          'count': value['count'],
          'user_name': userNames[value['user_id']] ?? 'Unknown',
        });
      });

      // Sort by Date Descending
      finalList.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _groupedItems = finalList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt, size: 80, color: Colors.orange[200]),
            ),
            const SizedBox(height: 24),
            Text(
              'Yeay! Semua tugas sudah diverifikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada kiriman aktivitas baru dari anak hari ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final item = _groupedItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailVerifikasiScreen(
                        userId: item['user_id'],
                        date: item['date'],
                        userName: item['user_name'],
                        role: 'ortu',
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadData();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.orange[50],
                          child: Text(
                            item['user_name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['user_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(item['date']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item['count']} Aktivitas',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
