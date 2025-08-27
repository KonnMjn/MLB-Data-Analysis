-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
-- 2. In each decade, how many schools were there that produced players?
-- 3. What are the names of the top 5 schools that produced the most players?
-- 4. For each decade, what were the names of the top 3 schools that produced the most players?

-- 1. 
SELECT	* 
FROM 	schools;

SELECT	*
FROM 	school_details;

-- 2.
WITH RECURSIVE s_pro(yearID) AS 
	 (SELECT 1860
	  UNION ALL 
	  SELECT yearID + 1 
	  FROM s_pro
	  WHERE yearID < 2019)

SELECT	 ROUND(FLOOR(sp.yearID / 10) / 10, 1) AS round_decade, 
		 COUNT(DISTINCT s.schoolID) AS total_schools
FROM	 s_pro sp LEFT JOIN schools s
		 ON sp.yearID = s.yearID
GROUP BY round_decade; -- my way, still correct, but not optimize, too long

SELECT 	FLOOR(yearID / 10) * 10 AS decade, COUNT(DISTINCT schoolID) AS num_schools
FROM	schools
GROUP BY decade
ORDER BY decade;

-- 3.
SELECT	 sd.name_full, COUNT(DISTINCT s.playerID) AS total_players_produced
FROM 	 schools s LEFT JOIN school_details sd
		 ON s.schoolID = sd.schoolID
GROUP BY sd.name_full
ORDER BY total_players_produced DESC 
LIMIT 5;

-- 4. 
WITH RECURSIVE s_pro(yearID) AS 
	 (SELECT 1860
	  UNION ALL 
	  SELECT yearID + 1 
	  FROM s_pro
	  WHERE yearID < 2019),
      
      top_schools AS (SELECT	 ROUND(FLOOR(sp.yearID / 10) / 10, 1) AS round_decade,
								 sd.name_full,
								 COUNT(DISTINCT s.playerID) AS total_players_produced,
								 ROW_NUMBER() OVER (PARTITION BY ROUND(FLOOR(sp.yearID / 10) / 10, 1) ORDER BY COUNT(s.playerID) DESC) AS school_rank
					  FROM	 	 schools s LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
										   RIGHT JOIN s_pro sp ON sp.yearID = s.yearID
					  GROUP BY 	 round_decade, sd.name_full)

SELECT	* 
FROM 	top_schools
WHERE 	school_rank < 4 AND name_full IS NOT NULL;  -- my way, still correct, but not optimize, too long

WITH ds AS (SELECT	 FLOOR(s.yearID / 10) * 10 AS decade, sd.name_full, COUNT(DISTINCT s.playerID) AS num_players
			FROM	 schools s LEFT JOIN school_details sd
					 ON s.schoolID = sd.schoolID
			GROUP BY decade, s.schoolID),
            
	 rn AS (SELECT	decade, name_full, num_players,
					ROW_NUMBER() OVER (PARTITION BY decade ORDER BY num_players DESC) AS row_num
                    /* ALTERNATIVE SOLUTION UPDATE: ROW_NUMBER will return exactly 3 schools for each decade. To account for ties,
                       use DENSE_RANK instead to return the top 3 player counts, which could potentially include more than 3 schools */
			FROM	ds)
            
SELECT	decade, name_full, num_players
FROM	rn
WHERE	row_num <= 3
ORDER BY decade DESC, row_num;
      

-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
-- 2. Return the top 20% of teams in terms of average annual spending
-- 3. For each team, show the cumulative sum of spending over the years
-- 4. Return the first year that each team's cumulative spending surpassed 1 billion

-- 1.
SELECT	*
FROM	salaries;

-- 2.
WITH ans AS (SELECT	  yearID, teamID,
					  SUM(salary) AS annual_spend
			 FROM	  salaries
			 GROUP BY yearID, teamID),
	 avgs AS (SELECT   teamID, 
					   ROUND(AVG(annual_spend), 2) AS avg_annual_spend
			  FROM 	   ans
              GROUP BY teamID),
	 ranked AS (SELECT	 *,
						 ROW_NUMBER() OVER (ORDER BY avg_annual_spend DESC) AS team_rank
				FROM 	 avgs),
	 counted AS (SELECT	 *,
						 (SELECT COUNT(*) FROM ranked) AS total_teams
				 FROM    ranked)

SELECT	 teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions, team_rank
FROM 	 counted
WHERE	 team_rank <= FLOOR(total_teams * 0.2); -- my way, redundant of teamID (more than the correct ans 1 team)

WITH ts AS (SELECT 	teamID, yearID, SUM(salary) AS total_spend
			FROM	salaries
			GROUP BY teamID, yearID
			ORDER BY teamID, yearID), -- ORDER BY in CTE is not needed and can be omitted
            
	 sp AS (SELECT	teamID, AVG(total_spend) AS avg_spend,
					NTILE(5) OVER (ORDER BY AVG(total_spend) DESC) AS spend_pct
			FROM	ts
			GROUP BY teamID)
            
SELECT	teamID, ROUND(avg_spend / 1000000, 1) AS avg_spend_millions
FROM	sp
WHERE	spend_pct = 1;

-- 3. 
WITH ans AS (SELECT	   teamID, yearID,
					   SUM(salary) AS annual_spend
			 FROM	   salaries
			 GROUP BY  teamID, yearID)

SELECT	teamID, yearID,
		ROUND(SUM(annual_spend) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000, 1) AS cumulative_sum
FROM 	ans;

-- 4. 
WITH ans AS (SELECT	   teamID, yearID,
					   SUM(salary) AS annual_spend
			 FROM	   salaries
			 GROUP BY  teamID, yearID),
	 cm AS (SELECT	teamID, yearID,
					SUM(annual_spend) OVER (PARTITION BY teamID ORDER BY yearID) AS cumulative_sum
			FROM    ans),
	 sob AS (SELECT	*,
					ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY yearID) AS row_num
			 FROM 	cm
			 WHERE 	cumulative_sum >= 1000000000)

SELECT	teamID, yearID, ROUND(cumulative_sum / 1000000000, 2) AS cumulative_sum_billions
FROM 	sob
WHERE 	row_num = 1;


-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
-- 3. What team did each player play on for their starting and ending years?
-- 4. How many players started and ended on the same team and also played for over a decade?

-- 1.
SELECT	* 
FROM 	players;

SELECT	COUNT(playerID)
FROM	players;

-- 2.
SELECT 	nameGiven,
        TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), debut)
			AS starting_age,
		TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), finalGame)
			AS ending_age,
		TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM	players
ORDER BY career_length DESC;

-- 3.             
SELECT 	p.nameGiven,
		s.yearID AS starting_year, s.teamID AS starting_team,
        e.yearID AS ending_year, e.teamID AS ending_team
FROM	players p INNER JOIN salaries s
							ON p.playerID = s.playerID
							AND YEAR(p.debut) = s.yearID
				  INNER JOIN salaries e
							ON p.playerID = e.playerID
							AND YEAR(p.finalGame) = e.yearID;	

-- 4.
SELECT 	p.nameGiven,
		s.yearID AS starting_year, s.teamID AS starting_team,
        e.yearID AS ending_year, e.teamID AS ending_team
FROM	players p INNER JOIN salaries s
							ON p.playerID = s.playerID
							AND YEAR(p.debut) = s.yearID
				  INNER JOIN salaries e
							ON p.playerID = e.playerID
							AND YEAR(p.finalGame) = e.yearID
WHERE	s.teamID = e.teamID AND e.yearID - s.yearID > 10;

SELECT COUNT(*) FROM

(SELECT 	p.nameGiven,
		s.yearID AS starting_year, s.teamID AS starting_team,
        e.yearID AS ending_year, e.teamID AS ending_team
FROM	players p INNER JOIN salaries s
							ON p.playerID = s.playerID
							AND YEAR(p.debut) = s.yearID
				  INNER JOIN salaries e
							ON p.playerID = e.playerID
							AND YEAR(p.finalGame) = e.yearID
WHERE	s.teamID = e.teamID AND e.yearID - s.yearID > 10) AS sq;

-- => 75 players started and ended on the same team and also played for over a decade
        
-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
-- 2. Which players have the same birthday?
-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?

-- 1.
SELECT	*
FROM	players;

-- 2.
WITH bp AS (SELECT	nameGiven,
					CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birthday
			FROM	players)
            
SELECT	 birthday,
		 GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players
FROM	 bp
WHERE	YEAR(birthday) BETWEEN 1980 AND 1990
GROUP BY birthday
ORDER BY birthday;
        
-- 3.
WITH up AS (SELECT DISTINCT s.teamID, s.playerID, p.bats
           FROM salaries s LEFT JOIN players p
           ON s.playerID = p.playerID) -- unique players CTE

SELECT teamID,
		ROUND(SUM(CASE WHEN bats = 'R' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_right,
        ROUND(SUM(CASE WHEN bats = 'L' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_left,
        ROUND(SUM(CASE WHEN bats = 'B' THEN 1 ELSE 0 END) / COUNT(playerID) * 100, 1) AS bats_both
FROM up
GROUP BY teamID;

-- 4. 
WITH hw AS (SELECT	 FLOOR(YEAR(debut) / 10) * 10 AS decade,
					 AVG(weight) AS avg_weight,
					 AVG(height) AS avg_height
			FROM	 players
			GROUP BY decade
			ORDER BY decade)
            
SELECT 	decade,
		avg_weight - LAG(avg_weight) OVER (ORDER BY decade) AS weight_diff,
        avg_height - LAG(avg_height) OVER (ORDER BY decade) AS height_diff
FROM	hw
WHERE 	decade IS NOT NULL;