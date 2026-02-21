import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
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

  Widget _buildItemCard(
    Map<String, dynamic> item,
    String statusKey,
    Color primaryColor,
  ) {
    final status = item[statusKey] ?? 'pending';
    final isPending = status == 'pending';

    String time = '';
    try {
      final date = DateTime.parse(item['created_at']);
      time = DateFormat('HH:mm').format(date);
    } catch (_) {
      time = item['created_at'].toString().length >= 16
          ? item['created_at'].toString().substring(11, 16)
          : '--:--';
    }

    // Parse Items
    String itemsText = '';
    var rawItems = item['items'];
    if (rawItems != null) {
      if (rawItems is List) {
        itemsText = rawItems.join(', ');
      } else if (rawItems is String && rawItems.isNotEmpty) {
        try {
          if (rawItems.trim().startsWith('[') ||
              rawItems.trim().startsWith('{')) {
            var decoded = jsonDecode(rawItems);
            if (decoded is List) {
              itemsText = decoded.join(', ');
            } else {
              itemsText = rawItems;
            }
          } else {
            itemsText = rawItems;
          }
        } catch (_) {
          itemsText = rawItems;
        }
      }
    }

    // Parse Notes
    String notes = (item['notes'] ?? item['note'] ?? '').toString();

    return Card(
      elevation: isPending ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isPending ? Colors.white : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTitle(item),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item['data_type'] == 'time' &&
                              item['time_value'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pukul: ${item['time_value']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(status),
              ],
            ),

            if (itemsText.isNotEmpty || notes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              if (itemsText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemsText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (notes.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan: $notes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusKey = widget.role == 'guru' ? 'status_guru' : 'status_ortu';
    final primaryColor = widget.role == 'guru' ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info - Sleeker look
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(
                                DateTime.tryParse(widget.date) ??
                                    DateTime.now(),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // List Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) =>
                        _buildItemCard(_items[index], statusKey, primaryColor),
                  ),
                ),

                // Note Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Tulis catatan evaluasi untuk siswa...',
                          prefixIcon: const Icon(Icons.chat_bubble_outline),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _processAll('rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'TOLAK SEMUA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _processAll('verified'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'SETUJUI SEMUA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'verified') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }
    if (status == 'rejected') {
      return const Icon(Icons.cancel, color: Colors.red, size: 28);
    }
    return const Icon(Icons.hourglass_empty, color: Colors.orange, size: 28);
  }
}
