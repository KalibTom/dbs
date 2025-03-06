WITH udalosti_hraca AS (
    SELECT *
    FROM players p
    JOIN play_records pr ON p.id IN (pr.player1_id, pr.player2_id) 
      AND pr.event_msg_type IN ('FIELD_GOAL_MADE', 'FIELD_GOAL_MISSED', 'FREE_THROW', 'REBOUND')
    JOIN games g ON g.id = pr.game_id 
      AND CAST(g.season_id AS int) = 22017
    JOIN teams t ON t.id = CASE
        WHEN p.id = pr.player1_id THEN pr.player1_team_id
        WHEN p.id = pr.player2_id THEN pr.player2_team_id
      END
),
zmeny_timov AS (
    SELECT 
        id,
        COUNT(DISTINCT team_id) AS num_teams
    FROM udalosti_hraca
    GROUP BY player_id
    HAVING COUNT(DISTINCT team_id) > 1
),
top_hraci AS (
    SELECT 
        uh.id,
        uh.first_name,
        uh.last_name,
        zt.num_teams - 1 AS team_changes
    FROM udalosti_hraca uh
    JOIN zmeny_timov zt ON uh.player_id = zt.player_id
    GROUP BY uh.player_id, uh.first_name, uh.last_name, uh.is_active, zt.num_teams
    ORDER BY zt.num_teams DESC, uh.last_name ASC, uh.first_name ASC
)
SELECT * FROM top_hraci