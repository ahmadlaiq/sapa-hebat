import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'dart:convert';

class SekolahScreen extends StatefulWidget {
  final int userId;
  final bool isFlowMode;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const SekolahScreen({
    super.key,
    required this.userId,
    this.isFlowMode = false,
    this.onNext,
    this.onBack,
  });

  @override
  State<SekolahScreen> createState() => _SekolahScreenState();
}

class _SekolahScreenState extends State<SekolahScreen> {
  final TextEditingController _notesController = TextEditingController();
  final Map<String, bool> _checklistItems = {
    'Hadir Tepat Waktu': false,
    'Pakai Seragam Lengkap': false,
    'Bawa Buku Pelajaran': false,
    'Mengerjakan PR': false,
    'Aktif di Kelas': false,
    'Menjaga Kebersihan': false,
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final data = await DatabaseHelper.instance.getTodayActivity(
      widget.userId,
      'sekolah',
    );
    if (data != null && mounted) {
      if (data['notes'] != null) _notesController.text = data['notes'];
      if (data['items'] != null) {
        try {
          List<dynamic> savedItems = jsonDecode(data['items']);
          setState(() {
            for (var item in savedItems) {
              if (_checklistItems.containsKey(item))
                _checklistItems[item] = true;
            }
          });
        } catch (e) {
          debugPrint('Error: $e');
        }
      }
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    final checked = _checklistItems.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final activity = {
      'user_id': widget.userId,
      'activity_type': 'sekolah',
      'items': jsonEncode(checked),
      'notes': _notesController.text,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await DatabaseHelper.instance.upsertActivity(activity);
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.isFlowMode && widget.onNext != null)
          widget.onNext!();
        else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Disimpan!')));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sekolah'),
        leading: widget.isFlowMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.school, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: _checklistItems.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: _checklistItems[key],
                    onChanged: (val) =>
                        setState(() => _checklistItems[key] = val ?? false),
                    activeColor: Colors.blue,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Sekolah',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                child: Text(widget.isFlowMode ? 'SELANJUTNYA' : 'SIMPAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
