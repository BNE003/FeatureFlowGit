-- ============================================================================
-- Daten-Check: Prüfe ob Features vorhanden sind
-- ============================================================================

-- 1. Prüfe Features
SELECT
    app_id,
    title,
    status,
    votes_count,
    created_at
FROM features
WHERE app_id = 'demo-app-001'
ORDER BY votes_count DESC;

-- 2. Anzahl Features pro app_id
SELECT
    app_id,
    COUNT(*) as feature_count
FROM features
GROUP BY app_id;

-- 3. Prüfe Kommentare
SELECT
    c.author_name,
    c.text,
    f.title as feature_title
FROM comments c
JOIN features f ON c.feature_id = f.id
WHERE f.app_id = 'demo-app-001';

-- 4. Prüfe Votes
SELECT
    COUNT(*) as total_votes
FROM votes;

-- ============================================================================
-- Falls KEINE Features angezeigt werden:
-- Führe test_data_simple.sql nochmal aus!
-- ============================================================================
