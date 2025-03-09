WITH zapasy_teamu AS (
    SELECT th.team_id,
		CONCAT(th.city, ' ', th.nickname) AS team_name,
        COUNT(CASE WHEN g.home_team_id = th.team_id THEN 1 END) AS number_home_matches,
        COUNT(CASE WHEN g.away_team_id = th.team_id THEN 1 END) AS number_away_matches,
        COUNT(CASE WHEN g.home_team_id = th.team_id OR g.away_team_id = th.team_id THEN 1 END) AS total_games
    FROM games g
    JOIN team_history th 
        ON (g.home_team_id = th.team_id OR g.away_team_id = th.team_id)
        WHERE (EXTRACT(YEAR FROM g.game_date) = th.year_founded AND EXTRACT(MONTH FROM g.game_date) > 6) 
		    OR (EXTRACT(YEAR FROM g.game_date) = th.year_active_till AND EXTRACT(MONTH FROM g.game_date) < 7)
		    OR (EXTRACT(YEAR FROM g.game_date) > th.year_founded AND EXTRACT(YEAR FROM g.game_date) < th.year_active_till)
		    OR (th.year_active_till = 2019 AND EXTRACT(YEAR FROM g.game_date) > 2018)
    GROUP BY team_name, th.team_id 
),
statistika_teamu AS (
	SELECT zt.team_id AS team_id,
		zt.team_name,
		zt.number_away_matches,
		ROUND(100.0 * zt.number_away_matches / NULLIF(zt.total_games, 0), 2) AS percentage_away_matches,
		zt.number_home_matches,
		ROUND(100.0 * zt.number_home_matches / NULLIF(zt.total_games, 0), 2) AS percentage_home_matches,
		zt.total_games
	FROM zapasy_teamu zt
)
SELECT * FROM statistika_teamu
ORDER BY team_id ASC