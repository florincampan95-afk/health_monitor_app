import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_data_provider.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _period = '7';

  List<Map<String, dynamic>> _filterByPeriod(List<Map<String, dynamic>> readings) {
    if (_period == 'all') return readings;
    final days = int.parse(_period);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return readings.where((r) {
      final date = DateTime.parse(r['created_at']);
      return date.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, provider, child) {
        if (provider.readings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text('Nu există date', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Adăugați măsurători pentru\na vedea evoluția', 
                    style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final filtered = _filterByPeriod(provider.readings);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Period selector - big buttons
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              // Overall status card
              _buildOverallStatus(filtered),
              const SizedBox(height: 20),
              
              // Glucose section
              _buildGlucoseSection(filtered),
              const SizedBox(height: 20),
              
              // Blood pressure section
              _buildBloodPressureSection(filtered),
              const SizedBox(height: 20),
              
              // Recent readings list
              _buildRecentReadings(filtered),
              const SizedBox(height: 20),
              
              // Weekly summary
              _buildWeeklySummary(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('ARATĂ DATELE DIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodButton('7 ZILE', '7', Colors.blue),
                const SizedBox(width: 8),
                _buildPeriodButton('30 ZILE', '30', Colors.green),
                const SizedBox(width: 8),
                _buildPeriodButton('TOATE', 'all', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, Color color) {
    final isSelected = _period == value;
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => setState(() => _period = value),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildOverallStatus(List<Map<String, dynamic>> readings) {
    final glucoseReadings = readings.where((r) => r['glucose'] != null).toList();
    final bpReadings = readings.where((r) => r['systolic'] != null).toList();
    
    int normalGlucose = 0;
    int normalBP = 0;
    
    for (var r in glucoseReadings) {
      final g = (r['glucose'] as num).toDouble();
      if (g >= 70 && g <= 125) normalGlucose++;
    }
    for (var r in bpReadings) {
      final s = (r['systolic'] as num).toDouble();
      final d = (r['diastolic'] as num).toDouble();
      if (s <= 140 && d <= 90) normalBP++;
    }
    
    final totalReadings = glucoseReadings.length + bpReadings.length;
    final totalNormal = normalGlucose + normalBP;
    final percent = totalReadings > 0 ? (totalNormal / totalReadings * 100).toInt() : 0;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (percent >= 80) {
      statusColor = Colors.green;
      statusText = 'FOARTE BINE!';
      statusIcon = Icons.sentiment_very_satisfied;
    } else if (percent >= 60) {
      statusColor = Colors.orange;
      statusText = 'ATENȚIE';
      statusIcon = Icons.sentiment_neutral;
    } else {
      statusColor = Colors.red;
      statusText = 'CONSULTAȚI MEDICUL';
      statusIcon = Icons.sentiment_dissatisfied;
    }

    return Card(
      elevation: 4,
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(statusIcon, size: 80, color: statusColor),
            const SizedBox(height: 12),
            Text(statusText, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 8),
            Text('$percent% din măsurători sunt normale', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text('($totalNormal din $totalReadings)', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlucoseSection(List<Map<String, dynamic>> readings) {
    final glucoseReadings = readings.where((r) => r['glucose'] != null).toList();
    
    if (glucoseReadings.isEmpty) {
      return _buildEmptySection('GLICEMIE', 'Nu există măsurători', Colors.blue, Icons.water_drop);
    }
    
    final values = glucoseReadings.map((r) => (r['glucose'] as num).toDouble()).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final normalCount = values.where((v) => v >= 70 && v <= 125).length;
    
    String status;
    Color statusColor;
    if (avg < 70) {
      status = 'SCĂZUTĂ';
      statusColor = Colors.orange;
    } else if (avg <= 100) {
      status = 'NORMALĂ';
      statusColor = Colors.green;
    } else if (avg <= 125) {
      status = 'UȘOR CRESCUTĂ';
      statusColor = Colors.yellow.shade700;
    } else {
      status = 'CRESCUTĂ';
      statusColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.water_drop, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('GLICEMIE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Big average number
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Column(
                children: [
                  const Text('MEDIA', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text('${avg.toInt()}', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: statusColor)),
                  const Text('mg/dL', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                Expanded(child: _buildStatItem('MINIM', '${min.toInt()}', 'mg/dL', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatItem('MAXIM', '${max.toInt()}', 'mg/dL', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatItem('NORMALE', '$normalCount/${values.length}', '', Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reference info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Valori normale: 70-100 mg/dL\nÎnainte de masă: până la 125 mg/dL', 
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureSection(List<Map<String, dynamic>> readings) {
    final bpReadings = readings.where((r) => r['systolic'] != null && r['diastolic'] != null).toList();
    
    if (bpReadings.isEmpty) {
      return _buildEmptySection('TENSIUNE', 'Nu există măsurători', Colors.red, Icons.favorite);
    }
    
    final systolicValues = bpReadings.map((r) => (r['systolic'] as num).toDouble()).toList();
    final diastolicValues = bpReadings.map((r) => (r['diastolic'] as num).toDouble()).toList();
    
    final avgSys = systolicValues.reduce((a, b) => a + b) / systolicValues.length;
    final avgDia = diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
    final normalCount = bpReadings.where((r) => 
      (r['systolic'] as num) <= 140 && (r['diastolic'] as num) <= 90).length;
    
    String status;
    Color statusColor;
    if (avgSys < 90 || avgDia < 60) {
      status = 'SCĂZUTĂ';
      statusColor = Colors.orange;
    } else if (avgSys <= 120 && avgDia <= 80) {
      status = 'NORMALĂ';
      statusColor = Colors.green;
    } else if (avgSys <= 140 && avgDia <= 90) {
      status = 'UȘOR CRESCUTĂ';
      statusColor = Colors.yellow.shade700;
    } else {
      status = 'CRESCUTĂ';
      statusColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('TENSIUNE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Big average numbers
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Column(
                children: [
                  const Text('MEDIA', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${avgSys.toInt()}', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: statusColor)),
                      Text('/', style: TextStyle(fontSize: 40, color: statusColor)),
                      Text('${avgDia.toInt()}', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                  const Text('mmHg', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('SISTOLICĂ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const Text('(numărul mare)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${avgSys.toInt()}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('DIASTOLICĂ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const Text('(numărul mic)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${avgDia.toInt()}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildStatItem('NORMALE', '$normalCount/${bpReadings.length}', '', Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reference info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Valori normale: sub 140/90 mmHg\nOptim: 120/80 mmHg', 
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReadings(List<Map<String, dynamic>> readings) {
    final recent = readings.take(5).toList();
    if (recent.isEmpty) return const SizedBox();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.purple, size: 28),
                SizedBox(width: 12),
                Text('ULTIMELE MĂSURĂTORI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...recent.map((r) => _buildReadingRow(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingRow(Map<String, dynamic> reading) {
    final date = DateTime.parse(reading['created_at']).toLocal();
    final days = ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];
    final dateStr = '${days[date.weekday - 1]} ${date.day}.${date.month}';
    
    final glucose = reading['glucose'];
    final systolic = reading['systolic'];
    final diastolic = reading['diastolic'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            child: Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          if (glucose != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGlucoseColor((glucose as num).toDouble()).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('$glucose', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (systolic != null && diastolic != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getBPColor((systolic as num).toDouble(), (diastolic as num).toDouble()).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('$systolic/$diastolic', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title, String message, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return Colors.orange;
    if (value <= 125) return Colors.green;
    return Colors.red;
  }

  Color _getBPColor(double systolic, double diastolic) {
    if (systolic < 90 || diastolic < 60) return Colors.orange;
    if (systolic <= 140 && diastolic <= 90) return Colors.green;
    return Colors.red;
  }

  Widget _buildWeeklySummary(HealthDataProvider provider) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekReadings = provider.readings.where((r) {
      final date = DateTime.parse(r['created_at']);
      return date.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
    
    // Calculate stats
    final glucoseReadings = weekReadings.where((r) => r['glucose'] != null).toList();
    final bpReadings = weekReadings.where((r) => r['systolic'] != null).toList();
    
    double? avgGlucose;
    double? avgSystolic;
    double? avgDiastolic;
    int glucoseNormal = 0;
    int bpNormal = 0;
    
    if (glucoseReadings.isNotEmpty) {
      final values = glucoseReadings.map((r) => (r['glucose'] as num).toDouble()).toList();
      avgGlucose = values.reduce((a, b) => a + b) / values.length;
      glucoseNormal = values.where((v) => v >= 70 && v <= 125).length;
    }
    
    if (bpReadings.isNotEmpty) {
      final sysValues = bpReadings.map((r) => (r['systolic'] as num).toDouble()).toList();
      final diaValues = bpReadings.map((r) => (r['diastolic'] as num).toDouble()).toList();
      avgSystolic = sysValues.reduce((a, b) => a + b) / sysValues.length;
      avgDiastolic = diaValues.reduce((a, b) => a + b) / diaValues.length;
      bpNormal = bpReadings.where((r) => 
        (r['systolic'] as num) <= 140 && (r['diastolic'] as num) <= 90).length;
    }
    
    // Adherence stats
    final adherence = provider.adherenceStats;
    final adherencePercent = adherence?['adherence_percent'] ?? 0;
    
    // Generate summary text
    String summaryText = _generateSummaryText(
      glucoseReadings.length,
      bpReadings.length,
      avgGlucose,
      avgSystolic,
      avgDiastolic,
      glucoseNormal,
      bpNormal,
      adherencePercent,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.summarize, color: Colors.indigo, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REZUMAT SĂPTĂMÂNAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Generat automat', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Summary stats
            Row(
              children: [
                _buildSummaryStatBox('Măsurători', '${glucoseReadings.length + bpReadings.length}', Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryStatBox('Normale', '${glucoseNormal + bpNormal}', Colors.green),
                const SizedBox(width: 12),
                _buildSummaryStatBox('Aderență', '$adherencePercent%', 
                  adherencePercent >= 80 ? Colors.green : (adherencePercent >= 60 ? Colors.orange : Colors.red)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Summary text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                summaryText,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _generateSummaryText(
    int glucoseCount,
    int bpCount,
    double? avgGlucose,
    double? avgSystolic,
    double? avgDiastolic,
    int glucoseNormal,
    int bpNormal,
    int adherencePercent,
  ) {
    final buffer = StringBuffer();
    
    if (glucoseCount == 0 && bpCount == 0) {
      return '📊 Nu ați înregistrat măsurători săptămâna aceasta. Vă recomandăm să măsurați glicemia dimineața și tensiunea zilnic.';
    }
    
    buffer.write('📊 Săptămâna aceasta ați înregistrat ');
    
    if (glucoseCount > 0 && bpCount > 0) {
      buffer.write('$glucoseCount măsurători de glicemie și $bpCount de tensiune. ');
    } else if (glucoseCount > 0) {
      buffer.write('$glucoseCount măsurători de glicemie. ');
    } else {
      buffer.write('$bpCount măsurători de tensiune. ');
    }
    
    buffer.write('\n\n');
    
    if (avgGlucose != null) {
      buffer.write('🩸 Glicemia medie: ${avgGlucose.toInt()} mg/dL');
      if (avgGlucose >= 70 && avgGlucose <= 100) {
        buffer.write(' - Excelent! ');
      } else if (avgGlucose <= 125) {
        buffer.write(' - Bine, dar monitorizați. ');
      } else {
        buffer.write(' - Atenție! Consultați medicul. ');
      }
      buffer.write('($glucoseNormal din $glucoseCount în limite normale)\n\n');
    }
    
    if (avgSystolic != null && avgDiastolic != null) {
      buffer.write('❤️ Tensiunea medie: ${avgSystolic!.toInt()}/${avgDiastolic!.toInt()} mmHg');
      if (avgSystolic <= 120 && avgDiastolic <= 80) {
        buffer.write(' - Excelent! ');
      } else if (avgSystolic <= 140 && avgDiastolic <= 90) {
        buffer.write(' - Bine, continuați monitorizarea. ');
      } else {
        buffer.write(' - Atenție! Consultați medicul. ');
      }
      buffer.write('($bpNormal din $bpCount în limite normale)\n\n');
    }
    
    buffer.write('💊 Aderența la tratament: $adherencePercent%');
    if (adherencePercent >= 90) {
      buffer.write(' - Felicitări! Continuați așa!');
    } else if (adherencePercent >= 70) {
      buffer.write(' - Bine, dar încercați să nu uitați medicamentele.');
    } else {
      buffer.write(' - Atenție! Este important să luați medicamentele la timp.');
    }
    
    return buffer.toString();
  }
}
