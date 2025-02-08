-- -- "Lab for SCD"
-- -- "droping table player and its dependencies"

-- drop table players

-- CREATE TABLE players (
--      player_name TEXT,
--      height TEXT,
--      college TEXT,
--      country TEXT,
--      draft_year TEXT,
--      draft_round TEXT,
--      draft_number TEXT,
--      season_stats season_stats[],
--      scoring_class scoring_class,
--      years_since_last_season INTEGER,
--     is_active BOOLEAN,
--      current_season INTEGER,
--      PRIMARY KEY (player_name, current_season)
--  );

-- select * from players

-- -- "script to load table"

INSERT INTO players
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(1996, 2022) AS season
), p AS (
    SELECT
        player_name,
        MIN(season) AS first_season
    FROM player_seasons
    GROUP BY player_name
), players_and_seasons AS (
    SELECT *
    FROM p
    JOIN years y
        ON p.first_season <= y.season
), windowed AS (
    SELECT
        ps.player_name,
        ps.season,
        ARRAY_REMOVE(
            ARRAY_AGG(
                CASE
                    WHEN p1.season IS NOT NULL
                        THEN ROW(
                            p1.season,
                            p1.gp,
                            p1.pts,
                            p1.reb,
                            p1.ast
                        )::season_stats
                END)
            OVER (PARTITION BY ps.player_name ORDER BY COALESCE(ps.season, ps.season)),
            NULL
        ) AS seasons
    FROM players_and_seasons ps
    LEFT JOIN player_seasons p1
        ON ps.player_name = p1.player_name
        AND ps.season = p1.season
    ORDER BY ps.player_name, ps.season
), static AS (
    SELECT
        player_name,
        MAX(height) AS height,
        MAX(college) AS college,
        MAX(country) AS country,
        MAX(draft_year) AS draft_year,
        MAX(draft_round) AS draft_round,
        MAX(draft_number) AS draft_number
    FROM player_seasons
    GROUP BY player_name
)
SELECT
    w.player_name,
    s.height,
    s.college,
    s.country,
    s.draft_year,
    s.draft_round,
    s.draft_number,
    seasons AS season_stats,
    CASE
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 20 THEN 'star'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 15 THEN 'good'
        WHEN (seasons[CARDINALITY(seasons)]::season_stats).pts > 10 THEN 'average'
        ELSE 'bad'
    END::scoring_class AS scoring_class,
    w.season - (seasons[CARDINALITY(seasons)]::season_stats).season as years_since_last_active,
    (seasons[CARDINALITY(seasons)]::season_stats).season = season AS is_active,
	w.season
FROM windowed w
JOIN static s
    ON w.player_name = s.player_name;
