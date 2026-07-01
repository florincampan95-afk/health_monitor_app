# Ghid de Testare - Monitor Sănătate

## Pregătire pentru Testare

### 1. Verifică Setup-ul
```bash
cd health_monitor_app
export PATH="$HOME/flutter/bin:$PATH"
flutter doctor
```

Ar trebui să vezi:
- ✓ Flutter
- ✓ Android toolchain
- ✓ Linux toolchain

### 2. Verifică Supabase
1. Accesează https://lllytdpuriyncsdvtxxt.supabase.co
2. Verifică că tabelele există:
   - `health_readings`
   - `medications`
3. Verifică date de test pentru `demo-user`

## Scenarii de Testare

### Test 1: Pornire Aplicație și Încărcare Date

**Obiectiv**: Verifică că aplicația pornește și încarcă datele din Supabase

**Pași**:
1. Rulează aplicația: `flutter run`
2. Așteaptă încărcarea
3. Verifică că vezi 5 măsurători de test

**Rezultat Așteptat**:
- Aplicația pornește fără erori
- Se afișează lista cu măsurători
- Una dintre măsurători are indicator roșu (valoare anormală)
- Datele sunt formatate corect (dată, oră, valori)

**Criterii de Succes**:
- ✓ Aplicația pornește în <5 secunde
- ✓ Datele se încarcă în <2 secunde
- ✓ Nu apar erori în console

---

### Test 2: Adăugare Măsurătoare Normală

**Obiectiv**: Verifică funcționalitatea de adăugare măsurători cu valori normale

**Pași**:
1. Apasă butonul `+` (floating action button)
2. Completează formularul:
   - Glicemie: `110`
   - Sistolică: `120`
   - Diastolică: `80`
   - Simptome: `Mă simt bine`
3. Apasă "Salvează Măsurătoarea"

**Rezultat Așteptat**:
- Formular se validează corect
- Apare mesaj "Măsurătoare salvată cu succes!"
- Revii la ecranul principal
- Noua măsurătoare apare în listă (prima)
- Card-ul este alb (valori normale)

**Criterii de Succes**:
- ✓ Salvare în <1 secundă
- ✓ UI se actualizează automat
- ✓ Datele sunt corecte în listă

---

### Test 3: Adăugare Măsurătoare cu Valori Anormale

**Obiectiv**: Verifică sistemul de alertă pentru valori în afara intervalului normal

**Pași**:
1. Apasă butonul `+`
2. Completează:
   - Glicemie: `200` (peste limită)
   - Sistolică: `160` (peste limită)
   - Diastolică: `100` (peste limită)
   - Simptome: `Durere de cap, amețeală`
3. Salvează

**Rezultat Așteptat**:
- Măsurătoarea se salvează
- Card-ul apare cu fundal roșu deschis
- Icon warning (⚠️) în loc de inimă
- Toate valorile sunt afișate corect

**Criterii de Succes**:
- ✓ Alertă vizuală clară
- ✓ Utilizatorul înțelege că valorile sunt anormale
- ✓ Simptomele sunt afișate complet

---

### Test 4: Validare Formular

**Obiectiv**: Verifică validarea input-urilor

**Pași**:
1. Apasă butonul `+`
2. Încearcă să introduci valori invalide:
   - Glicemie: `700` (peste limită)
   - Sistolică: `350` (peste limită)
   - Diastolică: `-10` (negativă)
3. Încearcă să salvezi

**Rezultat Așteptat**:
- Apar mesaje de eroare sub câmpuri
- Butonul "Salvează" nu funcționează
- Mesaje clare: "Valoare invalidă"

**Criterii de Succes**:
- ✓ Validare funcționează
- ✓ Mesaje de eroare clare
- ✓ Nu se salvează date invalide

---

### Test 5: Vizualizare Grafice

**Obiectiv**: Verifică generarea și afișarea graficelor

**Pași**:
1. Navighează la tab-ul "Grafice" (al doilea icon)
2. Observă graficul de glicemie
3. Scroll down pentru graficul de tensiune

**Rezultat Așteptat**:
- **Grafic Glicemie**:
  - Linie albastră curbată
  - Puncte pentru fiecare măsurătoare
  - Axe cu valori clare
  - Legendă explicativă
  
- **Grafic Tensiune**:
  - Două linii (roșu = sistolică, albastru = diastolică)
  - Evoluție vizibilă
  - Legendă cu culori

**Criterii de Succes**:
- ✓ Graficele se încarcă în <1 secundă
- ✓ Datele sunt corecte
- ✓ Graficele sunt interactive (zoom, pan)
- ✓ Design profesional

---

### Test 6: Gestionare Medicamente

**Obiectiv**: Verifică adăugarea și afișarea medicamentelor

**Pași**:
1. Navighează la tab-ul "Medicamente"
2. Verifică medicamentele existente (Metformin, Aspirina)
3. Apasă "Adaugă Medicament"
4. Completează:
   - Nume: `Paracetamol`
   - Dozaj: `500mg`
   - Ora 1: `08:00`
   - Apasă "Adaugă oră"
   - Ora 2: `20:00`
5. Salvează

**Rezultat Așteptat**:
- Dialog se deschide corect
- Poți adăuga multiple ore
- Medicamentul apare în listă
- Afișează: nume, dozaj, ore

**Criterii de Succes**:
- ✓ Adăugare funcționează
- ✓ Multiple ore suportate
- ✓ UI clar și intuitiv

---

### Test 7: Export PDF - Previzualizare

**Obiectiv**: Verifică generarea și previzualizarea PDF

**Pași**:
1. Navighează la tab-ul "Export PDF"
2. Verifică numărul total de măsurători afișat
3. Apasă "Previzualizare PDF"
4. Așteaptă generarea

**Rezultat Așteptat**:
- Se deschide viewer PDF
- PDF conține:
  - Header: "Raport Medical - Monitor Sănătate"
  - Data generării
  - Tabel cu măsurători (max 20)
  - Statistici:
    - Media glicemiei
    - Min/Max glicemie
    - Media tensiunii
    - Min/Max tensiune

**Criterii de Succes**:
- ✓ PDF se generează în <3 secunde
- ✓ Toate datele sunt corecte
- ✓ Format profesional
- ✓ Lizibil și bine structurat

---

### Test 8: Export PDF - Descărcare

**Obiectiv**: Verifică descărcarea și partajarea PDF

**Pași**:
1. În tab-ul "Export PDF"
2. Apasă "Generează și Descarcă PDF"
3. Alege opțiune de partajare (email, drive, etc.)

**Rezultat Așteptat**:
- Se deschide dialog de partajare Android
- PDF este disponibil pentru partajare
- Nume fișier: `raport_medical_[timestamp].pdf`

**Criterii de Succes**:
- ✓ PDF se poate descărca
- ✓ PDF se poate partaja
- ✓ Fișierul este valid

---

### Test 9: Performanță - Multe Date

**Obiectiv**: Verifică performanța cu multe măsurători

**Pași**:
1. Adaugă 20+ măsurători rapid
2. Verifică scroll în listă
3. Verifică graficele
4. Generează PDF

**Rezultat Așteptat**:
- Lista scrollează smooth
- Graficele afișează ultimele 10 măsurători
- PDF conține toate datele (max 20 în tabel)
- Nu apar lag-uri

**Criterii de Succes**:
- ✓ 60 FPS la scroll
- ✓ Grafice se actualizează instant
- ✓ PDF se generează în <5 secunde

---

### Test 10: Gestionare Erori - Fără Internet

**Obiectiv**: Verifică comportamentul fără conexiune

**Pași**:
1. Dezactivează WiFi și date mobile
2. Încearcă să adaugi o măsurătoare
3. Încearcă să încarci datele

**Rezultat Așteptat**:
- Apare mesaj de eroare clar
- Aplicația nu crashuiește
- Datele locale (cache) rămân disponibile

**Criterii de Succes**:
- ✓ Eroare gestionată elegant
- ✓ Mesaj clar pentru utilizator
- ✓ Aplicația rămâne funcțională

---

## Teste Automate (Opțional)

### Unit Tests

```dart
// test/providers/health_data_provider_test.dart
void main() {
  test('checkAlert returns true for high glucose', () {
    final provider = HealthDataProvider();
    expect(provider.checkAlert(200, null, null), true);
  });
  
  test('checkAlert returns false for normal values', () {
    final provider = HealthDataProvider();
    expect(provider.checkAlert(110, 120, 80), false);
  });
}
```

### Widget Tests

```dart
// test/screens/home_screen_test.dart
void main() {
  testWidgets('HomeScreen shows loading indicator', (tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Complete flow: add reading and view in list', (tester) async {
    // 1. Start app
    await tester.pumpWidget(MyApp());
    
    // 2. Tap add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 3. Fill form
    await tester.enterText(find.byType(TextField).first, '120');
    
    // 4. Save
    await tester.tap(find.text('Salvează Măsurătoarea'));
    await tester.pumpAndSettle();
    
    // 5. Verify in list
    expect(find.text('120'), findsOneWidget);
  });
}
```

## Checklist Final

### Funcționalități Core
- [ ] Aplicația pornește fără erori
- [ ] Datele se încarcă din Supabase
- [ ] Adăugare măsurători funcționează
- [ ] Validare formular funcționează
- [ ] Alertă valori anormale funcționează
- [ ] Grafice se afișează corect
- [ ] Adăugare medicamente funcționează
- [ ] Export PDF funcționează
- [ ] Previzualizare PDF funcționează

### UI/UX
- [ ] Interfață intuitivă
- [ ] Navigare clară
- [ ] Feedback vizual pentru acțiuni
- [ ] Mesaje de eroare clare
- [ ] Design consistent
- [ ] Responsive pe diferite ecrane

### Performanță
- [ ] Încărcare rapidă (<2s)
- [ ] Scroll smooth (60 FPS)
- [ ] Grafice se încarcă rapid
- [ ] PDF se generează rapid (<3s)
- [ ] Nu există memory leaks

### Securitate
- [ ] Validare input client-side
- [ ] Comunicare HTTPS
- [ ] RLS activat în Supabase
- [ ] Nu există chei hardcodate (pentru producție)

### Compatibilitate
- [ ] Funcționează pe Android 8+
- [ ] Funcționează pe diferite rezoluții
- [ ] Funcționează pe Linux desktop (pentru dev)

## Raportare Bugs

### Template Bug Report

```
**Titlu**: [Scurtă descriere]

**Severitate**: Critical / High / Medium / Low

**Pași de Reproducere**:
1. 
2. 
3. 

**Rezultat Așteptat**:


**Rezultat Actual**:


**Screenshots/Logs**:


**Mediu**:
- Device: 
- Android Version: 
- App Version: 
```

## Resurse

- Flutter DevTools: `flutter pub global activate devtools`
- Supabase Logs: Dashboard → Logs
- Android Logcat: `adb logcat`
