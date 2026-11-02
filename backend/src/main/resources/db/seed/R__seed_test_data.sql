-- =============================================================================
-- Nakama — R__seed_test_data.sql
-- Jeu d'essai de la base de TEST / DEV. Ne jamais l'activer en production.
--
-- À placer dans src/main/resources/db/seed/ et à n'activer que dans les profils
-- dev et test :
--   spring.flyway.locations=classpath:db/migration,classpath:db/seed
-- Préfixe R__ = migration « repeatable » : Flyway la rejoue à chaque fois que le
-- fichier change. Le TRUNCATE du début la rend rejouable sans doublons.
--
-- Un jeu d'essai « complet » couvre chaque cas que l'appli doit savoir gérer :
--   - les 3 rôles (USER, MODERATOR, ADMIN) et un compte banni
--   - un profil public et un profil privé, un genre favori vide
--   - les 4 statuts de suivi du CDC, des scores de 1 à 10 et un score vide,
--     des favoris, des dates
--   - des œuvres à nombre d'épisodes/tomes inconnu (NULL) et à venir
--   - un anime sans aucun suivi, un user sans aucun suivi
-- Les 4 personas du dossier de conception (Lucas, Camille, Théo, Alex) sont repris.
--
-- Mot de passe de tous les comptes : Nakama2026!  (hash BCrypt, coût 12 comme dans securite.md)
-- =============================================================================

TRUNCATE users, genres, animes, mangas RESTART IDENTITY CASCADE;


-- -----------------------------------------------------------------------------
-- Utilisateurs
-- -----------------------------------------------------------------------------
INSERT INTO users (id, username, email, password_hash, role, is_banned) VALUES
    (1, 'alex',     'alex@nakama.test',     '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'ADMIN',     FALSE),
    (2, 'sam_modo', 'sam@nakama.test',      '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'MODERATOR', FALSE),
    (3, 'lucas',    'lucas@nakama.test',    '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'USER',      FALSE),
    (4, 'camille',  'camille@nakama.test',  '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'USER',      FALSE),
    (5, 'theo',     'theo@nakama.test',     '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'USER',      FALSE),
    (6, 'spam_bot', 'spam@nakama.test',     '$2a$12$leRZP0o9w5pbPrSx.pj1i.U29teP8IWZqMLDAhn3wPZYHUZDbjGMe', 'USER',      TRUE);


-- -----------------------------------------------------------------------------
-- Genres (créés par le modérateur)
-- -----------------------------------------------------------------------------
INSERT INTO genres (id, name, slug, created_by) VALUES
    (1,  'Action',          'action',          2),
    (2,  'Aventure',        'aventure',        2),
    (3,  'Comédie',         'comedie',         2),
    (4,  'Drame',           'drame',           2),
    (5,  'Fantasy',         'fantasy',         2),
    (6,  'Romance',         'romance',         2),
    (7,  'Science-fiction', 'science-fiction', 2),
    (8,  'Slice of Life',   'slice-of-life',   2),
    (9,  'Sport',           'sport',           2),
    (10, 'Horreur',         'horreur',         2),
    (11, 'Shōnen',          'shonen',          2),
    (12, 'Seinen',          'seinen',          2);


-- -----------------------------------------------------------------------------
-- Profils (1-1) : un par user, comme le fera l'inscription
-- -----------------------------------------------------------------------------
INSERT INTO user_profiles (user_id, avatar_url, bio, is_public, favorite_genre_id) VALUES
    (1, '/avatars/alex.png',    'Créateur de Nakama. Le catalogue doit être nickel.', TRUE,  5),
    (2, NULL,                   'Modérateur du catalogue.',                            TRUE,  NULL),
    (3, '/avatars/lucas.png',   'Je débute, j''oublie toujours où j''en suis.',        TRUE,  1),
    (4, '/avatars/camille.png', 'Plus de 200 tomes à la maison.',                      FALSE, 4),   -- profil privé
    (5, '/avatars/theo.png',    'Stats addict. Anime et manga.',                       TRUE,  12),
    (6, NULL,                   NULL,                                                  TRUE,  NULL);


-- -----------------------------------------------------------------------------
-- Animes
-- -----------------------------------------------------------------------------
INSERT INTO animes (id, title, original_title, synopsis, image_url, nb_episodes, status, release_year, studio, created_by) VALUES
    (1, 'Naruto',                'ナルト',             'Un jeune ninja rêve de devenir Hokage.',                    '/covers/naruto.jpg',   220,  'TERMINE', 2002, 'Pierrot',              2),
    (2, 'L''Attaque des Titans', '進撃の巨人',          'L''humanité survit derrière des murs face aux Titans.',    '/covers/snk.jpg',      87,   'TERMINE', 2013, 'Wit Studio / MAPPA',   2),
    (3, 'Frieren',               '葬送のフリーレン',     'Une elfe mage revisite le voyage de son ancien groupe.',   '/covers/frieren.jpg',  28,   'TERMINE', 2023, 'Madhouse',             2),
    (4, 'One Piece',             'ワンピース',          'Luffy part à la recherche du trésor de Gol D. Roger.',     '/covers/onepiece.jpg', NULL, 'EN_COURS',   1999, 'Toei Animation',       2),  -- nb inconnu
    (5, 'Spy x Family',          'スパイファミリー',     'Un espion, une tueuse et une télépathe jouent la famille.', '/covers/spyfam.jpg',   37,   'EN_COURS',   2022, 'Wit Studio / CloverWorks', 2),
    (6, 'Haikyū!!',              'ハイキュー!!',        'Un petit gabarit veut briller au volley.',                 '/covers/haikyu.jpg',   85,   'TERMINE', 2014, 'Production I.G',       2),
    (7, 'Your Name.',            '君の名は。',           'Deux lycéens échangent leurs corps en rêve.',              '/covers/yourname.jpg', 1,    'TERMINE', 2016, 'CoMix Wave Films',     1),
    (8, 'Chainsaw Man',          'チェンソーマン',       'Denji fusionne avec son chien-tronçonneuse.',              '/covers/csm.jpg',      12,   'TERMINE', 2022, 'MAPPA',                1),
    (9, 'Frieren – Saison 2',    '葬送のフリーレン 第2期', NULL,                                                    NULL,                   NULL, 'A_VENIR', 2026, 'Madhouse',             1);  -- à venir, aucun suivi

INSERT INTO anime_genres (anime_id, genre_id) VALUES
    (1, 1), (1, 2), (1, 11),
    (2, 1), (2, 4), (2, 5),
    (3, 2), (3, 4), (3, 5),
    (4, 1), (4, 2), (4, 3), (4, 11),
    (5, 1), (5, 3), (5, 8),
    (6, 3), (6, 9), (6, 11),
    (7, 4), (7, 6),
    (8, 1), (8, 10), (8, 11),
    (9, 2), (9, 5);


-- -----------------------------------------------------------------------------
-- Mangas
-- -----------------------------------------------------------------------------
INSERT INTO mangas (id, title, original_title, synopsis, image_url, nb_volumes, nb_chapters, author, publisher, local_publisher, status, release_year, created_by) VALUES
    (1, 'One Piece',           'ワンピース',     'Luffy et son équipage parcourent Grand Line.',      '/covers/op-manga.jpg',  NULL, NULL, 'Eiichirō Oda',      'Shūeisha',    'Glénat',   'EN_COURS',  1997, 2),
    (2, 'Berserk',             'ベルセルク',     'Guts, mercenaire maudit, affronte la Main de Dieu.', '/covers/berserk.jpg',   NULL, NULL, 'Kentarō Miura',     'Hakusensha',  'Glénat',   'EN_COURS',   1989, 2),
    (3, 'Fullmetal Alchemist', '鋼の錬金術師',   'Deux frères alchimistes cherchent la pierre philosophale.', '/covers/fma.jpg', 27,   108,  'Hiromu Arakawa',    'Square Enix', 'Kurokawa', 'TERMINE', 2001, 2),
    (4, 'Death Note',          'デスノート',     'Un lycéen trouve un carnet qui tue.',               '/covers/deathnote.jpg', 12,   108,  'Tsugumi Ōba',       'Shūeisha',    'Kana',     'TERMINE', 2003, 2),
    (5, 'Blue Period',         'ブルーピリオド', 'Un lycéen découvre la peinture.',                   '/covers/blueperiod.jpg', NULL, NULL, 'Tsubasa Yamaguchi', 'Kōdansha',    'Pika',     'EN_COURS',  2017, 2),
    (6, 'Chainsaw Man',        'チェンソーマン', 'Denji devient chasseur de démons.',                 '/covers/csm-manga.jpg', NULL, NULL, 'Tatsuki Fujimoto',  'Shūeisha',    'Kazé',     'EN_COURS',  2018, 1),
    (7, 'Naruto',              'ナルト',         'Le parcours de Naruto Uzumaki.',                    '/covers/naruto-manga.jpg', 72, 700,  'Masashi Kishimoto', 'Shūeisha',    'Kana',     'TERMINE', 1999, 1);

INSERT INTO manga_genres (manga_id, genre_id) VALUES
    (1, 1), (1, 2), (1, 3), (1, 11),
    (2, 1), (2, 4), (2, 5), (2, 10), (2, 12),
    (3, 1), (3, 2), (3, 5), (3, 11),
    (4, 4), (4, 10), (4, 11),
    (5, 4), (5, 8), (5, 12),
    (6, 1), (6, 10), (6, 11),
    (7, 1), (7, 2), (7, 11);


-- -----------------------------------------------------------------------------
-- Suivi anime : les 4 statuts sont couverts
-- -----------------------------------------------------------------------------
INSERT INTO anime_tracking (user_id, anime_id, status, current_episode, score, notes, is_favorite, started_date, ending_date) VALUES
    -- Lucas (casual, anime only)
    (3, 1, 'EN_COURS', 45,   7,    'Arc de l''examen chunin.',    FALSE, '2026-09-01', NULL),
    (3, 5, 'A_VOIR',     0,    NULL, NULL,                          FALSE, NULL,         NULL),
    (3, 7, 'TERMINE',   1,    10,    'Vu au ciné avec des potes.',  TRUE,  '2026-08-15', '2026-08-15'),
    (3, 8, 'ABANDONNE',     3,    4,    'Trop gore pour moi.',         FALSE, '2026-10-01', NULL),
    -- Théo (otaku)
    (5, 2, 'TERMINE',   87,   10,    NULL,                          TRUE,  '2023-01-10', '2023-11-05'),
    (5, 3, 'TERMINE',   28,   10,    'Chef-d''œuvre.',              TRUE,  '2023-09-29', '2024-03-22'),
    (5, 4, 'EN_COURS', 1050, 8,    NULL,                          FALSE, '2019-05-01', NULL),
    (5, 6, 'EN_COURS',     30,   7,    'Reprendre à la saison 2.',    FALSE, '2025-02-01', NULL),
    -- Alex (admin, utilise aussi l'appli)
    (1, 3, 'EN_COURS', 10,   NULL, NULL,                          FALSE, '2026-10-20', NULL);


-- -----------------------------------------------------------------------------
-- Suivi manga
-- -----------------------------------------------------------------------------
INSERT INTO manga_tracking (user_id, manga_id, status, current_volume, current_chapter, score, notes, is_favorite, started_date, ending_date) VALUES
    -- Camille (collectionneuse, profil privé)
    (4, 3, 'TERMINE',   27, 108, 10,    'Intégrale en édition Perfect.', TRUE,  '2024-01-05', '2024-06-30'),
    (4, 1, 'EN_COURS', 54, 530, 9,    NULL,                            FALSE, '2022-03-01', NULL),
    (4, 2, 'EN_COURS',     20, 180, 10,    'En attente des prochains tomes.', TRUE, '2023-04-12', NULL),
    (4, 5, 'EN_COURS', 10, 40,  NULL, NULL,                            FALSE, '2026-06-01', NULL),
    (4, 4, 'A_VOIR',     0,  0,   NULL, NULL,                            FALSE, NULL,         NULL),
    -- Théo
    (5, 6, 'EN_COURS', 15, 150, 8,    NULL,                            FALSE, '2024-02-01', NULL),
    (5, 7, 'TERMINE',   72, 700, 8,    NULL,                            FALSE, '2015-01-01', '2018-12-31'),
    (5, 4, 'ABANDONNE',     3,  20,  6,    'Pas accroché.',                 FALSE, '2025-05-01', NULL);


-- -----------------------------------------------------------------------------
-- Les id ont été forcés : on recale les séquences pour que le prochain
-- INSERT de l'appli ne tombe pas sur un id déjà pris.
-- -----------------------------------------------------------------------------
SELECT setval('users_id_seq',          (SELECT MAX(id) FROM users));
SELECT setval('genres_id_seq',         (SELECT MAX(id) FROM genres));
SELECT setval('animes_id_seq',         (SELECT MAX(id) FROM animes));
SELECT setval('mangas_id_seq',         (SELECT MAX(id) FROM mangas));
