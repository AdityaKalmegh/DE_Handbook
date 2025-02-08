# Day 1 - Cumulative Table Design
-- select * from player_seasons;

-- -- "Creating a struct object/data-type for storing season stats for a player"
-- create type season_stats as (
-- 	season INTEGER,
-- 	gp INTEGER,
-- 	pts REAL,
-- 	Reb REAL,
-- 	ast REAL
-- )

-- CREATE type scoring_class as ENUM ('star','good','average','bad');

-- -- "create a class to score a player's performance based on the pts? > scoring class""

-- -- DROP table players

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
-- --     is_active BOOLEAN,
--      current_season INTEGER,
--      PRIMARY KEY (player_name, current_season)
--  );

 -- select * from players
 -- select min(season) from player_seasons;

-- -- "Creating the seed query for loading data with first season"
INSERT INTO players
WITH yesterday AS (
	select * from players
	where current_season = 2001
),
	today as (
	select * from player_seasons
	where season = 2002
	)
 
 -- select * from today t full outer join yesterday y 
 -- 	on t.player_name = y.player_name
	 
 select 
 		COALESCE(t.player_name, y.player_name) as player_name,
        COALESCE(t.height, y.height) as height,
        COALESCE(t.college, y.college) as college,
        COALESCE(t.country, y.country) as country,
        COALESCE(t.draft_year, y.draft_year) as draft_year,
        COALESCE(t.draft_round, y.draft_round) as draft_round,
        COALESCE(t.draft_number, y.draft_number) as draft_number,
		CASE
		-- -- "when the season stats is null, then get the today's details"
			WHEN y.season_stats IS NULL 
				THEN ARRAY[ROW(
		                t.season,
		                t.gp,
						t.pts,
		                t.reb,
						t.ast
		                )::season_stats]
		   	WHEN t.season IS NOT NULL 
				THEN y.season_stats || ARRAY[ROW(
						t.season,
		                t.gp,
						t.pts,
		                t.reb,
						t.ast
		                )::season_stats]
			ELSE y.season_stats
		END as season_stats, 
		
		-- -- "adding scoring class"
		CASE
			WHEN t.season IS NOT NULL THEN 
				CASE 
					WHEN t.pts > 20 THEN 'star'
					WHEN t.pts > 15 THEN 'good'
					WHEN t.pts > 10 THEN 'average'
					ELSE 'bad'
				END::scoring_class
			ELSE y.scoring_class 
		END AS scoring_class,
		
		-- -- "adding logic for years since last season"
		CASE
            WHEN t.season IS NOT NULL THEN 0
			ELSE y.years_since_last_season + 1 
		 END as years_since_last_season,
		 
		COALESCE (t.season, y.current_season + 1) as current_season
		
 from today t full outer join yesterday y 
 	on t.player_name = y.player_name

-- -- " changing yesterday to 1996 and today to 1997, to add next year's data"

-- -- " Ideas is to create a cumulative table design with temporal component"

-- -- " Ability to unnest the season_stats so that you can go back to original schema"
WITH unnested as(
  SELECT player_name,
         UNNEST(season_stats) as season_stats
        FROM players
  WHERE current_season = 2001
  AND player_name = 'Michael Jordan')
  
select * from unnested

-- -- "analytical query to see biggest improvement"
select 
player_name,
(season_stats[1]::season_stats).pts as first_season,
(season_stats[CARDINALITY(season_stats)]::season_stats).pts as latest_season
--latest_season - first_season as difference
from players 
WHERE current_season = 2001

-- -- "finding ratio of improvement"
-- -- "there is no group by in this query , no aggregation > very FAST query  > this cumulative pattern build history incrementally"
-- -- ""

 SELECT player_name,
        (season_stats[cardinality(season_stats)]).pts/
         CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1 ELSE  (season_stats[1]::season_stats).pts 
		 END as ratio_most_recent_to_first
 FROM players
WHERE current_season = 2001
and scoring_class = 'star'
order by 2 desc
