-- FeatureFlow Supabase Database Schema
-- Führe dieses SQL in deinem Supabase SQL Editor aus
--
-- HINWEIS: Deine bestehenden profiles, auth-Trigger und Funktionen bleiben unverändert!
-- Dieses Script fügt nur die FeatureFlow-spezifischen Tabellen hinzu.

-- ============================================================================
-- ADMIN TABLES (für deine Next.js SaaS-Verwaltung)
-- ============================================================================

-- Apps Tabelle: Verknüpft registrierte Apps mit deinen Usern
CREATE TABLE IF NOT EXISTS apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    app_id TEXT UNIQUE NOT NULL, -- Die ID die im SDK verwendet wird
    app_name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC')
);

-- Usage Metrics Tabelle: Tracking für Pricing-Tiers
CREATE TABLE IF NOT EXISTS usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id TEXT NOT NULL REFERENCES apps(app_id) ON DELETE CASCADE,
    month TEXT NOT NULL, -- Format: 'YYYY-MM'
    features_count INTEGER DEFAULT 0,
    votes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    UNIQUE(app_id, month)
);

-- ============================================================================
-- PUBLIC SDK TABLES (für das Swift SDK - öffentlicher Zugriff)
-- ============================================================================

-- Features Tabelle
CREATE TABLE IF NOT EXISTS features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'planned', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    votes_count INTEGER DEFAULT 0,
    CONSTRAINT votes_count_positive CHECK (votes_count >= 0)
);

-- Votes Tabelle
CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
    user_identifier TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    UNIQUE(feature_id, user_identifier)
);

-- Comments Tabelle
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
    author_name TEXT NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC')
);

-- ============================================================================
-- INDIZES für Performance
-- ============================================================================

-- Admin Tables
CREATE INDEX IF NOT EXISTS idx_apps_user_id ON apps(user_id);
CREATE INDEX IF NOT EXISTS idx_apps_app_id ON apps(app_id);
CREATE INDEX IF NOT EXISTS idx_usage_metrics_app_id ON usage_metrics(app_id);
CREATE INDEX IF NOT EXISTS idx_usage_metrics_month ON usage_metrics(month);

-- SDK Tables
CREATE INDEX IF NOT EXISTS idx_features_app_id ON features(app_id);
CREATE INDEX IF NOT EXISTS idx_features_status ON features(status);
CREATE INDEX IF NOT EXISTS idx_features_votes_count ON features(votes_count DESC);
CREATE INDEX IF NOT EXISTS idx_features_created_at ON features(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_votes_feature_id ON votes(feature_id);
CREATE INDEX IF NOT EXISTS idx_comments_feature_id ON comments(feature_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Admin Tables: Nur für eingeloggte User, nur eigene Daten
ALTER TABLE apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_metrics ENABLE ROW LEVEL SECURITY;

-- Apps: User sehen nur ihre eigenen Apps
CREATE POLICY "Users can view own apps" ON apps
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own apps" ON apps
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own apps" ON apps
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own apps" ON apps
    FOR DELETE USING (auth.uid() = user_id);

-- Usage Metrics: User sehen nur Metrics ihrer eigenen Apps
CREATE POLICY "Users can view own usage metrics" ON usage_metrics
    FOR SELECT USING (
        app_id IN (SELECT app_id FROM apps WHERE user_id = auth.uid())
    );

-- SDK Tables: Öffentlicher Zugriff für alle (anon key)
ALTER TABLE features ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Features: Jeder kann lesen und schreiben
CREATE POLICY "Anyone can read features" ON features
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert features" ON features
    FOR INSERT WITH CHECK (true);

-- Nur App-Owner oder Service Role kann Features updaten (Status ändern)
CREATE POLICY "App owners can update features" ON features
    FOR UPDATE USING (
        auth.role() = 'service_role' OR
        app_id IN (SELECT app_id FROM apps WHERE user_id = auth.uid())
    );

CREATE POLICY "App owners can delete features" ON features
    FOR DELETE USING (
        auth.role() = 'service_role' OR
        app_id IN (SELECT app_id FROM apps WHERE user_id = auth.uid())
    );

-- Votes: Jeder kann lesen und schreiben
CREATE POLICY "Anyone can read votes" ON votes
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert votes" ON votes
    FOR INSERT WITH CHECK (true);

-- Comments: Jeder kann lesen und schreiben
CREATE POLICY "Anyone can read comments" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert comments" ON comments
    FOR INSERT WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Update updated_at timestamp (falls noch nicht existiert)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = (now() AT TIME ZONE 'UTC');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger für apps.updated_at
CREATE TRIGGER update_apps_updated_at
    BEFORE UPDATE ON apps
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Function: Automatisches Vote-Count Update
CREATE OR REPLACE FUNCTION update_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE features SET votes_count = votes_count + 1 WHERE id = NEW.feature_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE features SET votes_count = votes_count - 1 WHERE id = OLD.feature_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER votes_count_trigger
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_votes_count();

-- Function: Automatisches Usage Tracking (optional, für später)
CREATE OR REPLACE FUNCTION track_feature_usage()
RETURNS TRIGGER AS $$
DECLARE
    current_month TEXT;
BEGIN
    current_month := TO_CHAR(now() AT TIME ZONE 'UTC', 'YYYY-MM');

    INSERT INTO usage_metrics (app_id, month, features_count)
    VALUES (NEW.app_id, current_month, 1)
    ON CONFLICT (app_id, month)
    DO UPDATE SET features_count = usage_metrics.features_count + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_feature_usage_trigger
    AFTER INSERT ON features
    FOR EACH ROW
    EXECUTE FUNCTION track_feature_usage();

-- ============================================================================
-- FERTIG!
-- ============================================================================
--
-- Nächste Schritte:
-- 1. Dieses SQL in Supabase SQL Editor ausführen
-- 2. In deiner Next.js App: Erstelle eine "Apps" Verwaltung wo User ihre app_id registrieren
-- 3. Im Swift SDK: Verwende die registrierte app_id
-- 4. Optional: Admin-Dashboard bauen wo du Features moderieren kannst
