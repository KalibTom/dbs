WITH udalosti_hraca AS (
	SELECT player1_id,
		period,
		pctimestring,
		event_msg_type,
		LAG(event_msg_type) OVER () AS prev_event,
		LAG(player1_id) OVER () AS prev_player
	FROM play_records
	WHERE CAST(game_id AS int) = {{game_id}} --22000529
	ORDER BY event_number
)
SELECT uh.player1_id AS player_id,
	p.first_name,
	p.last_name,
	uh.period,
	uh.pctimestring AS period_time
FROM udalosti_hraca uh
JOIN players p ON uh.player1_id = p.id
WHERE uh.event_msg_type = 'FIELD_GOAL_MADE' AND uh.prev_event = 'REBOUND' AND uh.player1_id = uh.prev_player
ORDER BY period ASC, pctimestring DESC, player1_id ASC;