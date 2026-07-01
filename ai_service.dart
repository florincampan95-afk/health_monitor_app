import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama-3.3-70b-versatile';
  
  // General chat response with patient context
  Future<String> getChatResponse(
    String userMessage, {
    List<Map<String, dynamic>>? recentReadings,
    List<Map<String, dynamic>>? medications,
    Map<String, dynamic>? adherenceStats,
  }) async {
    // Build comprehensive context from patient data
    String patientContext = '';
    
    if (recentReadings != null && recentReadings.isNotEmpty) {
      patientContext += '\n\n📊 MĂSURĂTORI RECENTE ALE PACIENTULUI:\n';
      
      // Calculate averages
      double avgGlucose = 0;
      double avgSystolic = 0;
      double avgDiastolic = 0;
      int glucoseCount = 0;
      int bpCount = 0;
      
      for (var reading in recentReadings.take(10)) {
        final date = reading['created_at'] ?? '';
        final glucose = reading['glucose'];
        final systolic = reading['systolic'];
        final diastolic = reading['diastolic'];
        final symptoms = reading['symptoms'] ?? '';
        
        // Add to averages
        if (glucose != null) {
          avgGlucose += glucose;
          glucoseCount++;
        }
        if (systolic != null && diastolic != null) {
          avgSystolic += systolic;
          avgDiastolic += diastolic;
          bpCount++;
        }
        
        // List recent readings
        if (recentReadings.indexOf(reading) < 5) {
          patientContext += '• ${date.split('T')[0]}: ';
          if (glucose != null) patientContext += 'Glicemie: $glucose mg/dL';
          if (systolic != null && diastolic != null) {
            if (glucose != null) patientContext += ', ';
            patientContext += 'Tensiune: $systolic/$diastolic mmHg';
          }
          if (symptoms.isNotEmpty) patientContext += ' | Simptome: $symptoms';
          patientContext += '\n';
        }
      }
      
      // Add averages
      if (glucoseCount > 0) {
        avgGlucose = avgGlucose / glucoseCount;
        patientContext += '\n📈 Media glicemiei (ultimele $glucoseCount măsurători): ${avgGlucose.toStringAsFixed(1)} mg/dL\n';
        
        // Add interpretation
        if (avgGlucose < 70) {
          patientContext += '⚠️ ATENȚIE: Glicemie medie SCĂZUTĂ (risc hipoglicemie)\n';
        } else if (avgGlucose > 125) {
          patientContext += '⚠️ ATENȚIE: Glicemie medie CRESCUTĂ (risc hiperglicemie)\n';
        } else {
          patientContext += '✅ Glicemie medie în interval normal\n';
        }
      }
      
      if (bpCount > 0) {
        avgSystolic = avgSystolic / bpCount;
        avgDiastolic = avgDiastolic / bpCount;
        patientContext += '\n📈 Media tensiunii (ultimele $bpCount măsurători): ${avgSystolic.toStringAsFixed(0)}/${avgDiastolic.toStringAsFixed(0)} mmHg\n';
        
        // Add interpretation
        if (avgSystolic < 90 || avgDiastolic < 60) {
          patientContext += '⚠️ ATENȚIE: Tensiune medie SCĂZUTĂ (hipotensiune)\n';
        } else if (avgSystolic > 140 || avgDiastolic > 90) {
          patientContext += '⚠️ ATENȚIE: Tensiune medie CRESCUTĂ (hipertensiune)\n';
        } else if (avgSystolic > 120 || avgDiastolic > 80) {
          patientContext += '⚠️ Tensiune medie ușor crescută (prehipertensiune)\n';
        } else {
          patientContext += '✅ Tensiune medie în interval normal\n';
        }
      }
    }
    
    if (medications != null && medications.isNotEmpty) {
      patientContext += '\n💊 MEDICAMENTELE PACIENTULUI:\n';
      for (var med in medications) {
        final name = med['name'] ?? '';
        final dosage = med['dosage'] ?? '';
        final frequency = med['frequency'] ?? '';
        final time = med['reminder_time'] ?? '';
        patientContext += '• $name - $dosage ($frequency)';
        if (time.isNotEmpty) patientContext += ' la ora $time';
        patientContext += '\n';
      }
    }
    
    if (adherenceStats != null) {
      final adherence = adherenceStats['adherence_percent'] ?? 0;
      final taken = adherenceStats['taken'] ?? 0;
      final total = adherenceStats['total'] ?? 0;
      
      patientContext += '\n📋 ADERENȚĂ LA TRATAMENT:\n';
      patientContext += '• Aderență: ${adherence.toStringAsFixed(1)}% ($taken din $total doze luate)\n';
      
      if (adherence < 50) {
        patientContext += '⚠️ ATENȚIE: Aderență FOARTE SCĂZUTĂ - risc major pentru sănătate!\n';
      } else if (adherence < 80) {
        patientContext += '⚠️ Aderență scăzută - pacientul trebuie încurajat să ia medicamentele regulat\n';
      } else if (adherence >= 90) {
        patientContext += '✅ Aderență EXCELENTĂ - pacientul urmează tratamentul corect\n';
      } else {
        patientContext += '✅ Aderență bună - pacientul urmează tratamentul\n';
      }
    }
    
    final response = await _callGroq(
      messages: [
        {
          'role': 'system',
          'content': 'Ești un asistent medical AI specializat pentru pacienți cu diabet și hipertensiune. '
                     'AI ACCES COMPLET LA DATELE MEDICALE ALE PACIENTULUI. '
                     '\n\nROLUL TĂU:'
                     '\n• Analizează măsurătorile și oferă sfaturi personalizate'
                     '\n• Identifică tendințe și valori anormale'
                     '\n• Oferă recomandări pentru dietă, exerciții și stil de viață'
                     '\n• Răspunde la întrebări despre medicamente și efecte secundare'
                     '\n• Încurajează aderența la tratament'
                     '\n• Explică rezultatele în termeni simpli'
                     '\n\nIMPORTANT - FORMATARE:'
                     '\n• **PUNE ÎN BOLD (folosind **text**) TOATE valorile numerice ale pacientului**'
                     '\n• **PUNE ÎN BOLD toate datele, medicamentele și măsurătorile specifice**'
                     '\n• Exemple: "glicemia ta de **145 mg/dL**", "tensiunea de **140/95 mmHg**", "medicamentul **Metformin**"'
                     '\n• Folosește bold pentru a evidenția informațiile importante din datele pacientului'
                     '\n\nALTE REGULI:'
                     '\n• Folosește datele pacientului pentru răspunsuri personalizate'
                     '\n• Menționează valorile specifice când răspunzi'
                     '\n• Reamintește să consulte medicul pentru decizii importante'
                     '\n• Fii empatic și încurajator'
                     '\n• Răspunde ÎNTOTDEAUNA în limba română'
                     '\n$patientContext'
        },
        {
          'role': 'user',
          'content': userMessage,
        }
      ],
      temperature: 0.7,
      maxTokens: 1000,
    );
    
    return response;
  }
  
  // Apel generic către Groq API
  Future<String> _callGroq({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'top_p': 1,
          'stream': false,
        }),
      );
      
      if (response.statusCode != 200) {
        final errorBody = response.body;
        print('Groq API Error - Status: ${response.statusCode}');
        print('Groq API Error - Body: $errorBody');
        throw Exception('Groq API error (${response.statusCode}): $errorBody');
      }
      
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      print('Exception in _callGroq: $e');
      rethrow;
    }
  }
}
