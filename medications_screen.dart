import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_data_provider.dart';
import '../services/notification_service.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Adherence stats card
              _buildAdherenceCard(provider),
              const SizedBox(height: 20),
              
              // Today's medications
              _buildTodaySection(context, provider),
              const SizedBox(height: 20),
              
              // All medications list
              _buildMedicationsList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdherenceCard(HealthDataProvider provider) {
    final stats = provider.adherenceStats;
    final percent = stats?['adherence_percent'] ?? 0;
    final taken = stats?['taken'] ?? 0;
    final total = stats?['total'] ?? 0;
    
    Color color;
    String message;
    IconData icon;
    
    if (percent >= 90) {
      color = Colors.green;
      message = 'Excelent! Continuați așa!';
      icon = Icons.emoji_events;
    } else if (percent >= 70) {
      color = Colors.orange;
      message = 'Bine, dar puteți mai bine!';
      icon = Icons.thumb_up;
    } else {
      color = Colors.red;
      message = 'Încercați să nu uitați medicamentele!';
      icon = Icons.warning;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ADERENȚĂ TRATAMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Ultimele 30 zile', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text('$percent%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
            Text('$taken din $total doze luate', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, HealthDataProvider provider) {
    if (provider.medications.isEmpty) return const SizedBox();
    
    // Build list of today's doses
    final now = DateTime.now();
    final todayDayOfWeek = now.weekday % 7; // Convert to 0=Sunday format
    final todayDoses = <Map<String, dynamic>>[];
    
    for (var med in provider.medications) {
      // Check if medication is scheduled for today
      final days = med['days'] != null ? List<int>.from(med['days']) : <int>[];
      if (days.isNotEmpty && !days.contains(todayDayOfWeek)) {
        continue; // Skip if not scheduled for today
      }
      
      final times = List<String>.from(med['times'] ?? []);
      for (var time in times) {
        final parts = time.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final doseTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          todayDoses.add({
            'medication': med,
            'time': time,
            'doseTime': doseTime,
            'isPast': doseTime.isBefore(now),
          });
        }
      }
    }
    
    todayDoses.sort((a, b) => (a['doseTime'] as DateTime).compareTo(b['doseTime'] as DateTime));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.today, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('ASTĂZI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (todayDoses.isEmpty)
              const Center(child: Text('Nu aveți medicamente programate', style: TextStyle(color: Colors.grey)))
            else
              ...todayDoses.map((dose) => _buildDoseItem(context, provider, dose)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseItem(BuildContext context, HealthDataProvider provider, Map<String, dynamic> dose) {
    final med = dose['medication'] as Map<String, dynamic>;
    final time = dose['time'] as String;
    final isPast = dose['isPast'] as bool;
    final doseTime = dose['doseTime'] as DateTime;
    
    // Check if already logged today
    final logs = provider.medicationLogs;
    final today = DateTime.now();
    final isLogged = logs.any((log) {
      final logDate = DateTime.parse(log['created_at']);
      return log['medication_id'] == med['id'] &&
             log['scheduled_time'] == time &&
             logDate.day == today.day &&
             logDate.month == today.month &&
             logDate.year == today.year;
    });
    
    final logStatus = isLogged ? logs.firstWhere((log) {
      final logDate = DateTime.parse(log['created_at']);
      return log['medication_id'] == med['id'] &&
             log['scheduled_time'] == time &&
             logDate.day == today.day;
    })['status'] : null;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;
    String statusText = 'Programat';
    
    if (logStatus == 'taken') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Luat ✓';
    } else if (logStatus == 'missed') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Ratat';
    } else if (logStatus == 'skipped') {
      statusColor = Colors.orange;
      statusIcon = Icons.skip_next;
      statusText = 'Sărit';
    } else if (isPast) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'În așteptare';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${doseTime.hour.toString().padLeft(2, '0')}:${doseTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(med['dosage'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (!isLogged) ...[
            // Action buttons
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 36),
              onPressed: () => _logDose(context, provider, med, time, 'taken'),
              tooltip: 'Am luat',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 36),
              onPressed: () => _logDose(context, provider, med, time, 'missed'),
              tooltip: 'Am ratat',
            ),
          ] else ...[
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 8),
            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  void _logDose(BuildContext context, HealthDataProvider provider, Map<String, dynamic> med, String time, String status) async {
    try {
      if (status == 'taken') {
        await provider.logMedicationTaken(med['id'].toString(), time);
      } else if (status == 'missed') {
        await provider.logMedicationMissed(med['id'].toString(), time);
      } else if (status == 'skipped') {
        await provider.logMedicationSkipped(med['id'].toString(), time);
      }
    } catch (e) {
      debugPrint('Error logging dose: $e');
    }
  }

  Widget _buildMedicationsList(BuildContext context, HealthDataProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.medication, color: Colors.purple, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('MEDICAMENTE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.purple, size: 36),
                  onPressed: () => _showMedicationDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.medications.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.medication_outlined, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('Nu aveți medicamente adăugate', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showMedicationDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Adaugă Medicament'),
                    ),
                  ],
                ),
              )
            else
              ...provider.medications.map((med) => _buildMedicationItem(context, provider, med)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(BuildContext context, HealthDataProvider provider, Map<String, dynamic> med) {
    final times = List<String>.from(med['times'] ?? []);
    final days = med['days'] != null ? List<int>.from(med['days']) : <int>[];
    final dayNames = ['D', 'L', 'Ma', 'Mi', 'J', 'V', 'S'];
    
    String daysText = 'Zilnic';
    if (days.isNotEmpty) {
      daysText = days.map((d) => dayNames[d]).join(', ');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.medication, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(med['dosage'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(daysText, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: times.map((t) => Chip(
                    label: Text(_formatTime(t), style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.purple.shade50,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _showMedicationDialog(context, medication: med),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, provider, med),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minute AM';
    if (hour == 12) return '12:$minute PM';
    return '${hour - 12}:$minute PM';
  }

  void _showDeleteDialog(BuildContext context, HealthDataProvider provider, Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge medicament', style: TextStyle(fontSize: 20)),
        content: Text('Sigur vrei să ștergi "${med['name']}"?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteMedication(med['id']);
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showMedicationDialog(BuildContext context, {Map<String, dynamic>? medication}) {
    final isEditing = medication != null;
    final nameController = TextEditingController(text: medication?['name'] ?? '');
    final dosageController = TextEditingController(text: medication?['dosage'] ?? '');
    
    List<TimeOfDay> selectedTimes = [];
    if (medication != null && medication['times'] != null) {
      for (var t in medication['times']) {
        final parts = t.toString().split(':');
        if (parts.length == 2) {
          selectedTimes.add(TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0));
        }
      }
    }
    if (selectedTimes.isEmpty) selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
    
    // Days selection (0=Duminică, 1=Luni, etc.)
    List<int> selectedDays = [];
    if (medication != null && medication['days'] != null) {
      selectedDays = List<int>.from(medication['days']);
    }
    // Empty means every day
    
    final dayNames = ['D', 'L', 'Ma', 'Mi', 'J', 'V', 'S'];
    final dayFullNames = ['Duminică', 'Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă'];
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editează Medicament' : 'Adaugă Medicament', style: const TextStyle(fontSize: 20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nume medicament', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(labelText: 'Dozaj (ex: 1 comprimat)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.science)),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    const Text('Zile de administrare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        final isSelected = selectedDays.isEmpty || selectedDays.contains(index);
                        return Tooltip(
                          message: dayFullNames[index],
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedDays.isEmpty) {
                                  // First tap: select only this day
                                  selectedDays = [index];
                                } else if (selectedDays.contains(index)) {
                                  selectedDays.remove(index);
                                  if (selectedDays.isEmpty) {
                                    // If all removed, means every day
                                    selectedDays = [];
                                  }
                                } else {
                                  selectedDays.add(index);
                                  selectedDays.sort();
                                  if (selectedDays.length == 7) {
                                    // All days selected = every day
                                    selectedDays = [];
                                  }
                                }
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.purple : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  dayNames[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        selectedDays.isEmpty ? 'În fiecare zi' : selectedDays.map((d) => dayFullNames[d]).join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ore de administrare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...selectedTimes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: time);
                                  if (picked != null) setState(() => selectedTimes[index] = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Colors.blue),
                                      const SizedBox(width: 12),
                                      Text(time.format(context), style: const TextStyle(fontSize: 18)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (selectedTimes.length > 1)
                              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => selectedTimes.removeAt(index))),
                          ],
                        ),
                      );
                    }),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => selectedTimes.add(const TimeOfDay(hour: 20, minute: 0))),
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Adaugă altă oră'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Anulează')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || dosageController.text.isEmpty) return;
                    
                    final times = selectedTimes.map((t) {
                      final hour = t.hour.toString().padLeft(2, '0');
                      final minute = t.minute.toString().padLeft(2, '0');
                      return '$hour:$minute';
                    }).toList();
                    
                    Navigator.pop(dialogContext);
                    final provider = context.read<HealthDataProvider>();
                    
                    if (isEditing) {
                      await provider.updateMedication(
                        id: medication['id'],
                        name: nameController.text,
                        dosage: dosageController.text,
                        times: times,
                        days: selectedDays.isEmpty ? null : selectedDays,
                      );
                    } else {
                      final med = await provider.addMedication(
                        name: nameController.text,
                        dosage: dosageController.text,
                        times: times,
                        days: selectedDays.isEmpty ? null : selectedDays,
                      );
                      
                      // Schedule notifications
                      final notificationService = NotificationService();
                      await notificationService.requestPermissions();
                      await notificationService.scheduleAllRemindersForMedication(
                        medicationId: med['id'].toString(),
                        name: nameController.text,
                        dosage: dosageController.text,
                        times: times,
                        days: selectedDays.isEmpty ? null : selectedDays,
                      );
                    }
                  },
                  child: Text(isEditing ? 'Salvează' : 'Adaugă'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
