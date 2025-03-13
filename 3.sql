WITH zapas AS (
	SELECT event_number,
		player1_id AS player_id,
		event_msg_type,
		CAST(REPLACE(score_margin, 'TIE', '0') AS INT) AS score_margin
	FROM play_records
	WHERE CAST(game_id AS int) = 21701185
	ORDER BY event_number
),
body_za_hod AS (
    SELECT *,
		CASE
			WHEN LAG(score_margin) OVER () IS NULL THEN score_margin
			ELSE score_margin - LAG(score_margin) OVER ()
	   END AS body
	FROM zapas
	WHERE event_msg_type IN ('FIELD_GOAL_MADE', 'FREE_THROW') AND score_margin IS NOT NULL
),
statistiky_uspesne AS (
    SELECT player_id,
		SUM(CASE
			WHEN body = 3 THEN 3
			WHEN body = 2 THEN 2
			WHEN body = 1 THEN 1
			ELSE 0
		END) AS points,
		SUM(CASE WHEN body = 3 THEN 1 ELSE 0 END) AS "3PM",
        SUM(CASE WHEN body = 2 THEN 1 ELSE 0 END) AS "2PM",
        SUM(CASE WHEN body = 1 THEN 1 ELSE 0 END) AS FTM
    FROM body_za_hod
    GROUP BY player_id
),
statistiky_neuspesne AS (
    SELECT player1_id AS player_id,
		SUM(CASE WHEN event_msg_type = 'FIELD_GOAL_MISSED' THEN 1 ELSE 0 END) AS missed_shots,
		SUM(CASE WHEN event_msg_type = 'FREE_THROW' AND score_margin IS NOT NULL THEN 1 ELSE 0 END) AS missed_free_throws
    FROM play_records
    WHERE CAST(game_id AS int) = 21701185
        AND (event_msg_type = 'FIELD_GOAL_MISSED'
		OR (event_msg_type = 'FREE_THROW' AND score_margin IS NULL))
    GROUP BY player1_id
),
statistiky_hracov AS (
	SELECT 
	    COALESCE(su.player_id, sn.player_id) AS player_id,
	    p.first_name,
	    p.last_name,
	    COALESCE(su.points, 0) AS points,
	    COALESCE(su."2PM", 0) AS "2PM",
	    COALESCE(su."3PM", 0) AS "3PM",
	    COALESCE(sn.missed_shots, 0) AS missed_shots,
		COALESCE(
	        ROUND(100.0 * (su."2PM" + su."3PM") / NULLIF(su."2PM" + su."3PM" + sn.missed_shots, 0), 2),
	    0) AS shooting_percentage,
		COALESCE(su.FTM, 0) AS FTM,
	    sn.missed_free_throws,
		COALESCE( 100.0 * (su.FTM) / NULLIF(su.FTM + sn.missed_free_throws, 0), 0) AS FT_percentage
	FROM statistiky_uspesne su
	FULL JOIN statistiky_neuspesne sn ON su.player_id = sn.player_id
	JOIN players p ON p.id = COALESCE(su.player_id, sn.player_id)
)
SELECT * FROM statistiky_hracov
ORDER BY points DESC, shooting_percentage DESC, FT_percentage DESC, player_id ASC;