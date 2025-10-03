-- ============================================================================
-- VERIFIZIERUNG & FIX - Führe alle Befehle nacheinander aus
-- ============================================================================

-- SCHRITT 1: Prüfe ob Features existieren
SELECT 'Checking features...' as step;
SELECT COUNT(*) as total_features FROM features;
SELECT COUNT(*) as demo_features FROM features WHERE app_id = 'demo-app-001';

-- Falls 0 Features für demo-app-001:
-- SCHRITT 2: Lösche alte Test-Daten
DELETE FROM comments WHERE feature_id IN (SELECT id FROM features WHERE app_id = 'demo-app-001');
DELETE FROM votes WHERE feature_id IN (SELECT id FROM features WHERE app_id = 'demo-app-001');
DELETE FROM features WHERE app_id = 'demo-app-001';

-- SCHRITT 3: Füge frische Test-Daten ein
INSERT INTO features (app_id, title, description, status, votes_count, created_at) VALUES
('demo-app-001', 'Dark Mode', 'Bitte fügt einen Dark Mode hinzu, damit die App abends besser nutzbar ist.', 'planned', 42, (now() AT TIME ZONE 'UTC') - INTERVAL '5 days'),
('demo-app-001', 'Export als PDF', 'Es wäre toll, wenn man die Daten als PDF exportieren könnte.', 'open', 28, (now() AT TIME ZONE 'UTC') - INTERVAL '3 days'),
('demo-app-001', 'Push-Benachrichtigungen', 'Ich hätte gerne Push-Benachrichtigungen für neue Updates.', 'in_progress', 35, (now() AT TIME ZONE 'UTC') - INTERVAL '7 days'),
('demo-app-001', 'Widget Support', 'Ein Home-Screen Widget wäre super praktisch.', 'completed', 56, (now() AT TIME ZONE 'UTC') - INTERVAL '14 days'),
('demo-app-001', 'Offline-Modus', 'Die App sollte auch offline funktionieren und später synchronisieren.', 'open', 19, (now() AT TIME ZONE 'UTC') - INTERVAL '2 days');

-- SCHRITT 4: Prüfe RLS Policies
SELECT 'Checking RLS policies...' as step;
SELECT tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'features';

-- Falls keine Policies existieren, erstelle sie:
DROP POLICY IF EXISTS "Anyone can read features" ON features;
DROP POLICY IF EXISTS "Anyone can insert features" ON features;

CREATE POLICY "Anyone can read features" ON features FOR SELECT USING (true);
CREATE POLICY "Anyone can insert features" ON features FOR INSERT WITH CHECK (true);

-- SCHRITT 5: Verifizierung - sollte 5 Features zurückgeben
SELECT 'Final verification...' as step;
SELECT id, app_id, title, status, votes_count, created_at
FROM features
WHERE app_id = 'demo-app-001'
ORDER BY votes_count DESC;

-- ============================================================================
-- FERTIG!
-- ============================================================================
-- Wenn hier 5 Features angezeigt werden, ist die DB korrekt!
-- Dann liegt das Problem am SDK/Network.
