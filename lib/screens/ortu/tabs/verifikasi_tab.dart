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
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.orange[100],
            ),
            const SizedBox(height: 16),
            Text(
              'Semua aktivitas sudah diverifikasi!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final item = _groupedItems[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () async {
                // Navigate to Detail
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailVerifikasiScreen(
                      userId: item['user_id'],
                      date: item['date'],
                      userName: item['user_name'],
                      role: 'ortu', // Role Ortu
                    ),
                  ),
                );

                if (result == true) {
                  _loadData();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        item['user_name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(item['date']),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item['count']} Pending',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
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
