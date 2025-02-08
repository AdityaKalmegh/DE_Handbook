-- -- "this is how you create a SCD table based on daily/weekly/monthly data to track changes"

-- create table players_scd(
-- 	player_name text,
-- 	scoring_class scoring_class,
-- 	is_active boolean,
-- 	start_season integer,
-- 	end_season integer,
-- 	current_season INTEGER,
-- 	PRIMARY KEY (player_name, start_season)
-- 	);

	
INSERT INTO players_scd
WITH with_previous as (
					SELECT
					     player_name,
						 current_season,
					     scoring_class,
						 is_active,
					     LAG(scoring_class,1) OVER (PARTITION BY player_name ORDER BY current_season) as previous_scoring_class,
						 LAG(is_active,1) OVER (PARTITION BY player_name ORDER BY current_season) as previous_is_active
					FROM players
					where current_season <= 2021
						),
-- -- "pay attention to the 'comma' above , highlighting continuity of CTE"
-- -- "since WITH keyword was used previously, no need to use again to define another CTE"

with_indicators as (
				select 
					*, 
					CASE 
						WHEN scoring_class <> previous_scoring_class THEN 1 
						WHEN is_active <> previous_is_active THEN 1 
						ELSE 0 
					END as change_indicator
				from with_previous 
					),

with_streaks as (
				select 
					*,
					SUM(change_indicator) 
						OVER (PARTITION BY player_name ORDER BY current_season) as streak_inditifier
				from with_indicators
				)

-- -- "query to check how the player performance is chaging over time"

	select 
		player_name,
		scoring_class,
		--streak_inditifier,
		is_active,
		MIN(current_season) as start_season,
		MAX(current_season) as end_season,
		2021 as current_season
	from with_streaks
	GROUP by player_name, streak_inditifier, is_active, scoring_class
	ORDER BY player_name, streak_inditifier


	select * from players_scd
