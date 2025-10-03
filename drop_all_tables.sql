-- ============================================================================
-- ACHTUNG: Löscht ALLE FeatureFlow Tabellen!
-- ============================================================================
-- Dieser Befehl löscht alle Feature-SDK Tabellen.
-- Deine profiles Tabelle bleibt ERHALTEN!
-- ============================================================================

-- Lösche Feature-SDK Tabellen in der richtigen Reihenfolge
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS features CASCADE;
DROP TABLE IF EXISTS usage_metrics CASCADE;
DROP TABLE IF EXISTS apps CASCADE;

-- Lösche die zugehörigen Trigger (falls vorhanden)
DROP TRIGGER IF EXISTS votes_count_trigger ON votes;
DROP TRIGGER IF EXISTS track_feature_usage_trigger ON features;
DROP TRIGGER IF EXISTS update_apps_updated_at ON apps;

-- Lösche die zugehörigen Functions (optional)
DROP FUNCTION IF EXISTS update_votes_count() CASCADE;
DROP FUNCTION IF EXISTS track_feature_usage() CASCADE;

-- ============================================================================
-- FERTIG! Alle Feature-SDK Tabellen wurden gelöscht.
-- ============================================================================
--
-- Was wurde gelöscht:
-- ❌ comments
-- ❌ votes
-- ❌ features
-- ❌ usage_metrics (falls vorhanden)
-- ❌ apps (falls vorhanden)
--
-- Was bleibt ERHALTEN:
-- ✅ profiles
-- ✅ auth.users
-- ✅ Alle anderen Tabellen
--
-- Nächster Schritt:
-- Führe supabase_schema_simple.sql aus, um alles neu zu erstellen!
