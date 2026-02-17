import 'package:flutter/material.dart';
import 'activities/bangun_pagi_screen.dart';
import 'activities/beribadah_screen.dart';
import 'activities/makan_sehat_screen.dart';
import 'activities/olahraga_screen.dart';
import 'activities/sekolah_screen.dart';
import 'activities/gemar_belajar_screen.dart';
import 'activities/bermasyarakat_screen.dart';
import 'activities/tidur_cepat_screen.dart';

class RekapHarianScreen extends StatefulWidget {
  final int userId;
  final int initialStep;

  const RekapHarianScreen({
    super.key,
    required this.userId,
    this.initialStep = 0,
  });

  @override
  State<RekapHarianScreen> createState() => _RekapHarianScreenState();
}

class _RekapHarianScreenState extends State<RekapHarianScreen> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  void _nextStep() {
    if (_currentStep < 7) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Selesai
      Navigator.pop(context, true); // Refresh dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekap Harian Selesai! Hebat!')),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita gunakan IndexedStack atau switch case sederhana.
    // Karena setiap screen adalah Scaffold, kita return Scaffold langsung.
    // Tapi kita butuh override tombol Back di AppBar mereka??
    // Sebaiknya kita pass onBack ke mereka untuk handle leading button.

    switch (_currentStep) {
      case 0:
        return BangunPagiScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 1:
        return BeribadahScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 2:
        return MakanSehatScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 3:
        return OlahragaScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 4:
        return SekolahScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 5:
        return GemarBelajarScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 6:
        return BermasyarakatScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      case 7:
        return TidurCepatScreen(
          userId: widget.userId,
          isFlowMode: true,
          onNext: _nextStep,
          onBack: _prevStep,
        );
      default:
        return Container();
    }
  }
}
