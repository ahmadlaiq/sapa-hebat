import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'dart:convert';

class BeribadahScreen extends StatefulWidget {
  final int userId;
  final bool isFlowMode;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const BeribadahScreen({
    super.key,
    required this.userId,
    this.isFlowMode = false,
    this.onNext,
    this.onBack,
  });

  @override
  State<BeribadahScreen> createState() => _BeribadahScreenState();
}

class _BeribadahScreenState extends State<BeribadahScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Default checklist is dependent on religion, so we keep the initial structure empty
  // But we need a list of religions first.
  String _selectedReligion = 'Islam';
  final List<String> _religions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Khonghucu',
    'Kepercayaan Sapta Darma',
  ];

  Map<String, bool> _checklistItems = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateChecklist(); // Set default for Islam
    _loadTodayData();
  }

  void _updateChecklist() {
    // Default items per religion
    List<String> items = [];
    switch (_selectedReligion) {
      case 'Islam':
        items = [
          'Sholat Subuh',
          'Sholat Dzuhur',
          'Sholat Ashar',
          'Sholat Maghrib',
          'Sholat Isya',
          'Mengaji',
        ];
        break;
      case 'Kristen':
      case 'Katolik':
        items = [
          'Berdoa Pagi',
          'Membaca Alkitab',
          'Saat Teduh',
          'Berdoa Malam',
        ];
        break;
      case 'Hindu':
        items = ['Tri Sandya', 'Sembahyang', 'Membaca Kitab Suci'];
        break;
      case 'Buddha':
        items = ['Membaca Paritta', 'Meditasi', 'Dana Makan'];
        break;
      case 'Kepercayaan Sapta Darma':
        items = ['Sujud', 'Hening'];
        break;
      default:
        items = ['Berdoa Pagi', 'Berdoa Malam', 'Bersyukur'];
    }

    setState(() {
      _checklistItems = {for (var item in items) item: false};
    });
  }

  Future<void> _loadTodayData() async {
    final data = await DatabaseHelper.instance.getTodayActivity(
      widget.userId,
      'beribadah',
    );
    if (data != null && mounted) {
      setState(() {
        _selectedReligion = data['category'] ?? 'Islam';
        _notesController.text = data['notes'] ?? '';
      });

      // Update checklist default keys first based on saved religion
      _updateChecklist();

      // Load checked items
      if (data['items'] != null) {
        try {
          List<dynamic> savedItems = jsonDecode(data['items']);
          // savedItems is List<String> of checked items

          setState(() {
            // Reset all to false first (already done in _updateChecklist)
            // Determine which keys are true
            for (var key in _checklistItems.keys) {
              if (savedItems.contains(key)) {
                _checklistItems[key] = true;
              }
            }
          });
        } catch (e) {
          print('Error parsing items: $e');
        }
      }
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);

    List<String> checkedItems = _checklistItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final activity = {
      'user_id': widget.userId,
      'activity_type': 'beribadah',
      'category': _selectedReligion,
      'items': jsonEncode(checkedItems),
      'notes': _notesController.text,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await DatabaseHelper.instance.upsertActivity(activity);

      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.isFlowMode && widget.onNext != null) {
          widget.onNext!();
        } else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aktivitas beribadah berhasil disimpan!'),
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
        title: const Text('Beribadah'),
        leading: widget.isFlowMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack ?? () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Religion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _religions.map((religion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(religion),
                      selected: _selectedReligion == religion,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedReligion = religion;
                            _updateChecklist();
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Checklist
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _checklistItems.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: _checklistItems[key],
                    onChanged: (val) {
                      setState(() {
                        _checklistItems[key] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isFlowMode ? 'SELANJUTNYA' : 'SIMPAN',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
