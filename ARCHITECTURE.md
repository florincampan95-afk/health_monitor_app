# Arhitectura Aplicației Monitor Sănătate

## Diagrama de Arhitectură

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
│                         (Flutter Widgets)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ HomeScreen   │  │ ChartsScreen │  │ Medications  │          │
│  │              │  │              │  │   Screen     │          │
│  │ - Dashboard  │  │ - Glucose    │  │ - List       │          │
│  │ - Readings   │  │   Chart      │  │ - Add Med    │          │
│  │   List       │  │ - BP Chart   │  │ - Reminders  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                   │
│  ┌──────┴───────┐  ┌──────────────┐  ┌──────┴───────┐          │
│  │ AddReading   │  │ ExportPDF    │  │              │          │
│  │   Screen     │  │   Screen     │  │              │          │
│  │              │  │              │  │              │          │
│  │ - Form       │  │ - Generate   │  │              │          │
│  │ - Validation │  │ - Preview    │  │              │          │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘          │
│         │                 │                                      │
└─────────┼─────────────────┼──────────────────────────────────────┘
          │                 │
          │                 │
┌─────────┼─────────────────┼──────────────────────────────────────┐
│         │   STATE MANAGEMENT LAYER (Provider)                    │
│         │                 │                                       │
│  ┌──────▼─────────────────▼──────────────────────────┐           │
│  │                                                    │           │
│  │         HealthDataProvider                        │           │
│  │                                                    │           │
│  │  - _readings: List<Map>                           │           │
│  │  - _medications: List<Map>                        │           │
│  │  - _isLoading: bool                               │           │
│  │  - _userId: String                                │           │
│  │                                                    │           │
│  │  + loadData()                                     │           │
│  │  + addReading()                                   │           │
│  │  + addMedication()                                │           │
│  │  + checkAlert()                                   │           │
│  │                                                    │           │
│  └────────────────────┬───────────────────────────────┘           │
│                       │                                           │
└───────────────────────┼───────────────────────────────────────────┘
                        │
                        │
┌───────────────────────┼───────────────────────────────────────────┐
│         SERVICE LAYER │                                           │
│                       │                                           │
│  ┌────────────────────▼──────────────────────────┐               │
│  │                                                │               │
│  │         SupabaseService                       │               │
│  │                                                │               │
│  │  + getHealthReadings(userId)                  │               │
│  │  + addHealthReading(...)                      │               │
│  │  + getMedications(userId)                     │               │
│  │  + addMedication(...)                         │               │
│  │                                                │               │
│  └────────────────────┬───────────────────────────┘               │
│                       │                                           │
└───────────────────────┼───────────────────────────────────────────┘
                        │
                        │ HTTP/REST API
                        │
┌───────────────────────▼───────────────────────────────────────────┐
│                    BACKEND LAYER                                  │
│                    (Supabase)                                     │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │                  PostgreSQL Database                     │     │
│  │                                                          │     │
│  │  ┌──────────────────┐      ┌──────────────────┐        │     │
│  │  │ health_readings  │      │   medications    │        │     │
│  │  ├──────────────────┤      ├──────────────────┤        │     │
│  │  │ id (UUID)        │      │ id (UUID)        │        │     │
│  │  │ user_id          │      │ user_id          │        │     │
│  │  │ glucose          │      │ name             │        │     │
│  │  │ systolic         │      │ dosage           │        │     │
│  │  │ diastolic        │      │ times[]          │        │     │
│  │  │ symptoms         │      │ active           │        │     │
│  │  │ created_at       │      │ created_at       │        │     │
│  │  └──────────────────┘      └──────────────────┘        │     │
│  │                                                          │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │              Row Level Security (RLS)                    │     │
│  │  - SELECT, INSERT, UPDATE, DELETE policies               │     │
│  │  - User-based access control                             │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Flux de Date

### 1. Încărcare Date (Load Data)
```
User Action (Open App)
    ↓
HomeScreen.initState()
    ↓
HealthDataProvider.loadData()
    ↓
SupabaseService.getHealthReadings()
    ↓
Supabase REST API
    ↓
PostgreSQL Query
    ↓
Return Data
    ↓
Provider.notifyListeners()
    ↓
UI Update (Rebuild Widgets)
```

### 2. Adăugare Măsurătoare (Add Reading)
```
User Input (Form)
    ↓
AddReadingScreen._saveReading()
    ↓
Form Validation
    ↓
HealthDataProvider.addReading()
    ↓
SupabaseService.addHealthReading()
    ↓
Supabase REST API (INSERT)
    ↓
PostgreSQL Insert
    ↓
Success Response
    ↓
Provider.loadData() (Refresh)
    ↓
Navigator.pop() + SnackBar
```

### 3. Generare PDF (Export PDF)
```
User Action (Generate PDF)
    ↓
ExportPdfScreen._generatePdf()
    ↓
_createPdf(provider.readings)
    ↓
PDF Document Creation
    ├─ Header
    ├─ Readings Table
    └─ Statistics
    ↓
Printing.sharePdf()
    ↓
System Share Dialog
```

## Componente Principale

### 1. Presentation Layer (UI)
**Responsabilități:**
- Afișare interfață utilizator
- Capturare input utilizator
- Navigare între ecrane
- Feedback vizual

**Tehnologii:**
- Flutter Widgets
- Material Design 3
- Navigation 2.0

### 2. State Management Layer
**Responsabilități:**
- Gestionare stare aplicație
- Notificare UI la schimbări
- Cache date în memorie
- Logică business

**Tehnologii:**
- Provider package
- ChangeNotifier
- Consumer widgets

### 3. Service Layer
**Responsabilități:**
- Comunicare cu backend
- Transformare date
- Gestionare erori
- Retry logic

**Tehnologii:**
- Supabase Client
- HTTP requests
- JSON serialization

### 4. Backend Layer
**Responsabilități:**
- Stocare date persistente
- Autentificare/Autorizare
- Validare date
- Backup/Recovery

**Tehnologii:**
- Supabase (BaaS)
- PostgreSQL
- Row Level Security

## Pattern-uri de Design

### 1. Repository Pattern
```dart
// Service Layer acts as Repository
class SupabaseService {
  static Future<List<Map>> getHealthReadings(String userId) {
    // Abstract database access
  }
}
```

### 2. Provider Pattern (State Management)
```dart
// Provider for reactive state
class HealthDataProvider extends ChangeNotifier {
  void loadData() {
    // Update state
    notifyListeners(); // Notify UI
  }
}
```

### 3. Singleton Pattern
```dart
// Supabase client is singleton
static final SupabaseClient client = Supabase.instance.client;
```

### 4. Observer Pattern
```dart
// Widgets observe provider changes
Consumer<HealthDataProvider>(
  builder: (context, provider, child) {
    // Rebuild when provider changes
  }
)
```

## Securitate

### 1. Row Level Security (RLS)
```sql
-- Only users can access their own data
CREATE POLICY "Users can view their own readings"
ON health_readings FOR SELECT
USING (user_id = auth.uid());
```

### 2. Input Validation
```dart
// Client-side validation
validator: (value) {
  if (val < 0 || val > 600) return 'Invalid';
}
```

### 3. HTTPS Communication
- Toate request-urile către Supabase sunt HTTPS
- Certificate pinning (opțional pentru producție)

## Scalabilitate

### Horizontal Scaling
- Supabase gestionează automat scaling-ul
- PostgreSQL connection pooling
- CDN pentru assets statice

### Vertical Scaling
- Upgrade plan Supabase pentru mai multe resurse
- Optimizare query-uri cu indexuri
- Cache local cu SharedPreferences

### Performance Optimizations
- Lazy loading pentru liste lungi
- Pagination pentru date mari
- Image caching
- Debouncing pentru search

## Extensii Viitoare

### 1. Autentificare
```
Supabase Auth
├─ Email/Password
├─ OAuth (Google, Apple)
└─ Magic Link
```

### 2. Real-time Updates
```
Supabase Realtime
└─ WebSocket connection
    └─ Live data sync
```

### 3. AI Integration (Groq)
```
Flutter App
    ↓
Groq API
    ↓
LLaMA 3.3 70B
    ↓
Predictions/Recommendations
```

### 4. Offline Support
```
Local Database (SQLite)
    ↓
Sync Queue
    ↓
Background Sync
    ↓
Supabase
```

## Metrici de Performanță

### Response Times
- Load data: <2s
- Add reading: <1s
- Generate PDF: <3s
- Chart rendering: <500ms

### Resource Usage
- Memory: ~100MB
- Storage: ~50MB (APK)
- Network: ~1KB per reading

### Availability
- Supabase uptime: 99.9%
- Offline mode: Planned
- Error recovery: Automatic retry
