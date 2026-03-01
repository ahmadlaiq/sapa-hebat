import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/database_helper.dart';
import '../detail_verifikasi_screen.dart'; // Import halaman detail

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
      print('DEBUG: Loading data for Guru userId: ${widget.userId}');

      // 1. Fetch Students managed by this Guru
      final students = await DatabaseHelper.instance.getStudentsByGuru(
        widget.userId,
      );
      print('DEBUG: Found ${students.length} students');

      final studentIds = students.map((s) => s['id'] as int).toList();
      print('DEBUG: Student IDs: $studentIds');

      if (studentIds.isEmpty) {
        print('DEBUG: No students found for this Guru');
        if (mounted) {
          setState(() {
            _groupedItems = [];
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch data pending for these students
      final activities = await DatabaseHelper.instance.getPendingActivities(
        'guru',
        studentIds,
      );
      print('DEBUG: Found ${activities.length} pending activities');

      final timeRecords = await DatabaseHelper.instance.getPendingTimeRecords(
        'guru',
        studentIds,
      );
      print('DEBUG: Found ${timeRecords.length} pending time records');

      List<Map<String, dynamic>> allPending = [...activities, ...timeRecords];
      print('DEBUG: Total pending items: ${allPending.length}');

      // 3. Group by User & Date
      Map<String, Map<String, dynamic>> groups = {};

      for (var item in allPending) {
        final userId = item['user_id'];
        final date = item['created_at'].toString().substring(0, 10);
        final key = '$userId-$date';

        if (!groups.containsKey(key)) {
          groups[key] = {
            'user_id': userId,
            'date': date,
            'count': 0,
            'user_name': 'Loading...',
            'kelas': '7',
          };
        }
        groups[key]!['count'] = (groups[key]!['count'] as int) + 1;
      }

      // 4. Update User Names
      for (var key in groups.keys) {
        final userId = groups[key]!['user_id'];
        final user = await DatabaseHelper.instance.getUserById(userId);
        if (user != null) {
          String name = user['username'];
          groups[key]!['user_name'] = name[0].toUpperCase() + name.substring(1);
          groups[key]!['kelas'] = user['kelas'] ?? '7';
        } else {
          groups[key]!['user_name'] = 'Siswa $userId';
        }
      }

      // 5. Final List
      List<Map<String, dynamic>> finalList = groups.values.toList();

      // Sort by Date Descending
      finalList.sort((a, b) => b['date'].compareTo(a['date']));

      print('DEBUG: Final grouped items: ${finalList.length}');

      if (mounted) {
        setState(() {
          _groupedItems = finalList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading data: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
      // Note: Locale id_ID might require intl initialization, defaulting to EN if not setup
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
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt, size: 80, color: Colors.green[200]),
            ),
            const SizedBox(height: 24),
            Text(
              'Semua beres!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seluruh aktivitas siswa Anda sudah diverifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.green,
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
                        kelas: item['kelas'],
                        role: 'guru',
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
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green[50],
                          child: Text(
                            item['user_name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.green,
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
                            const SizedBox(height: 2),
                            Text(
                              'Kelas ${item['kelas']}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                              color: Colors
                                  .orange[50], // Tetap orange untuk pending
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item['count']} Pending',
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
