-- ============================================================================
-- FIX: Vote-Count Trigger reparieren
-- ============================================================================

-- 1. Prüfe aktuellen Zustand
SELECT 'Checking current votes and counts...' as step;

SELECT
    f.id,
    f.title,
    f.votes_count as current_count,
    COUNT(v.id) as actual_votes
FROM features f
LEFT JOIN votes v ON v.feature_id = f.id
WHERE f.app_id = 'demo-app-001'
GROUP BY f.id, f.title, f.votes_count
ORDER BY f.title;

-- 2. Lösche alten Trigger und Function
DROP TRIGGER IF EXISTS votes_count_trigger ON votes;
DROP FUNCTION IF EXISTS update_votes_count() CASCADE;

-- 3. Erstelle neue, funktionierende Function
CREATE OR REPLACE FUNCTION update_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Bei neuem Vote: +1
        UPDATE features
        SET votes_count = votes_count + 1
        WHERE id = NEW.feature_id;

        RAISE NOTICE 'Vote added for feature_id: %, new count: %', NEW.feature_id, (SELECT votes_count FROM features WHERE id = NEW.feature_id);

    ELSIF TG_OP = 'DELETE' THEN
        -- Bei gelöschtem Vote: -1
        UPDATE features
        SET votes_count = GREATEST(votes_count - 1, 0)
        WHERE id = OLD.feature_id;

        RAISE NOTICE 'Vote removed for feature_id: %, new count: %', OLD.feature_id, (SELECT votes_count FROM features WHERE id = OLD.feature_id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Erstelle Trigger neu
CREATE TRIGGER votes_count_trigger
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_votes_count();

-- 5. Synchronisiere alle bestehenden Counts
SELECT 'Syncing existing vote counts...' as step;

UPDATE features f
SET votes_count = (
    SELECT COUNT(*)
    FROM votes v
    WHERE v.feature_id = f.id
)
WHERE f.app_id = 'demo-app-001';

-- 6. Verifizierung: Sollte jetzt korrekt sein
SELECT 'Final verification...' as step;

SELECT
    f.id,
    f.title,
    f.votes_count as synced_count,
    COUNT(v.id) as actual_votes,
    CASE
        WHEN f.votes_count = COUNT(v.id) THEN '✅ OK'
        ELSE '❌ MISMATCH'
    END as status
FROM features f
LEFT JOIN votes v ON v.feature_id = f.id
WHERE f.app_id = 'demo-app-001'
GROUP BY f.id, f.title, f.votes_count
ORDER BY f.title;

-- ============================================================================
-- FERTIG!
-- ============================================================================
-- Nach diesem Fix:
-- 1. Bestehende Votes sind synchronisiert
-- 2. Neue Votes werden automatisch gezählt
-- 3. Teste das Upvoting nochmal in der App!
