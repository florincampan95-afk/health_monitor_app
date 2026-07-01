import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_data_provider.dart';

class AddReadingScreen extends StatefulWidget {
  const AddReadingScreen({super.key});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _glucoseController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _symptomsController = TextEditingController();
  bool _isLoading = false;

  // Context for readings
  String? _selectedContext;
  String? _selectedMealType;

  final List<Map<String, dynamic>> _contextOptions = [
    {'value': 'fasting', 'label': 'Pe nemâncate', 'icon': '🌅'},
    {'value': 'before_meal', 'label': 'Înainte de masă', 'icon': '🍽️'},
    {'value': 'after_meal', 'label': 'După masă', 'icon': '🍴'},
    {'value': 'before_sleep', 'label': 'Înainte de culcare', 'icon': '🌙'},
    {'value': 'after_exercise', 'label': 'După exerciții', 'icon': '🏃'},
  ];

  final List<Map<String, dynamic>> _mealOptions = [
    {'value': 'breakfast', 'label': 'Mic dejun', 'icon': '🥐'},
    {'value': 'lunch', 'label': 'Prânz', 'icon': '🍲'},
    {'value': 'dinner', 'label': 'Cină', 'icon': '🍝'},
    {'value': 'snack', 'label': 'Gustare', 'icon': '🍎'},
  ];

  @override
  void dispose() {
    _glucoseController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Color _getGlucoseColor(double? value) {
    if (value == null) return Colors.grey;
    if (value < 70) return Colors.orange;
    if (value <= 100) return Colors.green;
    if (value <= 125) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getGlucoseStatus(double? value) {
    if (value == null) return '';
    if (value < 70) return '⚠️ Prea scăzută - Mâncați ceva dulce!';
    if (value <= 100) return '✅ Normală - Foarte bine!';
    if (value <= 125) return '⚡ Ușor crescută';
    return '🔴 Crescută - Consultați medicul!';
  }

  Color _getBloodPressureColor(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return Colors.grey;
    if (systolic < 90 || diastolic < 60) return Colors.orange;
    if (systolic <= 120 && diastolic <= 80) return Colors.green;
    if (systolic <= 140 && diastolic <= 90) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getBloodPressureStatus(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return '';
    if (systolic < 90 || diastolic < 60) return '⚠️ Prea scăzută - Odihniți-vă!';
    if (systolic <= 120 && diastolic <= 80) return '✅ Normală - Foarte bine!';
    if (systolic <= 140 && diastolic <= 90) return '⚡ Ușor crescută';
    return '🔴 Crescută - Consultați medicul!';
  }

  Future<void> _saveAll() async {
    final glucose = _glucoseController.text.isNotEmpty ? double.tryParse(_glucoseController.text) : null;
    final systolic = _systolicController.text.isNotEmpty ? double.tryParse(_systolicController.text) : null;
    final diastolic = _diastolicController.text.isNotEmpty ? double.tryParse(_diastolicController.text) : null;

    // Validate that at least one measurement is provided
    if (glucose == null && systolic == null && diastolic == null) {
      _showError('Introduceți cel puțin o măsurătoare (glicemie sau tensiune)');
      return;
    }

    // Validate glucose if provided
    if (glucose != null && (glucose < 20 || glucose > 600)) {
      _showError('Valoare glicemie invalidă (20-600 mg/dL)');
      return;
    }

    // Validate blood pressure if provided
    if (systolic != null || diastolic != null) {
      if (systolic == null || diastolic == null) {
        _showError('Introduceți ambele valori ale tensiunii');
        return;
      }
      if (systolic < 60 || systolic > 300) {
        _showError('Valoare sistolică invalidă (60-300 mmHg)');
        return;
      }
      if (diastolic < 40 || diastolic > 200) {
        _showError('Valoare diastolică invalidă (40-200 mmHg)');
        return;
      }
    }

    await _save(glucose: glucose, systolic: systolic, diastolic: diastolic);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Atenție', style: TextStyle(fontSize: 22)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _save({double? glucose, double? systolic, double? diastolic}) async {
    setState(() => _isLoading = true);
    try {
      await context.read<HealthDataProvider>().addReading(
        glucose: glucose,
        systolic: systolic,
        diastolic: diastolic,
        symptoms: _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
        readingContext: _selectedContext,
        mealType: _selectedMealType,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Eroare la salvare: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaugă Măsurătoare', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoBanner(),
                        const SizedBox(height: 20),
                        _buildContextCard(),
                        const SizedBox(height: 20),
                        _buildGlucoseCard(),
                        const SizedBox(height: 20),
                        _buildBloodPressureCard(),
                        const SizedBox(height: 20),
                        _buildSymptomsCard(),
                        const SizedBox(height: 80), // Space for bottom button
                      ],
                    ),
                  ),
                ),
                _buildBottomSaveButton(),
              ],
            ),
    );
  }

  Widget _buildGlucoseCard() {
    final glucoseValue = double.tryParse(_glucoseController.text);
    final color = _getGlucoseColor(glucoseValue);
    final status = _getGlucoseStatus(glucoseValue);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GLICEMIE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Zahărul din sânge', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Cum se măsoară:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Dimineața, PE NEMÂNCATE', style: TextStyle(fontSize: 15)),
                  Text('• Înainte de micul dejun', style: TextStyle(fontSize: 15)),
                  Text('• Valori normale: 70-100 mg/dL', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _glucoseController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Introduceți valoarea',
                hintStyle: TextStyle(fontSize: 20, color: Colors.grey.shade400),
                suffixText: 'mg/dL',
                suffixStyle: const TextStyle(fontSize: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(status, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    final systolic = double.tryParse(_systolicController.text);
    final diastolic = double.tryParse(_diastolicController.text);
    final color = _getBloodPressureColor(systolic, diastolic);
    final status = _getBloodPressureStatus(systolic, diastolic);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TENSIUNE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Tensiunea arterială', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Cum se măsoară:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Stați jos, relaxat, 5 minute', style: TextStyle(fontSize: 15)),
                  Text('• Brațul la nivelul inimii', style: TextStyle(fontSize: 15)),
                  Text('• Valori normale: 120/80 mmHg', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('SISTOLICĂ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('(numărul mare)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '120',
                          hintStyle: TextStyle(fontSize: 22, color: Colors.grey.shade300),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      const Text('/', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('DIASTOLICĂ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Text('(numărul mic)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '80',
                          hintStyle: TextStyle(fontSize: 22, color: Colors.grey.shade300),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(status, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.purple, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIMPTOME', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Cum vă simțiți? (Opțional)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSymptomChip('Amețeală'),
                _buildSymptomChip('Durere de cap'),
                _buildSymptomChip('Oboseală'),
                _buildSymptomChip('Vedere încețoșată'),
                _buildSymptomChip('Tremurături'),
                _buildSymptomChip('Transpirații'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _symptomsController,
              maxLines: 2,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Scrieți aici alte simptome...',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.orange, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTEXT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Când ați făcut măsurătoarea? (Opțional)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Momentul zilei:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _contextOptions.map((opt) => _buildContextChip(
                opt['value'],
                '${opt['icon']} ${opt['label']}',
                isContext: true,
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Tipul mesei (dacă e cazul):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mealOptions.map((opt) => _buildContextChip(
                opt['value'],
                '${opt['icon']} ${opt['label']}',
                isContext: false,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChip(String value, String label, {required bool isContext}) {
    final isSelected = isContext ? _selectedContext == value : _selectedMealType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 15, color: isSelected ? Colors.white : Colors.black)),
      selected: isSelected,
      selectedColor: Colors.orange,
      backgroundColor: Colors.grey.shade200,
      onSelected: (selected) {
        setState(() {
          if (isContext) {
            _selectedContext = selected ? value : null;
          } else {
            _selectedMealType = selected ? value : null;
          }
        });
      },
    );
  }

  Widget _buildSymptomChip(String label) {
    final isSelected = _symptomsController.text.contains(label);
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 15, color: isSelected ? Colors.white : Colors.black)),
      backgroundColor: isSelected ? Colors.purple : Colors.grey.shade200,
      onPressed: () {
        setState(() {
          if (isSelected) {
            _symptomsController.text = _symptomsController.text.replaceAll('$label, ', '').replaceAll(label, '');
          } else {
            if (_symptomsController.text.isNotEmpty && !_symptomsController.text.endsWith(', ')) {
              _symptomsController.text += ', ';
            }
            _symptomsController.text += label;
          }
        });
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completați măsurătorile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puteți introduce doar glicemie, doar tensiune, sau ambele. Contextul și simptomele sunt opționale.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveButton() {
    final hasGlucose = _glucoseController.text.isNotEmpty;
    final hasBP = _systolicController.text.isNotEmpty || _diastolicController.text.isNotEmpty;
    final hasAnyData = hasGlucose || hasBP;

    String buttonText = 'SALVEAZĂ MĂSURĂTORILE';
    if (hasGlucose && !hasBP) {
      buttonText = 'SALVEAZĂ GLICEMIA';
    } else if (!hasGlucose && hasBP) {
      buttonText = 'SALVEAZĂ TENSIUNEA';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: hasAnyData ? _saveAll : null,
            icon: const Icon(Icons.save, size: 28),
            label: Text(buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAnyData ? Colors.green.shade600 : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: hasAnyData ? 4 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
