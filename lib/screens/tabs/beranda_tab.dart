import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../rekap_harian_screen.dart';

class BerandaTab extends StatefulWidget {
  final int userId;

  const BerandaTab({super.key, required this.userId});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  int _completedSteps = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProgress();
  }

  Future<void> _checkProgress() async {
    final count = await DatabaseHelper.instance.getDailyProgressCount(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _completedSteps = count;
        _isLoading = false;
      });
    }
  }

  void _startRekap() async {
    // Navigasi ke RekapHarianScreen
    // Pass initialStep sesuai progress saat ini
    // Jika 8, berarti sudah selesai, tapi tombol seharusnya tidak muncul.
    // Jika user mau edit ulang? Mungkin kita biarkan start dari 0 jika user minta?
    // Tapi requirement bilang: "tombol dihide atau akan berubah menjadi semacam pesan"

    // Kita start dari step terakhir yang belum selesai.
    // Misal: steps=0 -> start 0.
    // steps=3 -> start 3.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RekapHarianScreen(
          userId: widget.userId,
          initialStep: _completedSteps >= 8 ? 0 : _completedSteps,
        ),
      ),
    );

    // Refresh progress setelah kembali
    if (result == true || result == null) {
      _checkProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Selamat Datang, Siswa!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ayo mulai kebiasaan baikmu hari ini.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Menu Grid 3x3 (DISABLED)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                0.85, // Memberikan ruang vertikal lebih agar tidak overflow
            children: [
              _buildMenuCard(
                context,
                'Bangun Pagi',
                Icons.wb_sunny,
                Colors.orange,
              ),
              _buildMenuCard(context, 'Beribadah', Icons.book, Colors.purple),
              _buildMenuCard(
                context,
                'Makan Sehat',
                Icons.restaurant,
                Colors.green,
              ),
              _buildMenuCard(
                context,
                'Olahraga',
                Icons.directions_run,
                Colors.red,
              ),
              _buildMenuCard(context, 'Sekolah', Icons.school, Colors.blue),
              _buildMenuCard(
                context,
                'Gemar Belajar',
                Icons.menu_book,
                Colors.teal,
              ),
              _buildMenuCard(
                context,
                'Bermasyarakat',
                Icons.groups,
                Colors.amber,
              ),
              _buildMenuCard(
                context,
                'Tidur Cepat',
                Icons.bedtime,
                Colors.indigo,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Tombol Rekap Harian
          if (!_isLoading) ...[
            if (_completedSteps < 8)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startRekap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _completedSteps > 0
                            ? Icons.edit_note
                            : Icons.play_arrow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _completedSteps > 0
                            ? 'LANJUTKAN REKAP HARIAN'
                            : 'REKAP HARIAN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kamu sudah mengisi rekap hari ini!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    const Text('Sampai jumpa besok!'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Helper tanpa onTap
  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        // Hapus InkWell agar tidak clickable
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors
                    .grey, // Greyed out to indicate disabled? Or keep standard?
                // User said "disable aja". Visual cue is nice but not strictly required.
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
