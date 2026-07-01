import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/health_data_provider.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _sharedAccessCodes = [];
  bool _loadingContacts = true;
  bool _loadingCodes = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Amprentă';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
    _loadSharedAccessCodes();
    _loadBiometricSettings();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadBiometricSettings() async {
    final canCheck = await BiometricService.canCheckBiometrics();
    final isSupported = await BiometricService.isDeviceSupported();
    final isEnabled = await BiometricService.isBiometricEnabled();
    final types = await BiometricService.getAvailableBiometrics();
    
    setState(() {
      _biometricAvailable = canCheck && isSupported;
      _biometricEnabled = isEnabled;
      _biometricType = BiometricService.getBiometricTypeName(types);
    });
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final response = await Supabase.instance.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false);
      
      setState(() {
        _emergencyContacts = List<Map<String, dynamic>>.from(response);
        _loadingContacts = false;
      });
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
      setState(() => _loadingContacts = false);
    }
  }

  Future<void> _loadSharedAccessCodes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final response = await Supabase.instance.client
          .from('shared_access')
          .select()
          .eq('patient_user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      setState(() {
        _sharedAccessCodes = List<Map<String, dynamic>>.from(response);
        _loadingCodes = false;
      });
    } catch (e) {
      debugPrint('Error loading shared access codes: $e');
      setState(() => _loadingCodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Setări', style: TextStyle(fontSize: 22)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('PROFIL'),
              _buildProfileCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('VALORI ȚINTĂ'),
              _buildTargetRangesCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('REMINDER MĂSURĂTORI'),
              _buildReadingRemindersCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('CONTACTE URGENȚĂ'),
              _buildEmergencyContactsCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('MEDIC'),
              _buildDoctorCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('PARTAJARE DATE'),
              _buildShareCard(provider),
              const SizedBox(height: 20),
              
              _buildSectionTitle('CONT'),
              _buildAccountCard(context),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }

  Widget _buildProfileCard(HealthDataProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (provider.userName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            Text(provider.userName ?? 'Utilizator', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(provider.userEmail ?? '', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editProfile(provider),
                icon: const Icon(Icons.edit),
                label: const Text('Editează Profilul', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRangesCard(HealthDataProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRangeRow('Glicemie', '${provider.glucoseMin.toInt()} - ${provider.glucoseMax.toInt()} mg/dL', Icons.water_drop, Colors.blue),
            const Divider(),
            _buildRangeRow('Tensiune Sistolică', 'sub ${provider.systolicMax.toInt()} mmHg', Icons.favorite, Colors.red),
            const Divider(),
            _buildRangeRow('Tensiune Diastolică', 'sub ${provider.diastolicMax.toInt()} mmHg', Icons.favorite_border, Colors.red),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editTargetRanges(provider),
                icon: const Icon(Icons.tune),
                label: const Text('Modifică Valorile', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsCard(HealthDataProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loadingContacts)
              const Center(child: CircularProgressIndicator())
            else if (_emergencyContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nu aveți contacte de urgență adăugate', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._emergencyContacts.map((contact) => _buildEmergencyContactTile(contact)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addEmergencyContact(),
                icon: const Icon(Icons.add),
                label: const Text('Adaugă Contact Urgență', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactTile(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: contact['is_primary'] == true ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: contact['is_primary'] == true ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Row(
        children: [
          Icon(
            contact['is_primary'] == true ? Icons.star : Icons.person,
            color: contact['is_primary'] == true ? Colors.red : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(contact['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (contact['is_primary'] == true)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Principal', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                  ],
                ),
                Text(contact['phone'], style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                if (contact['relationship'] != null)
                  Text(_getRelationshipLabel(contact['relationship']), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () => _callPhone(contact['phone']),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editEmergencyContact(contact);
              if (value == 'delete') _deleteEmergencyContact(contact['id']);
              if (value == 'primary') _setPrimaryContact(contact['id']);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Editează')),
              if (contact['is_primary'] != true)
                const PopupMenuItem(value: 'primary', child: Text('Setează Principal')),
              const PopupMenuItem(value: 'delete', child: Text('Șterge', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  String _getRelationshipLabel(String? rel) {
    switch (rel) {
      case 'spouse': return 'Soț/Soție';
      case 'child': return 'Copil';
      case 'parent': return 'Părinte';
      case 'sibling': return 'Frate/Soră';
      case 'friend': return 'Prieten';
      default: return 'Altul';
    }
  }

  Widget _buildReadingRemindersCard(HealthDataProvider provider) {
    final profile = provider.userProfile;
    final glucoseEnabled = profile?['reminder_glucose_enabled'] == true;
    final bpEnabled = profile?['reminder_bp_enabled'] == true;
    final glucoseTime = profile?['reminder_glucose_time'] ?? '07:00';
    final bpTime = profile?['reminder_bp_time'] ?? '08:00';
    final glucoseDays = profile?['reminder_glucose_days'] != null 
        ? List<int>.from(profile!['reminder_glucose_days']) 
        : <int>[];
    final bpDays = profile?['reminder_bp_days'] != null 
        ? List<int>.from(profile!['reminder_bp_days']) 
        : <int>[];
    
    final dayNames = ['D', 'L', 'Ma', 'Mi', 'J', 'V', 'S'];
    
    String getDaysText(List<int> days) {
      if (days.isEmpty) return 'Zilnic';
      return days.map((d) => dayNames[d]).join(', ');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Glucose reminder
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reminder Glicemie', style: TextStyle(fontSize: 16)),
                      if (glucoseEnabled)
                        Text(getDaysText(glucoseDays), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (glucoseEnabled) ...[
                  TextButton(
                    onPressed: () => _editReminderSettings(provider, 'glucose', glucoseTime, glucoseDays),
                    child: Text(glucoseTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
                Switch(value: glucoseEnabled, onChanged: (v) => _toggleReminder(provider, 'glucose', v, glucoseTime, glucoseDays), activeColor: Colors.blue),
              ],
            ),
            const Divider(),
            // Blood pressure reminder
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reminder Tensiune', style: TextStyle(fontSize: 16)),
                      if (bpEnabled)
                        Text(getDaysText(bpDays), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (bpEnabled) ...[
                  TextButton(
                    onPressed: () => _editReminderSettings(provider, 'bp', bpTime, bpDays),
                    child: Text(bpTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
                Switch(value: bpEnabled, onChanged: (v) => _toggleReminder(provider, 'bp', v, bpTime, bpDays), activeColor: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(HealthDataProvider provider, String type, bool enabled, String timeStr, List<int> days) async {
    final notificationService = NotificationService();
    if (enabled) {
      final parts = timeStr.split(':');
      final time = TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts[1]) ?? 0);
      await notificationService.scheduleReadingReminder(
        id: type == 'glucose' ? 9001 : 9002, 
        type: type, 
        time: time,
        days: days.isEmpty ? null : days,
      );
    } else {
      await notificationService.cancelReadingReminder(type == 'glucose' ? 9001 : 9002);
    }
    await provider.updateProfile({type == 'glucose' ? 'reminder_glucose_enabled' : 'reminder_bp_enabled': enabled});
    setState(() {});
  }

  Future<void> _editReminderSettings(HealthDataProvider provider, String type, String currentTime, List<int> currentDays) async {
    final parts = currentTime.split(':');
    TimeOfDay selectedTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts[1]) ?? 0);
    List<int> selectedDays = List<int>.from(currentDays);
    
    final dayNames = ['D', 'L', 'Ma', 'Mi', 'J', 'V', 'S'];
    final dayFullNames = ['Duminică', 'Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă'];
    final title = type == 'glucose' ? 'Reminder Glicemie' : 'Reminder Tensiune';
    final color = type == 'glucose' ? Colors.blue : Colors.red;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(type == 'glucose' ? Icons.water_drop : Icons.favorite, color: color),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ora:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: color),
                      const SizedBox(width: 12),
                      Text(selectedTime.format(context), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Zile:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final isSelected = selectedDays.isEmpty || selectedDays.contains(index);
                  return Tooltip(
                    message: dayFullNames[index],
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (selectedDays.isEmpty) {
                            selectedDays = [index];
                          } else if (selectedDays.contains(index)) {
                            selectedDays.remove(index);
                            if (selectedDays.isEmpty) {
                              selectedDays = [];
                            }
                          } else {
                            selectedDays.add(index);
                            selectedDays.sort();
                            if (selectedDays.length == 7) {
                              selectedDays = [];
                            }
                          }
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.grey.shade200,
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
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  selectedDays.isEmpty ? 'În fiecare zi' : selectedDays.map((d) => dayFullNames[d]).join(', '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final notificationService = NotificationService();
                
                // Cancel old notifications first
                await notificationService.cancelReadingReminder(type == 'glucose' ? 9001 : 9002);
                
                // Schedule new ones
                await notificationService.scheduleReadingReminder(
                  id: type == 'glucose' ? 9001 : 9002, 
                  type: type, 
                  time: selectedTime,
                  days: selectedDays.isEmpty ? null : selectedDays,
                );
                
                // Save to profile
                await provider.updateProfile({
                  type == 'glucose' ? 'reminder_glucose_time' : 'reminder_bp_time': timeStr,
                  type == 'glucose' ? 'reminder_glucose_days' : 'reminder_bp_days': selectedDays.isEmpty ? null : selectedDays,
                });
                setState(() {});
              },
              child: const Text('Salvează'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editReminderTime(HealthDataProvider provider, String type, String currentTime) async {
    final profile = provider.userProfile;
    final days = type == 'glucose' 
        ? (profile?['reminder_glucose_days'] != null ? List<int>.from(profile!['reminder_glucose_days']) : <int>[])
        : (profile?['reminder_bp_days'] != null ? List<int>.from(profile!['reminder_bp_days']) : <int>[]);
    await _editReminderSettings(provider, type, currentTime, days);
  }

  Widget _buildDoctorCard(HealthDataProvider provider) {
    final profile = provider.userProfile;
    final hasDoctor = profile?['doctor_name'] != null;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasDoctor) ...[
              Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. ${profile!['doctor_name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (profile['doctor_phone'] != null)
                          Text(profile['doctor_phone'], style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        if (profile['doctor_email'] != null)
                          Text(profile['doctor_email'], style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (profile['doctor_phone'] != null)
                    IconButton(icon: const Icon(Icons.phone, color: Colors.green, size: 32), onPressed: () => _callPhone(profile['doctor_phone'])),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editDoctor(provider),
                icon: Icon(hasDoctor ? Icons.edit : Icons.add),
                label: Text(hasDoctor ? 'Modifică' : 'Adaugă Medic', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(HealthDataProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: Colors.purple, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('Partajați datele cu medicul sau familia', style: TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareWithDoctor(provider),
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Cu Medicul'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareWithFamily(provider),
                    icon: const Icon(Icons.family_restroom),
                    label: const Text('Cu Familia'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateQuickCode(provider),
                icon: const Icon(Icons.qr_code),
                label: const Text('Generează Cod Rapid', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
              ),
            ),
            // Active codes section
            if (_sharedAccessCodes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.key, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('Coduri Active (${_sharedAccessCodes.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showManageCodesDialog(),
                    child: const Text('Gestionează'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showManageCodesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key, color: Colors.orange),
              SizedBox(width: 12),
              Text('Coduri de Acces Active'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _sharedAccessCodes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Nu aveți coduri active', textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sharedAccessCodes.length,
                    itemBuilder: (ctx, index) {
                      final code = _sharedAccessCodes[index];
                      final isExpired = code['expires_at'] != null && DateTime.parse(code['expires_at']).isBefore(DateTime.now());
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.grey.shade100 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isExpired ? Colors.grey : Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        code['access_code'] ?? '',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: isExpired ? Colors.grey : Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: code['role'] == 'doctor' ? Colors.blue : Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          code['role'] == 'doctor' ? 'Medic' : 'Familie',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    code['shared_with_name'] ?? code['shared_with_email'] ?? 'Necunoscut',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                  if (code['expires_at'] != null)
                                    Text(
                                      isExpired ? 'Expirat' : 'Expiră: ${_formatDate(code['expires_at'])}',
                                      style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _revokeAccessCode(code['id']);
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (_sharedAccessCodes.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Revocă Toate'),
                      content: const Text('Sigur doriți să revocați toate codurile de acces?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anulează')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Revocă Toate'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _revokeAllAccessCodes();
                    setDialogState(() {});
                  }
                },
                child: const Text('Revocă Toate', style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Închide')),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _revokeAccessCode(String id) async {
    try {
      await Supabase.instance.client.from('shared_access').update({'is_active': false}).eq('id', id);
      await _loadSharedAccessCodes();
      // No snackbar here - just update the list silently
    } catch (e) {
      debugPrint('Error revoking code: $e');
    }
  }

  Future<void> _revokeAllAccessCodes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('shared_access').update({'is_active': false}).eq('patient_user_id', userId);
      await _loadSharedAccessCodes();
      // No snackbar - dialog will close and list will be empty
    } catch (e) {
      debugPrint('Error revoking all codes: $e');
    }
  }

  Widget _buildAccountCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (_biometricAvailable) ...[
            ListTile(
              leading: const Icon(Icons.fingerprint, color: Colors.blue),
              title: Text('Blocare cu $_biometricType', style: const TextStyle(fontSize: 16)),
              subtitle: Text(_biometricEnabled ? 'Activat' : 'Dezactivat', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Verify biometric before enabling
                    final success = await BiometricService.authenticate(
                      reason: 'Confirmați pentru a activa blocarea cu $_biometricType',
                    );
                    if (success) {
                      await BiometricService.setBiometricEnabled(true);
                      setState(() => _biometricEnabled = true);
                    }
                  } else {
                    await BiometricService.setBiometricEnabled(false);
                    setState(() => _biometricEnabled = false);
                  }
                },
                activeColor: Colors.blue,
              ),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text('Schimbă Parola', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.system_update, color: Colors.blue),
            title: const Text('Verifică actualizări', style: TextStyle(fontSize: 16)),
            subtitle: Text(
              _appVersion.isEmpty ? 'Se încarcă...' : 'Versiune instalată: $_appVersion',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _checkForUpdates,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Deconectare', style: TextStyle(fontSize: 16, color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => _logout(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Șterge Contul', style: TextStyle(fontSize: 16, color: Colors.red)),
            subtitle: const Text('Șterge toate datele permanent', style: TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // First confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Șterge Contul?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Această acțiune va șterge PERMANENT:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('• Toate măsurătorile de glicemie și tensiune'),
            Text('• Toate medicamentele salvate'),
            Text('• Toate contactele de urgență'),
            Text('• Toate codurile de acces partajate'),
            Text('• Profilul și setările'),
            Text('• Contul de utilizator'),
            SizedBox(height: 16),
            Text('Această acțiune NU poate fi anulată!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continuă'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Second confirmation with typing
    final confirmController = TextEditingController();
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmare Finală'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pentru a confirma ștergerea, tastați:'),
            const SizedBox(height: 8),
            const Text('STERGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 4)),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 4),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'STERGE',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.toUpperCase() == 'STERGE') {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Textul nu corespunde. Tastați STERGE pentru a confirma.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ȘTERGE DEFINITIV'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Se șterge contul...'),
          ],
        ),
      ),
    );

    try {
      // Call Edge Function to delete user and all data
      final response = await Supabase.instance.client.functions.invoke('delete-user');
      
      if (response.status != 200) {
        throw Exception('Eroare la ștergerea contului');
      }

      // Close loading dialog and navigate to login
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contul și toate datele au fost șterse.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eroare la ștergerea contului. Încercați din nou.'), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== EMERGENCY CONTACT ACTIONS ====================

  void _addEmergencyContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRelationship;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Adaugă Contact Urgență'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume *', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon *', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (opțional)', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  decoration: const InputDecoration(labelText: 'Relație', prefixIcon: Icon(Icons.people)),
                  items: const [
                    DropdownMenuItem(value: 'spouse', child: Text('Soț/Soție')),
                    DropdownMenuItem(value: 'child', child: Text('Copil')),
                    DropdownMenuItem(value: 'parent', child: Text('Părinte')),
                    DropdownMenuItem(value: 'sibling', child: Text('Frate/Soră')),
                    DropdownMenuItem(value: 'friend', child: Text('Prieten')),
                    DropdownMenuItem(value: 'other', child: Text('Altul')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRelationship = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                Navigator.pop(ctx);
                await _saveEmergencyContact(
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text.isNotEmpty ? emailController.text : null,
                  relationship: selectedRelationship,
                );
              },
              child: const Text('Salvează'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEmergencyContact({required String name, required String phone, String? email, String? relationship, String? id}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = <String, dynamic>{'user_id': userId, 'name': name, 'phone': phone, 'email': email, 'relationship': relationship};
      
      if (id != null) {
        await Supabase.instance.client.from('emergency_contacts').update(data).eq('id', id);
      } else {
        data['is_primary'] = _emergencyContacts.isEmpty;
        await Supabase.instance.client.from('emergency_contacts').insert(data);
      }
      await _loadEmergencyContacts();
    } catch (e) {
      debugPrint('Error saving emergency contact: $e');
    }
  }

  void _editEmergencyContact(Map<String, dynamic> contact) {
    final nameController = TextEditingController(text: contact['name']);
    final phoneController = TextEditingController(text: contact['phone']);
    final emailController = TextEditingController(text: contact['email'] ?? '');
    String? selectedRelationship = contact['relationship'];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editează Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume *', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon *', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  decoration: const InputDecoration(labelText: 'Relație', prefixIcon: Icon(Icons.people)),
                  items: const [
                    DropdownMenuItem(value: 'spouse', child: Text('Soț/Soție')),
                    DropdownMenuItem(value: 'child', child: Text('Copil')),
                    DropdownMenuItem(value: 'parent', child: Text('Părinte')),
                    DropdownMenuItem(value: 'sibling', child: Text('Frate/Soră')),
                    DropdownMenuItem(value: 'friend', child: Text('Prieten')),
                    DropdownMenuItem(value: 'other', child: Text('Altul')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRelationship = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                Navigator.pop(ctx);
                await _saveEmergencyContact(
                  id: contact['id'],
                  name: nameController.text,
                  phone: phoneController.text,
                  email: emailController.text.isNotEmpty ? emailController.text : null,
                  relationship: selectedRelationship,
                );
              },
              child: const Text('Salvează'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEmergencyContact(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge Contact'),
        content: const Text('Sigur doriți să ștergeți acest contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulează')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Șterge')),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('emergency_contacts').delete().eq('id', id);
      await _loadEmergencyContacts();
    }
  }

  Future<void> _setPrimaryContact(String id) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client.from('emergency_contacts').update({'is_primary': false}).eq('user_id', userId);
    await Supabase.instance.client.from('emergency_contacts').update({'is_primary': true}).eq('id', id);
    await _loadEmergencyContacts();
  }

  // ==================== PROFILE & DOCTOR ACTIONS ====================

  void _editProfile(HealthDataProvider provider) {
    final nameController = TextEditingController(text: provider.userName ?? '');
    final phoneController = TextEditingController(text: provider.userProfile?['phone'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editează Profilul'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume complet', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateProfile({'full_name': nameController.text, 'phone': phoneController.text});
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _editTargetRanges(HealthDataProvider provider) {
    final glucoseMinController = TextEditingController(text: provider.glucoseMin.toInt().toString());
    final glucoseMaxController = TextEditingController(text: provider.glucoseMax.toInt().toString());
    final systolicController = TextEditingController(text: provider.systolicMax.toInt().toString());
    final diastolicController = TextEditingController(text: provider.diastolicMax.toInt().toString());
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valori Țintă'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Glicemie (mg/dL)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextField(controller: glucoseMinController, decoration: const InputDecoration(labelText: 'Min'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: glucoseMaxController, decoration: const InputDecoration(labelText: 'Max'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tensiune maximă (mmHg)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextField(controller: systolicController, decoration: const InputDecoration(labelText: 'Sistolică'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: diastolicController, decoration: const InputDecoration(labelText: 'Diastolică'), keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateProfile({
                'glucose_min': double.tryParse(glucoseMinController.text) ?? 70,
                'glucose_max': double.tryParse(glucoseMaxController.text) ?? 125,
                'systolic_max': double.tryParse(systolicController.text) ?? 140,
                'diastolic_max': double.tryParse(diastolicController.text) ?? 90,
              });
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  void _editDoctor(HealthDataProvider provider) {
    final nameController = TextEditingController(text: provider.userProfile?['doctor_name'] ?? '');
    final phoneController = TextEditingController(text: provider.userProfile?['doctor_phone'] ?? '');
    final emailController = TextEditingController(text: provider.userProfile?['doctor_email'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informații Medic'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume medic', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateProfile({'doctor_name': nameController.text, 'doctor_phone': phoneController.text, 'doctor_email': emailController.text});
              setState(() {});
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  // ==================== SHARE ACTIONS ====================

  void _shareWithDoctor(HealthDataProvider provider) {
    final profile = provider.userProfile;
    final emailController = TextEditingController(text: profile?['doctor_email'] ?? '');
    final nameController = TextEditingController(text: profile?['doctor_name'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partajează cu Medicul'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Medicul va primi un email cu codul de acces (valabil 1 oră, utilizare unică).', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume medic', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email medic', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final result = await provider.shareWithDoctor(emailController.text, nameController.text);
                if (mounted) {
                  _sendShareEmail(email: emailController.text, name: nameController.text, code: result['access_code'], patientName: provider.userName ?? 'Pacient', isDoctor: true);
                }
              } catch (e) {
                debugPrint('Error sharing: $e');
              }
            },
            child: const Text('Partajează'),
          ),
        ],
      ),
    );
  }

  void _shareWithFamily(HealthDataProvider provider) {
    // If there are emergency contacts, show selection dialog
    if (_emergencyContacts.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Selectează Contact'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selectați un contact sau introduceți manual:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                ..._emergencyContacts.map((contact) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(contact['name']),
                  subtitle: Text(contact['email'] ?? contact['phone']),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareWithContact(provider, contact);
                  },
                )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Altă persoană'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareWithNewPerson(provider);
                  },
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează'))],
        ),
      );
    } else {
      _shareWithNewPerson(provider);
    }
  }

  void _shareWithContact(HealthDataProvider provider, Map<String, dynamic> contact) async {
    final email = contact['email'];
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acest contact nu are email. Adăugați email în setări.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final result = await provider.shareWithCaregiver(email, contact['name']);
      if (mounted) {
        _sendShareEmail(email: email, name: contact['name'], code: result['access_code'], patientName: provider.userName ?? 'Pacient', isDoctor: false);
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  void _shareWithNewPerson(HealthDataProvider provider) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partajează cu Familia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Persoana va primi un email cu codul de acces (valabil 1 oră, utilizare unică).', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nume', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final result = await provider.shareWithCaregiver(emailController.text, nameController.text);
                if (mounted) {
                  _sendShareEmail(email: emailController.text, name: nameController.text, code: result['access_code'], patientName: provider.userName ?? 'Pacient', isDoctor: false);
                }
              } catch (e) {
                debugPrint('Error sharing: $e');
              }
            },
            child: const Text('Partajează'),
          ),
        ],
      ),
    );
  }

  void _generateQuickCode(HealthDataProvider provider) async {
    try {
      // Generate a quick access code for doctor visit
      final result = await provider.shareWithDoctor('', 'Vizită Cabinet');
      final code = result['access_code'];
      
      // Reload codes list
      await _loadSharedAccessCodes();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.qr_code, color: Colors.purple, size: 32),
                SizedBox(width: 12),
                Text('Cod Acces Rapid'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Arătați acest cod medicului pentru a vă vedea datele:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.purple.shade100, Colors.blue.shade100]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(code, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.purple)),
                      const SizedBox(height: 8),
                      Text('Valabil 1 oră, utilizare unică', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cod copiat!'), duration: Duration(seconds: 1)));
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiază'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Închide')),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating quick code: $e');
    }
  }

  Future<void> _sendShareEmail({required String email, required String name, required String code, required String patientName, required bool isDoctor}) async {
    // Reload codes list
    await _loadSharedAccessCodes();
    
    try {
      final response = await Supabase.instance.client.functions.invoke('send-share-email', body: {'email': email, 'name': name, 'code': code, 'patientName': patientName, 'isDoctor': isDoctor});
      
      if (response.status == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 32), SizedBox(width: 12), Text('Email Trimis!')]),
              content: Text('Un email cu codul de acces a fost trimis la $email', style: const TextStyle(fontSize: 16)),
              actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
        }
      } else {
        throw Exception('Failed to send email');
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      if (mounted) _showAccessCode(code, name.isNotEmpty ? name : email);
    }
  }

  void _showAccessCode(String code, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 32), SizedBox(width: 12), Text('Cod Generat!')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Trimiteți acest cod către $name:', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue, width: 2)),
              child: Text(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            ),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  // ==================== UTILITY ACTIONS ====================

  void _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final phoneUrl = Uri.parse('tel:$phone');
    try {
      await launchUrl(phoneUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schimbă Parola'),
        content: const Text('Veți primi un email cu link pentru resetarea parolei.', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = Supabase.instance.client.auth.currentUser?.email;
              if (email != null) {
                await Supabase.instance.client.auth.resetPasswordForEmail(email);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Email Trimis'),
                      content: Text('Verificați emailul $email pentru link-ul de resetare.'),
                      actions: [ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                    ),
                  );
                }
              }
            },
            child: const Text('Trimite Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deconectare'),
        content: const Text('Sigur vrei să te deconectezi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulează')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Deconectare')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    }
  }
  
  Future<void> _checkForUpdates() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.healthmonitor.health_monitor_app');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nu se poate deschide Google Play Store')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e')),
        );
      }
    }
  }
}
