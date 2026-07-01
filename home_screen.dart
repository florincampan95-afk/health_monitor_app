import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_data_provider.dart';
import 'add_reading_screen.dart';
import 'charts_screen.dart';
import 'medications_screen.dart';
import 'export_pdf_screen.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthDataProvider>().loadData();
    });
  }

  final List<Widget> _screens = [
    const DashboardTab(),
    const ChartsScreen(),
    const MedicationsScreen(),
    const ExportPdfScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthDataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Sănătate', style: TextStyle(fontSize: 22)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (provider.userName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(provider.userName?.split(' ').first ?? '', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home, size: 26), selectedIcon: Icon(Icons.home, size: 30), label: 'Acasă'),
          NavigationDestination(icon: Icon(Icons.show_chart, size: 26), selectedIcon: Icon(Icons.show_chart, size: 30), label: 'Grafice'),
          NavigationDestination(icon: Icon(Icons.medication, size: 26), selectedIcon: Icon(Icons.medication, size: 30), label: 'Medicamente'),
          NavigationDestination(icon: Icon(Icons.picture_as_pdf, size: 26), selectedIcon: Icon(Icons.picture_as_pdf, size: 30), label: 'Export'),
          NavigationDestination(icon: Icon(Icons.settings, size: 26), selectedIcon: Icon(Icons.settings, size: 30), label: 'Setări'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _RobotFacePainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'add',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReadingScreen())),
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('ADAUGĂ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          : null,
    );
  }
}


class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _filter = 'all';
  String _period = 'all';

  List<Map<String, dynamic>> _filterReadings(List<Map<String, dynamic>> readings) {
    var filtered = readings;
    if (_filter == 'glucose') {
      filtered = filtered.where((r) => r['glucose'] != null).toList();
    } else if (_filter == 'bp') {
      filtered = filtered.where((r) => r['systolic'] != null && r['diastolic'] != null).toList();
    }
    if (_period != 'all') {
      final days = int.parse(_period);
      final cutoff = DateTime.now().subtract(Duration(days: days));
      filtered = filtered.where((r) => DateTime.parse(r['created_at']).isAfter(cutoff)).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        if (provider.readings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text('Nicio măsurătoare încă', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text('Apăsați butonul ADAUGĂ\npentru prima măsurătoare', style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  const Icon(Icons.arrow_downward, size: 40, color: Colors.blue),
                ],
              ),
            ),
          );
        }

        final filteredReadings = _filterReadings(provider.readings);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list, size: 20),
                      const SizedBox(width: 8),
                      const Text('Tip:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Toate', 'all'),
                      _buildFilterChip('Glicemie', 'glucose'),
                      _buildFilterChip('Tensiune', 'bp'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      const Text('Perioadă:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _buildPeriodChip('Toate', 'all'),
                      _buildPeriodChip('7 zile', '7'),
                      _buildPeriodChip('30 zile', '30'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${filteredReadings.length} măsurători', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ),
            Expanded(
              child: filteredReadings.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Nicio măsurătoare găsită', style: TextStyle(fontSize: 18)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredReadings.length,
                        itemBuilder: (context, index) => _ReadingCard(reading: filteredReadings[index], provider: provider, parentContext: context),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.black)), selected: isSelected, selectedColor: Colors.blue, onSelected: (_) => setState(() => _filter = value), visualDensity: VisualDensity.compact),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _period == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.black)), selected: isSelected, selectedColor: Colors.green, onSelected: (_) => setState(() => _period = value), visualDensity: VisualDensity.compact),
    );
  }
}


class _ReadingCard extends StatelessWidget {
  final Map<String, dynamic> reading;
  final HealthDataProvider provider;
  final BuildContext parentContext;

  const _ReadingCard({required this.reading, required this.provider, required this.parentContext});

  Color _getGlucoseColor(double? value) {
    if (value == null) return Colors.grey;
    if (value < 70) return Colors.orange;
    if (value <= 100) return Colors.green;
    if (value <= 125) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getGlucoseLabel(double? value) {
    if (value == null) return '';
    if (value < 70) return 'SCĂZUTĂ';
    if (value <= 100) return 'NORMALĂ';
    if (value <= 125) return 'UȘOR CRESCUTĂ';
    return 'CRESCUTĂ';
  }

  Color _getBPColor(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return Colors.grey;
    if (systolic < 90 || diastolic < 60) return Colors.orange;
    if (systolic <= 120 && diastolic <= 80) return Colors.green;
    if (systolic <= 140 && diastolic <= 90) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getBPLabel(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return '';
    if (systolic < 90 || diastolic < 60) return 'SCĂZUTĂ';
    if (systolic <= 120 && diastolic <= 80) return 'NORMALĂ';
    if (systolic <= 140 && diastolic <= 90) return 'UȘOR CRESCUTĂ';
    return 'CRESCUTĂ';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr).toLocal();
    final days = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
    final months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}\n${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final glucose = reading['glucose']?.toDouble();
    final systolic = reading['systolic']?.toDouble();
    final diastolic = reading['diastolic']?.toDouble();
    final hasAlert = provider.checkAlert(glucose, systolic, diastolic);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: hasAlert ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none),
      child: InkWell(
        onLongPress: () => _showDeleteDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(hasAlert ? Icons.warning_rounded : Icons.check_circle, color: hasAlert ? Colors.red : Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_formatDate(reading['created_at']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28), onPressed: () => _showDeleteDialog(context)),
                ],
              ),
              const Divider(height: 24),
              if (glucose != null) _buildGlucoseRow(glucose),
              if (systolic != null && diastolic != null) ...[
                if (glucose != null) const SizedBox(height: 12),
                _buildBPRow(systolic, diastolic),
              ],
              if (reading['reading_context'] != null || reading['meal_type'] != null) ...[
                const SizedBox(height: 12),
                _buildContextRow(reading['reading_context'], reading['meal_type']),
              ],
              if (reading['symptoms'] != null && reading['symptoms'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.note, color: Colors.purple, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reading['symptoms'], style: const TextStyle(fontSize: 16))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.delete, color: Colors.red, size: 32), SizedBox(width: 12), Text('Șterge?', style: TextStyle(fontSize: 20))]),
        content: Text('Sigur vrei să ștergi această măsurătoare din ${_formatDate(reading['created_at'])}?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează', style: TextStyle(fontSize: 16))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); parentContext.read<HealthDataProvider>().deleteReading(reading['id']); },
            child: const Text('Șterge', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseRow(double glucose) {
    final color = _getGlucoseColor(glucose);
    final label = _getGlucoseLabel(glucose);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 2)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.water_drop, color: Colors.blue, size: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLICEMIE', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('${glucose.toInt()} mg/dL', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      ]),
    );
  }

  Widget _buildBPRow(double systolic, double diastolic) {
    final color = _getBPColor(systolic, diastolic);
    final label = _getBPLabel(systolic, diastolic);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 2)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.favorite, color: Colors.red, size: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TENSIUNE', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('${systolic.toInt()}/${diastolic.toInt()} mmHg', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      ]),
    );
  }

  Widget _buildContextRow(String? readingContext, String? mealType) {
    String contextText = '';
    String contextIcon = '';

    // Map reading context to display text and icon
    if (readingContext != null) {
      switch (readingContext) {
        case 'fasting':
          contextIcon = '🌅';
          contextText = 'Pe nemâncate';
          break;
        case 'before_meal':
          contextIcon = '🍽️';
          contextText = 'Înainte de masă';
          break;
        case 'after_meal':
          contextIcon = '🍴';
          contextText = 'După masă';
          break;
        case 'before_sleep':
          contextIcon = '🌙';
          contextText = 'Înainte de culcare';
          break;
        case 'after_exercise':
          contextIcon = '🏃';
          contextText = 'După exerciții';
          break;
      }
    }

    // Map meal type to display text and icon
    String mealText = '';
    String mealIcon = '';
    if (mealType != null) {
      switch (mealType) {
        case 'breakfast':
          mealIcon = '🥐';
          mealText = 'Mic dejun';
          break;
        case 'lunch':
          mealIcon = '🍲';
          mealText = 'Prânz';
          break;
        case 'dinner':
          mealIcon = '🍝';
          mealText = 'Cină';
          break;
        case 'snack':
          mealIcon = '🍎';
          mealText = 'Gustare';
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.schedule, color: Colors.orange, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (contextText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text('$contextIcon $contextText', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              if (mealText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade400),
                  ),
                  child: Text('$mealIcon $mealText', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}


// Smiling Robot Face for AI button
class _RobotFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Eyes
    final eyeRadius = size.width * 0.12;
    final eyeY = size.height * 0.38;
    final leftEyeX = size.width * 0.32;
    final rightEyeX = size.width * 0.68;

    canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, paint);
    canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, paint);

    // Pupils
    final pupilPaint = Paint()..color = const Color(0xFF1E1B4B);
    final pupilRadius = eyeRadius * 0.5;
    canvas.drawCircle(Offset(leftEyeX, eyeY), pupilRadius, pupilPaint);
    canvas.drawCircle(Offset(rightEyeX, eyeY), pupilRadius, pupilPaint);

    // Eye shine
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.8);
    final shineRadius = pupilRadius * 0.4;
    canvas.drawCircle(Offset(leftEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3), shineRadius, shinePaint);
    canvas.drawCircle(Offset(rightEyeX - pupilRadius * 0.3, eyeY - pupilRadius * 0.3), shineRadius, shinePaint);

    // Smiling mouth
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final mouthY = size.height * 0.65;
    final mouthWidth = size.width * 0.35;

    final smilePath = Path();
    smilePath.moveTo(size.width / 2 - mouthWidth / 2, mouthY - size.height * 0.02);
    smilePath.quadraticBezierTo(
      size.width / 2, mouthY + size.height * 0.12,
      size.width / 2 + mouthWidth / 2, mouthY - size.height * 0.02,
    );
    canvas.drawPath(smilePath, mouthPaint);

    // Antenna
    final antennaPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.08),
      Offset(size.width / 2, -size.height * 0.05),
      antennaPaint,
    );

    // Antenna ball
    canvas.drawCircle(Offset(size.width / 2, -size.height * 0.08), size.width * 0.08, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
