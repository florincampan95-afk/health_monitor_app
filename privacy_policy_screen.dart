import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politica de Confidențialitate'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.privacy_tip, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Monitor Sănătate',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text(
                'Ultima actualizare: 30 Ianuarie 2026',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introducere',
              'Bine ați venit la Monitor Sănătate. Respectăm confidențialitatea dumneavoastră și ne angajăm să protejăm datele personale pe care ni le furnizați.',
            ),
            _buildSection(
              '2. Date Colectate',
              '',
              children: [
                _buildSubSection('La înregistrare (obligatoriu):', [
                  '• Numele complet',
                  '• Adresa de email',
                  '• Parola (stocată criptat)',
                ]),
                _buildSubSection('Date de sănătate:', [
                  '• Valori ale glicemiei',
                  '• Valori ale tensiunii arteriale',
                  '• Simptome și note',
                  '• Lista medicamentelor',
                ]),
                _buildSubSection('Informații opționale:', [
                  '• Număr de telefon',
                  '• Contacte de urgență',
                  '• Informații medic curant',
                ]),
              ],
            ),
            _buildHighlight(
              'Nu colectăm date de localizare, nu accesăm contactele din telefon și nu folosim datele în scopuri publicitare.',
            ),
            _buildSection(
              '3. Cum Utilizăm Datele',
              '',
              children: [
                const Text('• Afișarea istoricului măsurătorilor și graficelor'),
                const Text('• Trimiterea notificărilor pentru medicamente'),
                const Text('• Generarea rapoartelor PDF pentru medic'),
                const Text('• Partajarea datelor cu persoanele autorizate'),
                const Text('• Funcționarea asistentului AI'),
              ],
            ),
            _buildSection(
              '4. Securitatea Datelor',
              'Datele dumneavoastră sunt stocate în siguranță pe servere care respectă standardele GDPR și SOC 2. Toate comunicațiile sunt criptate.',
            ),
            _buildSection(
              '5. Partajarea Datelor',
              'Datele dumneavoastră pot fi partajate DOAR cu persoanele pe care le autorizați explicit (medic, familie) prin generarea unui cod de acces. Nu vindem și nu partajăm datele cu terți.',
            ),
            _buildSection(
              '6. Drepturile Dumneavoastră',
              '',
              children: [
                const Text('• Dreptul de acces - puteți solicita o copie a datelor'),
                const Text('• Dreptul la rectificare - puteți corecta datele'),
                const Text('• Dreptul la ștergere - puteți șterge contul din Setări'),
                const Text('• Dreptul la portabilitate - puteți exporta datele în PDF'),
              ],
            ),
            _buildSection(
              '7. Permisiuni Aplicație',
              '',
              children: [
                const Text('• Internet - pentru sincronizarea datelor'),
                const Text('• Notificări - pentru reminder-uri medicamente'),
                const Text('• Telefon - pentru apelarea contactelor de urgență'),
              ],
            ),
            _buildSection(
              '8. Contact',
              'Pentru întrebări despre confidențialitate:\nEmail: support@andreitech.ro',
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '© 2026 Monitor Sănătate\nToate drepturile rezervate',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {List<Widget>? children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          if (content.isNotEmpty)
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(item, style: const TextStyle(fontSize: 15)),
              )),
        ],
      ),
    );
  }

  Widget _buildHighlight(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
