WITH ordered_events AS (
    SELECT 
        pr1.player1_id,
        pr1.period,
        pr1.wctimestring AS pctimestring,
        pr1.event_msg_type,
        pr1.event_number
    FROM 
        play_records pr1
    WHERE 
        pr1.game_id = 22000529
    ORDER BY 
        pr1.event_number
),
event_pairs AS (
    SELECT 
        curr.player1_id,
        curr.period,
        curr.pctimestring,
        curr.event_msg_type AS current_event,
        prev.event_msg_type AS previous_event,
        prev.player1_id AS previous_player
    FROM 
        ordered_events curr
    LEFT JOIN 
        ordered_events prev ON curr.event_number = prev.event_number + 1
    WHERE 
        curr.event_msg_type = 'FIELD_GOAL_MADE'
        AND prev.event_msg_type = 'REBOUND'
        AND curr.player1_id = prev.player1_id
)
SELECT 
    ep.player1_id AS player_id,
    p.first_name,
    p.last_name,
    ep.period,
    ep.pctimestring AS period_time
FROM 
    event_pairs ep
JOIN 
    players p ON ep.player1_id = p.id
ORDER BY 
    ep.period ASC,
    ep.pctimestring DESC,
    ep.player1_id ASC;