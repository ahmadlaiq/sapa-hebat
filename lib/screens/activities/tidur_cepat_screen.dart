import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class TidurCepatScreen extends StatefulWidget {
  final int userId;
  final bool isFlowMode;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const TidurCepatScreen({
    super.key,
    required this.userId,
    this.isFlowMode = false,
    this.onNext,
    this.onBack,
  });

  @override
  State<TidurCepatScreen> createState() => _TidurCepatScreenState();
}

class _TidurCepatScreenState extends State<TidurCepatScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final data = await DatabaseHelper.instance.getTodayTimeRecord(
      widget.userId,
      'tidur_cepat',
    );
    if (data != null && mounted) {
      final timeParts = (data['time_value'] as String).split(':');
      if (timeParts.length == 2) {
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    final String timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final record = {
      'user_id': widget.userId,
      'record_type': 'tidur_cepat',
      'time_value': timeStr,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await DatabaseHelper.instance.upsertTimeRecord(record);

      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.isFlowMode && widget.onNext != null) {
          widget.onNext!(); // This will trigger finish
        } else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waktu tidur berhasil disimpan!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tidur Cepat'),
        leading: widget.isFlowMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack ?? () => Navigator.pop(context),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.bedtime, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              'Jam berapa kamu tidur malam ini?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 48),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _selectTime(context),
              icon: const Icon(Icons.edit),
              label: const Text('Ubah Waktu'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isFlowMode
                      ? Colors.green
                      : Colors.indigo, // Green for Finish?
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isFlowMode ? 'SELESAI' : 'SIMPAN',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
