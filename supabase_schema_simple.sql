-- ============================================================================
-- FeatureFlow - Einfaches Schema
-- ============================================================================
-- Dieses Script erstellt ALLE nötigen Tabellen für:
-- 1. User-Verwaltung (profiles) - für deine Next.js App
-- 2. Feature SDK (features, votes, comments) - für das Swift SDK
--
-- ACHTUNG: Lösche zuerst alte Tabellen falls vorhanden!
-- ============================================================================

-- ============================================================================
-- SCHRITT 1: ALTE TABELLEN LÖSCHEN (falls vorhanden)
-- ============================================================================

-- Lösche alte Tabellen in der richtigen Reihenfolge (wegen Foreign Keys)
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS features CASCADE;

-- ============================================================================
-- SCHRITT 2: USER PROFILES (Next.js - bereits vorhanden, aber hier komplett)
-- ============================================================================

-- Profiles Tabelle (falls noch nicht existiert)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    image TEXT,
    customer_id TEXT,
    price_id TEXT,
    has_access BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC')
);

-- Function für updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = (now() AT TIME ZONE 'UTC');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger für profiles.updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Function für automatisches Profile bei Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, image, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
        NEW.raw_user_meta_data->>'avatar_url',
        (now() AT TIME ZONE 'UTC'),
        (now() AT TIME ZONE 'UTC')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger für neuen User
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- SCHRITT 3: FEATURE SDK TABELLEN (Swift SDK - öffentlich)
-- ============================================================================

-- Features Tabelle
CREATE TABLE features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'planned', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    votes_count INTEGER DEFAULT 0
);

-- Votes Tabelle
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
    user_identifier TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC'),
    UNIQUE(feature_id, user_identifier)
);

-- Comments Tabelle
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
    author_name TEXT NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC')
);

-- ============================================================================
-- SCHRITT 4: INDIZES FÜR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_features_app_id ON features(app_id);
CREATE INDEX idx_features_votes_count ON features(votes_count DESC);
CREATE INDEX idx_features_created_at ON features(created_at DESC);
CREATE INDEX idx_votes_feature_id ON votes(feature_id);
CREATE INDEX idx_comments_feature_id ON comments(feature_id);

-- ============================================================================
-- SCHRITT 5: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- RLS für Feature-Tabellen aktivieren
ALTER TABLE features ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Policies: Jeder kann lesen
CREATE POLICY "Anyone can read features" ON features FOR SELECT USING (true);
CREATE POLICY "Anyone can read votes" ON votes FOR SELECT USING (true);
CREATE POLICY "Anyone can read comments" ON comments FOR SELECT USING (true);

-- Policies: Jeder kann schreiben
CREATE POLICY "Anyone can insert features" ON features FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can insert votes" ON votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can insert comments" ON comments FOR INSERT WITH CHECK (true);

-- ============================================================================
-- SCHRITT 6: AUTOMATISCHE VOTE-COUNT UPDATES
-- ============================================================================

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

DROP TRIGGER IF EXISTS votes_count_trigger ON votes;
CREATE TRIGGER votes_count_trigger
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_votes_count();

-- ============================================================================
-- FERTIG! ✅
-- ============================================================================
--
-- Was wurde erstellt:
-- ✅ profiles (für User-Verwaltung & Payments)
-- ✅ features, votes, comments (für Swift SDK)
-- ✅ Alle nötigen Trigger und Functions
-- ✅ RLS Policies für Sicherheit
-- ✅ Performance-Indizes
--
-- Nächster Schritt:
-- Führe test_data.sql aus um Demo-Features zu erstellen!
