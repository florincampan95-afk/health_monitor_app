# Monitor Sănătate - Health Monitoring App

Aplicație mobilă Flutter pentru monitorizarea sănătății pacienților cu diabet și hipertensiune.

## Caracteristici

✅ **Înregistrare zilnică a valorilor**
- Glicemie (mg/dL)
- Tensiune arterială (sistolică/diastolică)
- Simptome

✅ **Reminder pentru medicație**
- Adăugare medicamente cu dozaj
- Programare ore de administrare
- Notificări automate

✅ **Grafice evolutive**
- Grafic glicemie în timp
- Grafic tensiune arterială
- Vizualizare tendințe

✅ **Alertă valori anormale**
- Glicemie: <70 sau >180 mg/dL
- Tensiune sistolică: <90 sau >140 mmHg
- Tensiune diastolică: <60 sau >90 mmHg

✅ **Export PDF pentru medic**
- Raport complet cu toate măsurătorile
- Statistici (medie, minim, maxim)
- Descărcare și partajare

## Tehnologii

- **Frontend**: Flutter 3.27.3
- **Backend**: Supabase
- **Database**: PostgreSQL (via Supabase)
- **Charts**: fl_chart
- **PDF**: pdf + printing packages
- **State Management**: Provider

## Setup Supabase

1. Accesează [https://lllytdpuriyncsdvtxxt.supabase.co](https://lllytdpuriyncsdvtxxt.supabase.co)

2. Deschide SQL Editor în Supabase Dashboard

3. Copiază și rulează conținutul fișierului `supabase_schema.sql`

4. Verifică că tabelele au fost create:
   - `health_readings`
   - `medications`

## Instalare și Rulare

### Cerințe
- Flutter SDK 3.27.3+
- Android SDK (pentru Android)
- Supabase account

### Pași

1. **Clonează/Deschide proiectul**
```bash
cd health_monitor_app
```

2. **Instalează dependențele**
```bash
flutter pub get
```

3. **Configurează Supabase**
Cheile sunt deja configurate în `lib/main.dart`:
- URL: `https://lllytdpuriyncsdvtxxt.supabase.co`
- Anon Key: (deja configurat)

4. **Rulează aplicația**
```bash
flutter run
```

## Structura Proiectului

```
lib/
├── main.dart                          # Entry point
├── providers/
│   └── health_data_provider.dart      # State management
├── services/
│   └── supabase_service.dart          # Backend API calls
└── screens/
    ├── home_screen.dart               # Dashboard principal
    ├── add_reading_screen.dart        # Adăugare măsurători
    ├── charts_screen.dart             # Grafice evolutive
    ├── medications_screen.dart        # Gestionare medicamente
    └── export_pdf_screen.dart         # Export raport PDF
```

## Utilizare

### 1. Adăugare Măsurătoare
- Apasă butonul `+` din ecranul principal
- Completează valorile (glicemie, tensiune, simptome)
- Salvează

### 2. Vizualizare Grafice
- Navighează la tab-ul "Grafice"
- Vezi evoluția glicemiei și tensiunii în timp
- Identifică tendințe

### 3. Gestionare Medicamente
- Navighează la tab-ul "Medicamente"
- Adaugă medicamente cu dozaj și ore
- Primește notificări pentru administrare

### 4. Export PDF
- Navighează la tab-ul "Export PDF"
- Generează raport complet
- Descarcă sau partajează cu medicul

## Integrare AI (Viitor)

Aplicația este pregătită pentru integrare cu Groq AI:
- API Key: `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`
- Funcționalități planificate:
  - Predicții glicemie bazate pe istoric
  - Recomandări personalizate
  - Detectare pattern-uri anormale
  - Sugestii pentru îmbunătățirea aderenței la tratament

## Avantaje pentru Licență

1. **Impact medical real** - Ajută pacienții să își monitorizeze sănătatea
2. **Aderență la tratament** - Reminder-uri pentru medicație
3. **Concepte moderne** - eHealth, mHealth, telemedicină
4. **Extensibilitate** - Ușor de extins cu AI și machine learning
5. **Grafice profesionale** - Vizualizare date medicale
6. **Export pentru medici** - Rapoarte PDF complete

## Disertatie

Acest proiect este dezvoltat pentru scopuri educaționale (licență).

## Contact

Pentru întrebări sau suport, contactează dezvoltatorul.
