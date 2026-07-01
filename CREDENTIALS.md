# Credențiale și Chei API

## Supabase

### Project URL
```
https://lllytdpuriyncsdvtxxt.supabase.co
```

### Anon/Public Key
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsbHl0ZHB1cml5bmNzZHZ0eHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5NzY4NzAsImV4cCI6MjA1MzU1Mjg3MH0.VYmcWFQFZIBELKC9arvZsA_1JvCFSw4G
```

### Service Role Key (Secret - Nu expune public!)
```
sb_publishable_VYmcWFQFZIBELKC9arvZsA_1JvCFSw4G
```

## Groq AI (Pentru integrare viitoare)

### API Key
```
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
```

### Endpoint
```
https://api.groq.com/openai/v1/chat/completions
```

### Model Recomandat
```
llama-3.3-70b-versatile
```

## User Demo

### User ID (pentru testare)
```
demo-user
```

## Notă Importantă

⚠️ **SECURITATE**: 
- Aceste chei sunt pentru dezvoltare/demo
- Pentru producție, folosește variabile de mediu
- Nu include niciodată chei secrete în cod
- Folosește `.env` files și `.gitignore`

## Configurare Variabile de Mediu (Recomandare pentru Producție)

### 1. Creează fișier `.env`
```env
SUPABASE_URL=https://lllytdpuriyncsdvtxxt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GROQ_API_KEY=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
```

### 2. Adaugă în `.gitignore`
```
.env
.env.local
.env.production
```

### 3. Folosește în cod
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
final supabaseUrl = dotenv.env['SUPABASE_URL']!;
final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;
```

## Link-uri Utile

- **Supabase Dashboard**: https://app.supabase.com/project/lllytdpuriyncsdvtxxt
- **Supabase Table Editor**: https://app.supabase.com/project/lllytdpuriyncsdvtxxt/editor
- **Supabase SQL Editor**: https://app.supabase.com/project/lllytdpuriyncsdvtxxt/sql
- **Groq Console**: https://console.groq.com/
