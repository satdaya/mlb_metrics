WITH at_bats AS (
  SELECT *
  FROM at_bats_2019
),
games AS (
  SELECT *
  FROM games_2019
),
players AS (
  SELECT *
  FROM player_names
),
cte_pas AS (
  SELECT
    *
   ,CASE WHEN _event ILIKE ('%pickoff%')
         THEN 0
         WHEN _event ILIKE ('%steal%')
         THEN 0
         WHEN _event ILIKE ('%stolen%')
         THEN 0
         WHEN _event ILIKE ('%advisory%')
         THEN 0
         WHEN _event = 'Batter Interference'
         THEN 0
         WHEN _event = 'Passed Ball'
         THEN 0
         WHEN _event = 'Wild Pitch'
         THEN 0
         ELSE 1
         END AS is_plate_appearance
   ,CASE WHEN _event IN ('Single', 'Double', 'Triple', 'Home Run', 'Grounded Into DP', 'Fielders Choice', 'Triple Play')
         THEN 1
         WHEN _event ILIKE ('%double play%')
         THEN 1
         WHEN _event ILIKE ('%bunt%')
         THEN 1
         WHEN _event ILIKE ('%out%')
         THEN 1
         ELSE 0 END
         AS is_at_bat
   ,CASE WHEN _event IN ('Single', 'Double', 'Triple', 'Home Run')
         THEN 1
         ELSE 0
         END AS ab_safe_or_out
   ,CASE WHEN is_plate_appearance = 1
         AND _event IN ('Single', 'Double', 'Triple', 'Home Run', 'Hit By Pitch', 'Catcher Interference', 'Fan Interference', 'Walk', 'Intent Walk')
         THEN 1
         ELSE 0
         END AS pa_safe_or_out
   ,CASE WHEN _event = 'Single'
         THEN 1
         WHEN _event = 'Double'
         THEN 2
         WHEN _event = 'Triple'
         THEN 3
         WHEN _event = 'Home Run'
         THEN 4
         ELSE 0
         END AS bases_for_slg
   ,CASE WHEN _event = 'Hit By Pitch'
         THEN 1
         ELSE 0 
         END AS hbp
   ,CASE WHEN _event = 'Walk'
         THEN 1
         ELSE 0
         END AS walk
   ,CASE WHEN _event = 'Intentional Walk'
         THEN 1
         ELSE 0
         END AS ibb
   ,CASE WHEN _event = 'Single'
         THEN 1
         ELSE 0
         END AS single
   ,CASE WHEN _event = 'Double'
         THEN 1
         ELSE 0
         END AS double
   ,CASE WHEN _event = 'Triple'
         THEN 1
         ELSE 0 
         END AS triple
   ,CASE WHEN _event = 'Home Run'
         THEN 1
         ELSE 0 
         END AS home_run
   ,CASE WHEN _event ILIKE ('%sac%')
         THEN 1
         ELSE 0 
         END AS sf
  FROM at_bats
),
cte_batting_slash_line AS (
  SELECT
     cte_pas.batter_id
    ,first_name
    ,last_name
    ,ROUND( SUM(cte_pas.ab_safe_or_out) / SUM(cte_pas.is_at_bat) , 3) AS batting_avg
    ,ROUND( SUM(cte_pas.pa_safe_or_out) / SUM(cte_pas.is_plate_appearance), 3) AS obp
    ,ROUND( SUM(cte_pas.bases_for_slg) / SUM(cte_pas.is_at_bat), 3) as slg_percentage
    ,obp + slg_percentage AS ops
    --wOBA (weighted on base average) uses a predetermined scale (varies by season) to weight significance of outcome.
    ,ROUND( ( (SUM(walk) * .690) + (SUM(hbp) * .719) + (SUM(hbp) * .719) + (SUM(single) * .870) + (SUM(double) * 1.217) + (SUM(triple) * 1.529)
      + (SUM(home_run) * 1.940) ) / (SUM(is_at_bat) + SUM(walk) - SUM(ibb) + SUM(sf) + SUM(hbp) ), 3 ) AS wOBA
  FROM cte_pas
  LEFT JOIN players
  ON cte_pas.batter_id = players.id
  GROUP BY 1,2,3
  HAVING SUM(is_plate_appearance) >= 502
  ORDER BY 7 DESC
  )

SELECT *
FROM cte_batting_slash_line
