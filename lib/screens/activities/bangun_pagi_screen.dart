import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class BangunPagiScreen extends StatefulWidget {
  final int userId;
  final bool isFlowMode; // Mode Rekap Harian
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const BangunPagiScreen({
    super.key,
    required this.userId,
    this.isFlowMode = false,
    this.onNext,
    this.onBack,
  });

  @override
  State<BangunPagiScreen> createState() => _BangunPagiScreenState();
}

class _BangunPagiScreenState extends State<BangunPagiScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 5, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final data = await DatabaseHelper.instance.getTodayTimeRecord(
      widget.userId,
      'bangun_pagi',
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
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);

    final String formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final record = {
      'user_id': widget.userId,
      'record_type': 'bangun_pagi',
      'time_value': formattedTime,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      // Gunakan upsert agar update jika data hari ini sudah ada
      await DatabaseHelper.instance.upsertTimeRecord(record);

      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.isFlowMode && widget.onNext != null) {
          widget.onNext!();
        } else {
          Navigator.pop(context, true); // Return true to refresh dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waktu bangun pagi berhasil disimpan!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangun Pagi'),
        leading: widget.isFlowMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : null, // Default back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Jam berapa kamu bangun pagi ini?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 48),

            // Digital Clock Display
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
                      color: Colors.orange.withOpacity(0.3),
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

            // Save/Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor, // Blue for Next? Or Keep Orange?
                  // Let's stick to Orange for Save actions, but user requested 'Next'.
                  // Standard Next is usually Primary Color.
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isFlowMode ? 'SELANJUTNYA' : 'SIMPAN',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isFlowMode) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
