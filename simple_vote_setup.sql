-- ============================================================================
-- SIMPLE VOTE SETUP - Ohne komplexe Trigger
-- ============================================================================

-- SCHRITT 1: Alles zurücksetzen
DELETE FROM votes;
DROP TRIGGER IF EXISTS votes_count_trigger ON votes;
DROP FUNCTION IF EXISTS update_votes_count() CASCADE;

-- SCHRITT 2: Test-Daten wiederherstellen
UPDATE features SET votes_count = 42 WHERE title = 'Dark Mode' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 28 WHERE title = 'Export als PDF' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 35 WHERE title = 'Push-Benachrichtigungen' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 56 WHERE title = 'Widget Support' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 19 WHERE title = 'Offline-Modus' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 0 WHERE title NOT IN ('Dark Mode', 'Export als PDF', 'Push-Benachrichtigungen', 'Widget Support', 'Offline-Modus') AND app_id = 'demo-app-001';

-- SCHRITT 3: RLS Policies für UPDATE erlauben (wichtig!)
DROP POLICY IF EXISTS "Anyone can update features" ON features;

CREATE POLICY "Anyone can update features" ON features
    FOR UPDATE USING (true)
    WITH CHECK (true);

-- SCHRITT 4: Prüfe alle Policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('features', 'votes')
ORDER BY tablename, policyname;

-- SCHRITT 5: Finaler Status
SELECT
    id,
    title,
    votes_count
FROM features
WHERE app_id = 'demo-app-001'
ORDER BY votes_count DESC;

-- ============================================================================
-- FERTIG!
-- ============================================================================
-- Jetzt kann das SDK direkt votes_count updaten.
-- Keine Trigger, einfache Logik!
