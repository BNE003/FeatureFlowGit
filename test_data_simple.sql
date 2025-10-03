-- ============================================================================
-- FeatureFlow - Test-Daten
-- ============================================================================
-- Erstellt Demo-Features zum Testen des Swift SDK
-- ============================================================================

-- Alte Test-Daten löschen (falls vorhanden)
DELETE FROM comments WHERE feature_id IN (SELECT id FROM features WHERE app_id = 'demo-app-001');
DELETE FROM votes WHERE feature_id IN (SELECT id FROM features WHERE app_id = 'demo-app-001');
DELETE FROM features WHERE app_id = 'demo-app-001';

-- Demo-Features erstellen
INSERT INTO features (app_id, title, description, status, votes_count, created_at) VALUES
(
    'demo-app-001',
    'Dark Mode',
    'Bitte fügt einen Dark Mode hinzu, damit die App abends besser nutzbar ist.',
    'planned',
    42,
    (now() AT TIME ZONE 'UTC') - INTERVAL '5 days'
),
(
    'demo-app-001',
    'Export als PDF',
    'Es wäre toll, wenn man die Daten als PDF exportieren könnte.',
    'open',
    28,
    (now() AT TIME ZONE 'UTC') - INTERVAL '3 days'
),
(
    'demo-app-001',
    'Push-Benachrichtigungen',
    'Ich hätte gerne Push-Benachrichtigungen für neue Updates.',
    'in_progress',
    35,
    (now() AT TIME ZONE 'UTC') - INTERVAL '7 days'
),
(
    'demo-app-001',
    'Widget Support',
    'Ein Home-Screen Widget wäre super praktisch.',
    'completed',
    56,
    (now() AT TIME ZONE 'UTC') - INTERVAL '14 days'
),
(
    'demo-app-001',
    'Offline-Modus',
    'Die App sollte auch offline funktionieren und später synchronisieren.',
    'open',
    19,
    (now() AT TIME ZONE 'UTC') - INTERVAL '2 days'
);

-- Demo-Kommentare hinzufügen
INSERT INTO comments (feature_id, author_name, text, created_at)
SELECT
    id,
    'Anna',
    'Super Idee! Brauche ich auch.',
    (now() AT TIME ZONE 'UTC') - INTERVAL '3 days'
FROM features
WHERE app_id = 'demo-app-001' AND title = 'Dark Mode'
LIMIT 1;

INSERT INTO comments (feature_id, author_name, text, created_at)
SELECT
    id,
    'Max',
    'Ja bitte!',
    (now() AT TIME ZONE 'UTC') - INTERVAL '6 days'
FROM features
WHERE app_id = 'demo-app-001' AND title = 'Push-Benachrichtigungen'
LIMIT 1;

INSERT INTO comments (feature_id, author_name, text, created_at)
SELECT
    id,
    'Lisa',
    'Mit Einstellungen bitte, um sie auch ausschalten zu können.',
    (now() AT TIME ZONE 'UTC') - INTERVAL '5 days'
FROM features
WHERE app_id = 'demo-app-001' AND title = 'Push-Benachrichtigungen'
LIMIT 1;

-- ============================================================================
-- FERTIG! ✅
-- ============================================================================
--
-- Erstellt:
-- ✅ 5 Demo-Features für "demo-app-001"
-- ✅ 3 Demo-Kommentare
--
-- Nächster Schritt:
-- 1. In SupabaseClient.swift: useMockData = false setzen
-- 2. Xcode öffnen: open Package.swift
-- 3. Preview testen mit app_id: "demo-app-001"
