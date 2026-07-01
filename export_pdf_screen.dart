import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/health_data_provider.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  String _period = '30'; // 7, 30, all
  bool _includeGlucose = true;
  bool _includeBP = true;
  bool _includeMeds = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthDataProvider>(
      builder: (context, provider, child) {
        final filteredReadings = _filterByPeriod(provider.readings);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf, size: 48, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      const Text('Export Raport Medical',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Generați un raport PDF pentru medic',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Period selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Perioadă raport', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPeriodOption('7 zile', '7'),
                          _buildPeriodOption('30 zile', '30'),
                          _buildPeriodOption('Tot istoricul', 'all'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content options
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.checklist, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Conținut raport', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Măsurători glicemie'),
                        subtitle: Text('${_countGlucose(filteredReadings)} înregistrări'),
                        value: _includeGlucose,
                        onChanged: (v) => setState(() => _includeGlucose = v!),
                        secondary: const Icon(Icons.water_drop, color: Colors.blue),
                      ),
                      CheckboxListTile(
                        title: const Text('Măsurători tensiune'),
                        subtitle: Text('${_countBP(filteredReadings)} înregistrări'),
                        value: _includeBP,
                        onChanged: (v) => setState(() => _includeBP = v!),
                        secondary: const Icon(Icons.favorite, color: Colors.red),
                      ),
                      CheckboxListTile(
                        title: const Text('Lista medicamente'),
                        subtitle: Text('${provider.medications.length} medicamente active'),
                        value: _includeMeds,
                        onChanged: (v) => setState(() => _includeMeds = v!),
                        secondary: const Icon(Icons.medication, color: Colors.purple),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Summary
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Raportul va conține ${filteredReadings.length} măsurători din perioada selectată',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: filteredReadings.isEmpty ? null : () => _previewPdf(context, provider, filteredReadings),
                  icon: const Icon(Icons.preview, size: 28),
                  label: const Text('PREVIZUALIZARE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: filteredReadings.isEmpty ? null : () => _sharePdf(context, provider, filteredReadings),
                  icon: const Icon(Icons.share, size: 28),
                  label: const Text('TRIMITE / SALVEAZĂ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String label, String value) {
    final isSelected = _period == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: Colors.blue,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          onSelected: (_) => setState(() => _period = value),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterByPeriod(List<Map<String, dynamic>> readings) {
    if (_period == 'all') return readings;
    final days = int.parse(_period);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return readings.where((r) {
      final date = DateTime.parse(r['created_at']);
      return date.isAfter(cutoff);
    }).toList();
  }

  int _countGlucose(List<Map<String, dynamic>> readings) {
    return readings.where((r) => r['glucose'] != null).length;
  }

  int _countBP(List<Map<String, dynamic>> readings) {
    return readings.where((r) => r['systolic'] != null).length;
  }

  Future<void> _previewPdf(BuildContext context, HealthDataProvider provider, List<Map<String, dynamic>> readings) async {
    final pdf = await _createPdf(provider, readings);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _sharePdf(BuildContext context, HealthDataProvider provider, List<Map<String, dynamic>> readings) async {
    final pdf = await _createPdf(provider, readings);
    final now = DateTime.now();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'raport_medical_${now.day}_${now.month}_${now.year}.pdf',
    );
  }

  Future<pw.Document> _createPdf(HealthDataProvider provider, List<Map<String, dynamic>> readings) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final List<Map<String, dynamic>> glucoseReadings = _includeGlucose
        ? List<Map<String, dynamic>>.from(readings.where((r) => r['glucose'] != null))
        : [];
    final List<Map<String, dynamic>> bpReadings = _includeBP
        ? List<Map<String, dynamic>>.from(readings.where((r) => r['systolic'] != null))
        : [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(fontBold),
        footer: (context) => _buildFooter(context, font),
        build: (context) => [
          _buildPatientInfo(provider, fontBold),
          pw.SizedBox(height: 20),
          _buildPeriodInfo(readings, font),
          pw.SizedBox(height: 20),
          if (glucoseReadings.isNotEmpty) ...[
            _buildSectionTitle('Glicemie', fontBold),
            _buildGlucoseStats(glucoseReadings, font, fontBold),
            pw.SizedBox(height: 10),
            _buildGlucoseTable(glucoseReadings, font, fontBold),
            pw.SizedBox(height: 20),
          ],
          if (bpReadings.isNotEmpty) ...[
            _buildSectionTitle('Tensiune Arteriala', fontBold),
            _buildBPStats(bpReadings, font, fontBold),
            pw.SizedBox(height: 10),
            _buildBPTable(bpReadings, font, fontBold),
            pw.SizedBox(height: 20),
          ],
          if (_includeMeds && provider.medications.isNotEmpty) ...[
            _buildSectionTitle('Medicamente Active', fontBold),
            _buildMedicationsTable(provider.medications, font, fontBold),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('RAPORT MEDICAL', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue)),
          pw.Text('Monitor Sanatate', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generat: ${_formatDate(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
          pw.Text('Pagina ${context.pageNumber} din ${context.pagesCount}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildPatientInfo(HealthDataProvider provider, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PACIENT', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(provider.userName ?? 'Necunoscut', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              pw.Text(provider.userEmail ?? '', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPeriodInfo(List<Map<String, dynamic>> readings, pw.Font font) {
    String periodText = _period == 'all' ? 'Tot istoricul' : 'Ultimele $_period zile';
    return pw.Text('Perioada: $periodText (${readings.length} masuratori)',
      style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700));
  }

  pw.Widget _buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white)),
    );
  }

  pw.Widget _buildGlucoseStats(List<Map<String, dynamic>> readings, pw.Font font, pw.Font fontBold) {
    final values = readings.map((r) => (r['glucose'] as num).toDouble()).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final normalCount = values.where((v) => v >= 70 && v <= 125).length;
    final normalPercent = (normalCount / values.length * 100).toInt();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox('Media', '${avg.toInt()} mg/dL', fontBold),
          _buildStatBox('Minim', '${min.toInt()} mg/dL', fontBold),
          _buildStatBox('Maxim', '${max.toInt()} mg/dL', fontBold),
          _buildStatBox('In normal', '$normalPercent%', fontBold, normalPercent >= 70 ? PdfColors.green : PdfColors.orange),
        ],
      ),
    );
  }

  pw.Widget _buildBPStats(List<Map<String, dynamic>> readings, pw.Font font, pw.Font fontBold) {
    final systolic = readings.map((r) => (r['systolic'] as num).toDouble()).toList();
    final diastolic = readings.map((r) => (r['diastolic'] as num).toDouble()).toList();
    final avgSys = systolic.reduce((a, b) => a + b) / systolic.length;
    final avgDia = diastolic.reduce((a, b) => a + b) / diastolic.length;
    final normalCount = readings.where((r) =>
      (r['systolic'] as num) <= 140 && (r['diastolic'] as num) <= 90).length;
    final normalPercent = (normalCount / readings.length * 100).toInt();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox('Media Sistolica', '${avgSys.toInt()} mmHg', fontBold),
          _buildStatBox('Media Diastolica', '${avgDia.toInt()} mmHg', fontBold),
          _buildStatBox('In normal', '$normalPercent%', fontBold, normalPercent >= 70 ? PdfColors.green : PdfColors.orange),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value, pw.Font fontBold, [PdfColor? valueColor]) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14, color: valueColor ?? PdfColors.black)),
      ],
    );
  }

  pw.Widget _buildGlucoseTable(List<Map<String, dynamic>> readings, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Data si Ora', fontBold),
            _tableHeader('Valoare', fontBold),
            _tableHeader('Status', fontBold),
            _tableHeader('Context', fontBold),
            _tableHeader('Simptome', fontBold),
          ],
        ),
        ...readings.take(30).map((r) {
          final value = (r['glucose'] as num).toDouble();
          String status = 'Normal';
          PdfColor statusColor = PdfColors.green;
          if (value < 70) { status = 'Scazuta'; statusColor = PdfColors.orange; }
          else if (value > 180) { status = 'Crescuta'; statusColor = PdfColors.red; }
          else if (value > 125) { status = 'Usor crescuta'; statusColor = PdfColors.orange; }

          String contextText = _formatContext(r['reading_context'], r['meal_type']);

          return pw.TableRow(children: [
            _tableCell(_formatDate(DateTime.parse(r['created_at'])), font),
            _tableCell('${value.toInt()} mg/dL', font),
            _tableCellColored(status, font, statusColor),
            _tableCell(contextText, font),
            _tableCell(r['symptoms']?.toString() ?? '-', font),
          ]);
        }),
      ],
    );
  }

  pw.Widget _buildBPTable(List<Map<String, dynamic>> readings, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Data si Ora', fontBold),
            _tableHeader('Valoare', fontBold),
            _tableHeader('Status', fontBold),
            _tableHeader('Context', fontBold),
            _tableHeader('Simptome', fontBold),
          ],
        ),
        ...readings.take(30).map((r) {
          final sys = (r['systolic'] as num).toDouble();
          final dia = (r['diastolic'] as num).toDouble();
          String status = 'Normal';
          PdfColor statusColor = PdfColors.green;
          if (sys > 140 || dia > 90) { status = 'Crescuta'; statusColor = PdfColors.red; }
          else if (sys > 130 || dia > 85) { status = 'Usor crescuta'; statusColor = PdfColors.orange; }
          else if (sys < 90 || dia < 60) { status = 'Scazuta'; statusColor = PdfColors.orange; }

          String contextText = _formatContext(r['reading_context'], r['meal_type']);

          return pw.TableRow(children: [
            _tableCell(_formatDate(DateTime.parse(r['created_at'])), font),
            _tableCell('${sys.toInt()}/${dia.toInt()} mmHg', font),
            _tableCellColored(status, font, statusColor),
            _tableCell(contextText, font),
            _tableCell(r['symptoms']?.toString() ?? '-', font),
          ]);
        }),
      ],
    );
  }

  pw.Widget _buildMedicationsTable(List<Map<String, dynamic>> medications, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Medicament', fontBold),
            _tableHeader('Dozaj', fontBold),
            _tableHeader('Ore administrare', fontBold),
          ],
        ),
        ...medications.map((m) {
          final times = (m['times'] as List?)?.join(', ') ?? '-';
          return pw.TableRow(children: [
            _tableCell(m['name'] ?? '-', font),
            _tableCell(m['dosage'] ?? '-', font),
            _tableCell(times, font),
          ]);
        }),
      ],
    );
  }

  pw.Widget _tableHeader(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: fontBold, fontSize: 10)),
    );
  }

  pw.Widget _tableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  pw.Widget _tableCellColored(String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, color: color)),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final days = ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sam', 'Dum'];
    return '${days[localDate.weekday - 1]} ${localDate.day}.${localDate.month}.${localDate.year} ${localDate.hour}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  String _formatContext(String? readingContext, String? mealType) {
    List<String> parts = [];

    if (readingContext != null) {
      switch (readingContext) {
        case 'fasting':
          parts.add('Pe nemancate');
          break;
        case 'before_meal':
          parts.add('Inainte de masa');
          break;
        case 'after_meal':
          parts.add('Dupa masa');
          break;
        case 'before_sleep':
          parts.add('Inainte de culcare');
          break;
        case 'after_exercise':
          parts.add('Dupa exercitii');
          break;
      }
    }

    if (mealType != null) {
      switch (mealType) {
        case 'breakfast':
          parts.add('Mic dejun');
          break;
        case 'lunch':
          parts.add('Pranz');
          break;
        case 'dinner':
          parts.add('Cina');
          break;
        case 'snack':
          parts.add('Gustare');
          break;
      }
    }

    return parts.isEmpty ? '-' : parts.join(', ');
  }
}
