# Swift SDK für Feature-Request SaaS

Ich möchte ein Swift Package (SDK) erstellen, das iOS-App-Entwicklern ermöglicht, mit einer Zeile Code eine vollständige Feature-Request/Feedback-UI in ihre App einzubinden.

## Projekt-Übersicht

**Ziel:** Ein Swift Package, das via Git eingebunden werden kann und eine fertige SwiftUI-View bereitstellt, in der Nutzer:
- Features/Ideen vorschlagen können
- Bestehende Features upvoten können
- Kommentare zu Features hinzufügen können

**Backend:** 
- Alle Daten werden in MEINER zentralen Supabase-Datenbank gespeichert
- Das SDK kommuniziert über die Supabase REST API
- Supabase URL und API-Key sind **hardcoded im SDK** (nur ich kenne sie)
- Jede App wird nur über eine simple `appId` (String) identifiziert
- Die App-Entwickler kennen nur ihre `appId`, nicht meine Supabase-Credentials

**Technologie-Stack:**
- Swift Package Manager
- SwiftUI für die UI
- Supabase REST API für Backend-Kommunikation
- URLSession für Networking (oder supabase-swift Client)

## Gewünschte Struktur

```
FeatureRequestSDK/
├── Package.swift
├── Sources/
│   └── FeatureFlow/
│       ├── FeatureRequestSDK.swift (Main entry point)
│       ├── Models/
│       │   ├── Feature.swift
│       │   ├── Vote.swift
│       │   └── Comment.swift
│       ├── Networking/
│       │   ├── SupabaseClient.swift
│       │   └── APIModels.swift
│       └── Views/
│           ├── FeatureRequestView.swift (Haupt-View mit Tabs)
│           ├── FeatureListView.swift
│           ├── FeatureDetailView.swift
│           └── SubmitFeatureView.swift
└── Tests/
    └── FeatureRequestSDKTests/

Optional: Demo-App zum Testen
```

## Anwendungsbeispiel für App-Entwickler

So soll das SDK später verwendet werden (super simpel):

```swift
import FeatureRequestSDK

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink("Feedback & Features") {
                FeatureRequestView(appId: "mein-app-id")
            }
        }
    }
}
```

**Das war's!** Nur eine App-ID, keine URLs, keine Supabase-Details. Alles andere ist im SDK hardcoded.

## Features der UI

1. **Feature-Liste View:**
   - Suchfunktion
   - Sortierung (nach Votes, nach Datum)
   - Upvote-Button für jedes Feature
   - Status-Badge (Offen, Geplant, In Arbeit, Fertig)
   - Kommentar-Counter

2. **Feature-Detail View:**
   - Vollständige Beschreibung
   - Alle Kommentare
   - Kommentar hinzufügen

3. **Feature einreichen View:**
   - Formular mit Titel und Beschreibung
   - Submit-Button

## Supabase Datenbank-Schema

Ich habe bereits eine Next.js-App mit Supabase. Die Tabellen sind:

```sql
-- features Tabelle
id (uuid, primary key)
app_id (text) -- zur Identifikation welche App das Feature eingereicht hat
title (text)
description (text)
status (text) -- 'open', 'planned', 'in_progress', 'completed'
created_at (timestamp)
votes_count (integer)

-- votes Tabelle
id (uuid, primary key)
feature_id (uuid, foreign key)
user_identifier (text) -- z.B. Device ID oder User ID
created_at (timestamp)

-- comments Tabelle
id (uuid, primary key)
feature_id (uuid, foreign key)
author_name (text)
text (text)
created_at (timestamp)
```

## Nächste Schritte

Bitte hilf mir:

1. Das Swift Package korrekt aufzusetzen mit Package.swift
2. SPÄTER: (Eine funktionierende Demo-App zu erstellen zum Testen)
3. Die erste View zu implementieren (mit Mock-Daten zunächst)
4. Den Supabase-Client für API-Calls aufzubauen (mit hardcoded Credentials)
5. Die Views mit echten Daten aus Supabase zu verbinden

**Wichtig:** 
- Ich bin auf macOS und habe Xcode installiert
- Das Package soll via Git verteilt werden
- Die UI soll modern und schön aussehen (iOS 16+ Design)
- Deutsch als Hauptsprache in der UI
- **So einfach wie möglich:** Nutzer gibt nur `appId` an, nichts weiter
- Meine Supabase-Credentials (URL + anon key) kommen später - vorerst mit Mock-Daten arbeiten

Beginne mit Schritt 1 und 2: Package.swift Setup und Demo-App zum Testen.
