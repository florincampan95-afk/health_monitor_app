# Ghid Rapid de Configurare

## 1. Setup Supabase Database

### Pasul 1: Accesează Supabase Dashboard
1. Deschide browser-ul și accesează: https://lllytdpuriyncsdvtxxt.supabase.co
2. Autentifică-te cu credențialele tale Supabase

### Pasul 2: Creează Tabelele
1. În dashboard, navighează la **SQL Editor** (din meniul lateral stâng)
2. Click pe **New Query**
3. Deschide fișierul `supabase_schema.sql` din proiect
4. Copiază tot conținutul și lipește-l în SQL Editor
5. Click pe **Run** sau apasă `Ctrl+Enter`
6. Verifică că vezi mesajul de succes

### Pasul 3: Verifică Tabelele
1. Navighează la **Table Editor** din meniul lateral
2. Ar trebui să vezi 2 tabele noi:
   - `health_readings` - pentru măsurători
   - `medications` - pentru medicamente
3. Verifică că există date de test (5 măsurători și 2 medicamente pentru `demo-user`)

## 2. Rulare Aplicație

### Opțiunea A: Android Emulator

1. **Pornește Android Emulator**
```bash
# Listează emulatoarele disponibile
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/emulator:$PATH
emulator -list-avds

# Pornește un emulator (dacă există)
emulator -avd <nume_avd> &
```

2. **Rulează aplicația**
```bash
cd health_monitor_app
export PATH="$HOME/flutter/bin:$PATH"
flutter run
```

### Opțiunea B: Dispozitiv Fizic Android

1. **Activează Developer Options pe telefon**
   - Setări → Despre telefon → Apasă de 7 ori pe "Build number"
   - Setări → Developer Options → Activează "USB Debugging"

2. **Conectează telefonul la PC via USB**

3. **Verifică conexiunea**
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
adb devices
```

4. **Rulează aplicația**
```bash
cd health_monitor_app
export PATH="$HOME/flutter/bin:$PATH"
flutter run
```

### Opțiunea C: Linux Desktop (pentru testare rapidă)

```bash
cd health_monitor_app
export PATH="$HOME/flutter/bin:$PATH"
flutter run -d linux
```

## 3. Testare Funcționalități

### Test 1: Vizualizare Date Existente
1. Deschide aplicația
2. Ar trebui să vezi 5 măsurători de test în ecranul principal
3. Observă că una dintre ele are indicator roșu (valoare anormală)

### Test 2: Adăugare Măsurătoare Nouă
1. Apasă butonul `+` (floating action button)
2. Completează:
   - Glicemie: 150
   - Sistolică: 130
   - Diastolică: 85
   - Simptome: "Test"
3. Apasă "Salvează Măsurătoarea"
4. Verifică că apare în listă

### Test 3: Vizualizare Grafice
1. Navighează la tab-ul "Grafice" (al doilea icon din bottom navigation)
2. Ar trebui să vezi:
   - Grafic cu evoluția glicemiei
   - Grafic cu evoluția tensiunii (sistolică în roșu, diastolică în albastru)

### Test 4: Gestionare Medicamente
1. Navighează la tab-ul "Medicamente"
2. Ar trebui să vezi 2 medicamente de test
3. Apasă "Adaugă Medicament"
4. Completează:
   - Nume: "Paracetamol"
   - Dozaj: "500mg"
   - Ora 1: "12:00"
5. Salvează

### Test 5: Export PDF
1. Navighează la tab-ul "Export PDF"
2. Apasă "Previzualizare PDF"
3. Ar trebui să vezi un raport cu:
   - Toate măsurătorile în tabel
   - Statistici (medie, minim, maxim)
4. Poți descărca sau partaja PDF-ul

## 4. Troubleshooting

### Eroare: "Unable to connect to Supabase"
- Verifică conexiunea la internet
- Verifică că URL-ul și cheia Supabase sunt corecte în `lib/main.dart`
- Verifică că tabelele au fost create în Supabase

### Eroare: "No data found"
- Verifică că ai rulat scriptul SQL în Supabase
- Verifică că există date pentru `user_id = 'demo-user'`
- Verifică politicile RLS în Supabase (ar trebui să permită acces public pentru demo)

### Aplicația nu pornește
```bash
# Curăță cache-ul Flutter
flutter clean
flutter pub get

# Verifică că toate dependențele sunt instalate
flutter doctor

# Încearcă din nou
flutter run
```

### Graficele nu se afișează
- Verifică că există cel puțin 2 măsurători în baza de date
- Verifică că măsurătorile au valori pentru glicemie sau tensiune

## 5. Următorii Pași

### Pentru Dezvoltare Ulterioară:

1. **Autentificare Utilizatori**
   - Implementează Supabase Auth
   - Înlocuiește `demo-user` cu user ID real

2. **Notificări Push**
   - Configurează Firebase Cloud Messaging
   - Implementează reminder-uri pentru medicamente

3. **Integrare AI (Groq)**
   - Adaugă predicții pentru glicemie
   - Implementează recomandări personalizate
   - Detectare pattern-uri anormale

4. **Îmbunătățiri UI/UX**
   - Adaugă animații
   - Îmbunătățește design-ul graficelor
   - Adaugă dark mode

5. **Funcționalități Noi**
   - Sincronizare cu dispozitive medicale
   - Partajare date cu medicul
   - Istoric detaliat pe perioade
   - Rapoarte săptămânale/lunare

## 6. Resurse Utile

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [fl_chart Examples](https://github.com/imaNNeo/fl_chart)
- [Groq AI Documentation](https://console.groq.com/docs)

## Contact

Pentru probleme sau întrebări, verifică:
1. Logs în terminal când rulezi `flutter run`
2. Supabase Dashboard pentru erori de bază de date
3. README.md pentru informații generale
