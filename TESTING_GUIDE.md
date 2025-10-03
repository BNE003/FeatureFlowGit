# FeatureFlow SDK - Testing Guide

## 🎯 Schritt 1: Datenbank Setup

### SQL Befehle in Supabase ausführen (in dieser Reihenfolge):

```sql
-- 1. Alte Tabellen löschen (falls vorhanden)
-- Führe aus: drop_all_tables.sql

-- 2. Schema erstellen
-- Führe aus: supabase_schema_simple.sql

-- 3. Test-Daten einfügen
-- Führe aus: test_data_simple.sql
```

## 🧪 Schritt 2: Test-App erstellen

### Option A: Xcode Preview testen (Schnelltest)

```bash
cd /Users/benediktheld/Documents/dev/FeatureFlow
open Package.swift
```

1. Warte bis Xcode das Package lädt
2. Öffne `Sources/FeatureFlow/FeatureFlowView.swift`
3. Drücke `⌘ + Option + Enter` für Preview
4. Du solltest die 5 Demo-Features sehen!

**Testfälle im Preview:**
- ✅ Features werden geladen und angezeigt
- ✅ Sortierung nach Votes/Datum funktioniert
- ✅ Suche funktioniert
- ✅ Auf ein Feature klicken → Detail-Ansicht
- ✅ Plus-Button → Neues Feature einreichen
- ✅ Upvote-Button testen (nur 1x möglich)
- ✅ Kommentar hinzufügen

---

### Option B: Standalone Test-App (Vollständiger Test)

Erstelle eine neue iOS App zum Testen:

```bash
cd /Users/benediktheld/Documents/dev
mkdir FeatureFlowTestApp
cd FeatureFlowTestApp
```

#### 1. Erstelle ein neues Xcode Projekt:

```bash
# Öffne Xcode und erstelle:
# File → New → Project → iOS → App
# - Name: FeatureFlowTestApp
# - Interface: SwiftUI
# - Language: Swift
# - Speichere in: /Users/benediktheld/Documents/dev/FeatureFlowTestApp
```

#### 2. FeatureFlow Package hinzufügen:

1. In Xcode: File → Add Package Dependencies
2. Paste: `/Users/benediktheld/Documents/dev/FeatureFlow`
3. Add Package

Oder manuell in `Package.swift`:
```swift
dependencies: [
    .package(path: "/Users/benediktheld/Documents/dev/FeatureFlow")
]
```

#### 3. Test-Code in ContentView.swift:

```swift
import SwiftUI
import FeatureFlow

struct ContentView: View {
    @State private var showFeatureFlow = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("FeatureFlow Test App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Teste das FeatureFlow SDK")
                    .foregroundColor(.secondary)

                Button(action: {
                    showFeatureFlow = true
                }) {
                    Label("Features & Feedback", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showFeatureFlow) {
                    FeatureFlowView(appId: "demo-app-001")
                }

                Divider()
                    .padding()

                // Alternative: Direkt in der Navigation
                NavigationLink(destination: FeatureFlowView(appId: "demo-app-001")) {
                    Label("Direct Navigation", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Test App")
        }
    }
}

#Preview {
    ContentView()
}
```

#### 4. App starten und testen:

1. Wähle ein iOS Simulator (z.B. iPhone 15 Pro)
2. Drücke `⌘ + R` zum Starten
3. Klicke auf "Features & Feedback"

## ✅ Test-Checkliste

### Feature-Liste:
- [ ] 5 Demo-Features werden angezeigt
- [ ] Sortierung nach "Votes" zeigt Widget Support (56) zuerst
- [ ] Sortierung nach "Datum" zeigt Offline-Modus (2 Tage) zuerst
- [ ] Suche nach "Dark" findet "Dark Mode"
- [ ] Status-Badges werden korrekt angezeigt (Offen, Geplant, etc.)

### Feature-Details:
- [ ] Klick auf Feature öffnet Detail-Ansicht
- [ ] Beschreibung wird angezeigt
- [ ] Kommentare werden angezeigt (Dark Mode hat 1, Push-Benachrichtigungen hat 2)
- [ ] Upvote-Button funktioniert (Vote-Count erhöht sich)
- [ ] Nach Upvote: Button wird disabled (blau gefärbt)
- [ ] Kommentar-Formular öffnet sich
- [ ] Neuer Kommentar wird hinzugefügt

### Feature einreichen:
- [ ] Plus-Button öffnet Formular
- [ ] Titel und Beschreibung können eingegeben werden
- [ ] Submit-Button ist disabled ohne Input
- [ ] Nach Submit: Success-Alert erscheint
- [ ] Neues Feature erscheint in der Liste

### Pull-to-Refresh:
- [ ] Liste nach unten ziehen lädt Daten neu
- [ ] Loading-Indicator wird angezeigt

## 🐛 Troubleshooting

### "Keine Features werden angezeigt"

**Check 1: Supabase Credentials**
```swift
// In Sources/FeatureFlow/Networking/SupabaseClient.swift
private let supabaseURL = "https://xxx.supabase.co" // Richtig?
private let supabaseAnonKey = "eyJxxx..." // Richtig?
private let useMockData = false // Muss false sein!
```

**Check 2: Supabase RLS Policies**
```sql
-- In Supabase SQL Editor:
SELECT * FROM features WHERE app_id = 'demo-app-001';
-- Sollte 5 Features zurückgeben
```

**Check 3: Network Permissions**
- iOS Simulator: Network sollte automatisch funktionieren
- Real Device: Info.plist benötigt keine Änderungen (HTTPS ist erlaubt)

### "Loading spinner dreht sich endlos"

**Check Console Output:**
```bash
# In Xcode Console schauen nach:
# - HTTP Errors (401, 403, 404)
# - JSON Decode Errors
```

**Manuell testen:**
```bash
# Terminal:
curl "https://ssaaaryvzpmfefvnfpxf.supabase.co/rest/v1/features?app_id=eq.demo-app-001" \
  -H "apikey: DEIN_ANON_KEY" \
  -H "Content-Type: application/json"
```

### "Vote funktioniert nicht"

**UserDefaults Reset (falls nötig):**
```swift
// Temporär in SupabaseClient.init() einfügen:
UserDefaults.standard.removeObject(forKey: "FeatureFlowVotedFeatures")
UserDefaults.standard.removeObject(forKey: "FeatureFlowDeviceId")
```

## 🎉 Erfolg!

Wenn alle Tests ✅ sind, funktioniert dein SDK perfekt!

**Nächste Schritte:**
1. SDK auf GitHub pushen
2. In deiner echten App einbinden
3. Verschiedene `app_id`s für verschiedene Apps verwenden
4. Optional: Admin-Dashboard in Next.js bauen
