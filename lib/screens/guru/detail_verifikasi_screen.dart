import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class DetailVerifikasiScreen extends StatefulWidget {
  final int userId;
  final String date;
  final String userName;
  final String role; // 'guru' or 'ortu'

  const DetailVerifikasiScreen({
    super.key,
    required this.userId,
    required this.date,
    required this.userName,
    required this.role,
  });

  @override
  State<DetailVerifikasiScreen> createState() => _DetailVerifikasiScreenState();
}

class _DetailVerifikasiScreenState extends State<DetailVerifikasiScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      final allActivities = await DatabaseHelper.instance.getActivities(
        widget.userId,
      );
      final allTimes = await DatabaseHelper.instance.getAllTimeRecords(
        widget.userId,
      );

      List<Map<String, dynamic>> dailyItems = [];

      // Filter Activities
      for (var item in allActivities) {
        if (item['created_at'].toString().startsWith(widget.date)) {
          dailyItems.add({...item, 'data_type': 'activity'});
        }
      }

      // Filter Time Records
      for (var item in allTimes) {
        if (item['created_at'].toString().startsWith(widget.date)) {
          dailyItems.add({...item, 'data_type': 'time'});
        }
      }

      // Sort
      dailyItems.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      // Load existing note
      final note = await DatabaseHelper.instance.getVerificationNote(
        widget.userId,
        widget.date,
        widget.role,
      );
      if (note != null) {
        _noteController.text = note;
      }

      if (mounted) {
        setState(() {
          _items = dailyItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processAll(String status) async {
    // 1. Update Status
    await DatabaseHelper.instance.updateDailyStatus(
      widget.userId,
      widget.date,
      widget.role,
      status,
    );

    // 2. Save Note (if any)
    if (_noteController.text.trim().isNotEmpty) {
      await DatabaseHelper.instance.upsertVerificationNote(
        widget.userId,
        widget.date,
        widget.role,
        _noteController.text.trim(),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'verified' ? 'Berhasil disetujui' : 'Berhasil ditolak',
        ),
      ),
    );
    Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final statusKey = widget.role == 'guru' ? 'status_guru' : 'status_ortu';
    final primaryColor = widget.role == 'guru' ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Tanggal: ${widget.date}'),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // List Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final status = item[statusKey] ?? 'pending';
                      final isPending = status == 'pending';

                      return Card(
                        color: isPending ? Colors.white : Colors.grey[100],
                        child: ListTile(
                          title: Text(_formatTitle(item)),
                          subtitle: Text(
                            item['created_at'].toString().substring(11, 16),
                          ), // HH:mm
                          trailing: _buildStatusIcon(status),
                        ),
                      );
                    },
                  ),
                ),

                // Note Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Catatan untuk Siswa (Opsional)',
                      prefixIcon: const Icon(Icons.note_add),
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processAll('rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('TOLAK SEMUA'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _processAll('verified'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('SETUJUI SEMUA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'verified')
      return const Icon(Icons.check_circle, color: Colors.green);
    if (status == 'rejected')
      return const Icon(Icons.cancel, color: Colors.red);
    return const Icon(Icons.hourglass_empty, color: Colors.orange);
  }
}
