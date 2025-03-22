WITH udalosti_hraca AS (
    SELECT p.id AS player_id, p.first_name, p.last_name, p.is_active,
		t.id AS team_id, t.full_name,
        pr.game_id, pr.event_msg_type, pr.score,
        pr.player1_id, pr.player2_id, pr.player1_team_id, pr.player2_team_id
    FROM players p
    JOIN play_records pr ON p.id IN (pr.player1_id,  pr.player2_id) AND pr.event_msg_type IN ('FIELD_GOAL_MADE', 'FIELD_GOAL_MISSED', 'FREE_THROW', 'REBOUND')
    JOIN games g ON g.id = pr.game_id AND CAST(g.season_id AS int) = {{season_id}} --22017
    JOIN teams t ON t.id = CASE
		WHEN p.id = pr.player1_id THEN pr.player1_team_id
		WHEN p.id = pr.player2_id THEN pr.player2_team_id
	END
),
top_hraci AS (
    SELECT uh.player_id,
		uh.first_name,
        uh.last_name,
		uh.is_active,
        COUNT(DISTINCT team_id) AS team_count
    FROM udalosti_hraca uh
    GROUP BY uh.player_id, uh.first_name, uh.last_name, uh.is_active
    ORDER BY team_count DESC
    LIMIT 5
),
pocet_hier AS (
    SELECT 
        player_id, 
        team_id, 
        COUNT(DISTINCT game_id) AS total_games
    FROM udalosti_hraca
    WHERE player_id IN (SELECT player_id FROM top_hraci)
    GROUP BY player_id, team_id
),
statistika_hraca AS (
    SELECT uh.player_id,
        uh.first_name,
        uh.last_name,
        uh.team_id,
        uh.full_name,
        SUM(CASE
				WHEN uh.event_msg_type = 'FIELD_GOAL_MADE' AND uh.player_id = uh.player1_id THEN 2
				WHEN uh.event_msg_type = 'FREE_THROW' AND uh.score IS NOT NULL THEN 1
			END) AS total_points,
        SUM(CASE WHEN uh.event_msg_type = 'FIELD_GOAL_MADE' AND uh.player_id = uh.player2_id THEN 1 END) AS total_assists
    FROM udalosti_hraca uh
    JOIN top_hraci th ON uh.player_id = th.player_id
    GROUP BY uh.player_id, uh.first_name, uh.last_name, uh.team_id, uh.full_name
)
SELECT sh.player_id,
	sh.first_name,
	sh.last_name,
	sh.team_id,
	sh.full_name,
	ROUND(SUM(sh.total_points) * 1.0 / NULLIF(SUM(ph.total_games), 0), 2) AS "PPG",
	ROUND(SUM(sh.total_assists) * 1.0 / NULLIF(SUM(ph.total_games), 0), 2) AS "APG",
	SUM(ph.total_games) AS total_games
FROM statistika_hraca sh
JOIN pocet_hier ph ON sh.player_id = ph.player_id AND sh.team_id = ph.team_id
GROUP BY sh.player_id, sh.first_name, sh.last_name, sh.team_id, sh.full_name
ORDER BY player_id ASC, team_id ASC;