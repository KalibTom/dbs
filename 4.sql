WITH statistiky_hraca AS (
	SELECT g.id game_id,
		g.game_date,
		p.id player_id,
		p.full_name player_full_name,
	SUM(CASE
			WHEN event_msg_type = 'FIELD_GOAL_MADE' AND p.id = pr.player1_id THEN 2 ELSE 0 END)
			+ SUM(CASE WHEN event_msg_type = 'FREE_THROW' AND (pr.score IS NOT NULL) AND p.id = pr.player1_id THEN 1 ELSE 0
		END) AS body,
	SUM(CASE
			WHEN event_msg_type = 'FIELD_GOAL_MADE' AND p.id = pr.player2_id THEN 1 ELSE 0
		END) AS asistencie,
	SUM(CASE
			WHEN event_msg_type = 'REBOUND' AND p.id = pr.player1_id THEN 1 ELSE 0
		END) AS doskoky
	FROM players p
	JOIN play_records pr ON (p.id = pr.player1_id OR p.id = pr.player2_id)
	JOIN games g ON pr.game_id = g.id
	WHERE CAST(g.season_id AS int) = {{season_id}} --22018
	GROUP BY g.id, p.id, p.full_name
	ORDER BY game_date
),
triple_double AS (
    SELECT *,
        CASE 
            WHEN body >= 10 AND asistencie >= 10 AND doskoky >= 10 THEN 1 
            ELSE 0 
        END AS triple_double
    FROM statistiky_hraca
),
streak_groups AS (
    SELECT *,
        SUM(CASE WHEN triple_double = 0 THEN 1 ELSE 0 END) 
            OVER (PARTITION BY player_id ORDER BY game_date) AS group_id
    FROM triple_double
),
streaks AS (
    SELECT 
        player_id,
        game_id,
        game_date,
        triple_double,
        group_id,
        COUNT(*) OVER (PARTITION BY player_id, group_id ORDER BY game_date) AS streak_counter
    FROM streak_groups
    WHERE triple_double = 1
)
SELECT 
    player_id, 
    MAX(streak_counter) AS longest_streak
FROM streaks
GROUP BY player_id
ORDER BY longest_streak DESC, player_id ASC;