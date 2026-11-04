-- =============================================================================
-- Nakama — V2__create_triggers.sql
-- Fonctions PL/pgSQL et déclencheurs (triggers).
--
-- Pourquoi des triggers ? Deux règles ne peuvent pas être garanties par un
-- simple CHECK :
--   1. updated_at doit changer à CHAQUE modification, même faite hors de
--      l'application (console SQL, script d'admin).
--   2. La progression ne doit pas dépasser la taille de l'œuvre
--      (current_episode <= animes.nb_episodes) : un CHECK ne lit qu'une ligne
--      d'une seule table, cette règle compare deux tables.
-- La base reste ainsi la dernière ligne de défense, même si le contrôle Java
-- est oublié ou contourné (style défensif demandé par le référentiel).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. updated_at automatique
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at          BEFORE UPDATE ON users          FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_user_profiles_updated_at  BEFORE UPDATE ON user_profiles  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_genres_updated_at         BEFORE UPDATE ON genres         FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_animes_updated_at         BEFORE UPDATE ON animes         FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_mangas_updated_at         BEFORE UPDATE ON mangas         FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_anime_tracking_updated_at BEFORE UPDATE ON anime_tracking FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_manga_tracking_updated_at BEFORE UPDATE ON manga_tracking FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- -----------------------------------------------------------------------------
-- 2. Progression anime : current_episode <= nb_episodes
--    nb_episodes NULL (anime en cours de diffusion) = pas de limite connue.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_anime_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_max INTEGER;
BEGIN
    SELECT nb_episodes INTO v_max FROM animes WHERE id = NEW.anime_id;

    IF v_max IS NOT NULL AND NEW.current_episode > v_max THEN
        RAISE EXCEPTION 'current_episode (%) dépasse nb_episodes (%) pour l''anime %',
            NEW.current_episode, v_max, NEW.anime_id
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_anime_tracking_progress
    BEFORE INSERT OR UPDATE OF current_episode, anime_id ON anime_tracking
    FOR EACH ROW EXECUTE FUNCTION fn_check_anime_progress();


-- -----------------------------------------------------------------------------
-- 3. Progression manga : current_volume <= nb_volumes et
--    current_chapter <= nb_chapters
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_manga_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_volumes  INTEGER;
    v_chapters INTEGER;
BEGIN
    SELECT nb_volumes, nb_chapters INTO v_volumes, v_chapters
    FROM mangas WHERE id = NEW.manga_id;

    IF v_volumes IS NOT NULL AND NEW.current_volume > v_volumes THEN
        RAISE EXCEPTION 'current_volume (%) dépasse nb_volumes (%) pour le manga %',
            NEW.current_volume, v_volumes, NEW.manga_id
            USING ERRCODE = 'check_violation';
    END IF;

    IF v_chapters IS NOT NULL AND NEW.current_chapter > v_chapters THEN
        RAISE EXCEPTION 'current_chapter (%) dépasse nb_chapters (%) pour le manga %',
            NEW.current_chapter, v_chapters, NEW.manga_id
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_manga_tracking_progress
    BEFORE INSERT OR UPDATE OF current_volume, current_chapter, manga_id ON manga_tracking
    FOR EACH ROW EXECUTE FUNCTION fn_check_manga_progress();


-- -----------------------------------------------------------------------------
-- 4. created_by ne peut jamais être modifié (règle du CDC)
--    Seule exception : passer à NULL, ce que fait ON DELETE SET NULL quand le
--    créateur supprime son compte (droit à l'oubli).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_protect_created_by()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.created_by IS DISTINCT FROM OLD.created_by AND NEW.created_by IS NOT NULL THEN
        RAISE EXCEPTION 'created_by ne peut pas être modifié (table %, id %)', TG_TABLE_NAME, OLD.id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_animes_protect_created_by BEFORE UPDATE OF created_by ON animes FOR EACH ROW EXECUTE FUNCTION fn_protect_created_by();
CREATE TRIGGER trg_mangas_protect_created_by BEFORE UPDATE OF created_by ON mangas FOR EACH ROW EXECUTE FUNCTION fn_protect_created_by();
CREATE TRIGGER trg_genres_protect_created_by BEFORE UPDATE OF created_by ON genres FOR EACH ROW EXECUTE FUNCTION fn_protect_created_by();
