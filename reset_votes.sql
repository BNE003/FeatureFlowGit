-- ============================================================================
-- RESET: Votes komplett zurücksetzen und neu aufbauen
-- ============================================================================

-- SCHRITT 1: Alle Votes löschen
DELETE FROM votes;

-- SCHRITT 2: Alle vote_counts auf die Original-Werte zurücksetzen
UPDATE features SET votes_count = 42 WHERE title = 'Dark Mode' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 28 WHERE title = 'Export als PDF' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 35 WHERE title = 'Push-Benachrichtigungen' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 56 WHERE title = 'Widget Support' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 19 WHERE title = 'Offline-Modus' AND app_id = 'demo-app-001';
UPDATE features SET votes_count = 0 WHERE title NOT IN ('Dark Mode', 'Export als PDF', 'Push-Benachrichtigungen', 'Widget Support', 'Offline-Modus') AND app_id = 'demo-app-001';

-- SCHRITT 3: Trigger komplett neu erstellen
DROP TRIGGER IF EXISTS votes_count_trigger ON votes;
DROP FUNCTION IF EXISTS update_votes_count() CASCADE;

CREATE OR REPLACE FUNCTION update_votes_count()
RETURNS TRIGGER AS $$
DECLARE
    new_count INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Erhöhe vote_count um 1
        UPDATE features
        SET votes_count = votes_count + 1
        WHERE id = NEW.feature_id
        RETURNING votes_count INTO new_count;

        RAISE NOTICE 'INSERT: Feature % now has % votes', NEW.feature_id, new_count;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Verringere vote_count um 1 (minimum 0)
        UPDATE features
        SET votes_count = GREATEST(votes_count - 1, 0)
        WHERE id = OLD.feature_id
        RETURNING votes_count INTO new_count;

        RAISE NOTICE 'DELETE: Feature % now has % votes', OLD.feature_id, new_count;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger erstellen
CREATE TRIGGER votes_count_trigger
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_votes_count();

-- SCHRITT 4: Prüfe RLS Policies für votes
SELECT 'Checking votes policies...' as step;

-- Lösche alte Policies
DROP POLICY IF EXISTS "Anyone can read votes" ON votes;
DROP POLICY IF EXISTS "Anyone can insert votes" ON votes;

-- Erstelle neue Policies
CREATE POLICY "Anyone can read votes" ON votes
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert votes" ON votes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can delete votes" ON votes
    FOR DELETE USING (true);

-- SCHRITT 5: Teste den Trigger manuell
SELECT 'Testing trigger...' as step;

-- Test: Füge einen Test-Vote ein
DO $$
DECLARE
    test_feature_id UUID;
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    -- Finde ein Feature
    SELECT id INTO test_feature_id FROM features WHERE app_id = 'demo-app-001' LIMIT 1;

    -- Hole alten Count
    SELECT votes_count INTO old_count FROM features WHERE id = test_feature_id;
    RAISE NOTICE 'Before: votes_count = %', old_count;

    -- Füge Test-Vote ein
    INSERT INTO votes (feature_id, user_identifier) VALUES (test_feature_id, 'test-user-123');

    -- Hole neuen Count
    SELECT votes_count INTO new_count FROM features WHERE id = test_feature_id;
    RAISE NOTICE 'After: votes_count = %', new_count;

    -- Prüfe ob es funktioniert hat
    IF new_count = old_count + 1 THEN
        RAISE NOTICE '✅ Trigger works!';
    ELSE
        RAISE NOTICE '❌ Trigger failed! Expected %, got %', old_count + 1, new_count;
    END IF;

    -- Lösche Test-Vote wieder
    DELETE FROM votes WHERE user_identifier = 'test-user-123';
END $$;

-- SCHRITT 6: Zeige finalen Status
SELECT 'Final status:' as step;

SELECT
    f.title,
    f.votes_count,
    COUNT(v.id) as actual_votes_in_db
FROM features f
LEFT JOIN votes v ON v.feature_id = f.id
WHERE f.app_id = 'demo-app-001'
GROUP BY f.id, f.title, f.votes_count
ORDER BY f.votes_count DESC;

-- ============================================================================
-- FERTIG!
-- ============================================================================
-- Der Trigger sollte jetzt funktionieren.
-- Teste in der App ein Upvote!
