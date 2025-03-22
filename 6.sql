 WITH statistiky_zapasov AS ( 
	SELECT pr.game_id,
		pr.player1_id,
		pr.event_msg_type,
		g.season_id,
		g.game_date
	FROM play_records pr
	JOIN players p ON pr.player1_id = p.id
	JOIN games g ON pr.game_id = g.id
	WHERE p.first_name = {{first_name}} --'LeBron' 
		AND p.last_name = {{last_name}} --'James' 
		AND g.season_type = 'Regular Season'
		AND pr.event_msg_type IN ('FIELD_GOAL_MADE', 'FIELD_GOAL_MISSED')
),
zapasy_hraca AS (
	SELECT season_id, COUNT(DISTINCT game_id) AS total_games
	FROM statistiky_zapasov
	GROUP BY season_id
	HAVING COUNT(DISTINCT game_id) >= 50
),
strelby AS (
	SELECT sz.season_id,
		sz.game_id,
		sz.game_date,
		100.0 * SUM(CASE WHEN sz.event_msg_type = 'FIELD_GOAL_MADE' THEN 1 ELSE 0 END) / COUNT(sz.event_msg_type) AS fg_percentage
	FROM statistiky_zapasov sz
	JOIN zapasy_hraca zh ON sz.season_id = zh.season_id
	GROUP BY sz.season_id, sz.game_id, sz.game_date
),
strelby_vypocet AS (
	SELECT season_id,
		game_id,
		game_date,
		fg_percentage,
		LAG(fg_percentage) OVER (PARTITION BY season_id ORDER BY game_date) AS prev_fg_percentage,
		CASE 
			WHEN LAG(fg_percentage) OVER (PARTITION BY season_id ORDER BY game_date) IS NULL THEN 0 
			ELSE ABS(fg_percentage - LAG(fg_percentage) OVER (PARTITION BY season_id ORDER BY game_date))
		END AS shooting_change
	FROM strelby
),
stabilita AS (
	SELECT 
		season_id,
		ROUND(AVG(shooting_change), 2) AS stability
	FROM strelby_vypocet
	GROUP BY season_id
)
SELECT season_id, stability
FROM stabilita
ORDER BY stability ASC, season_id ASC;