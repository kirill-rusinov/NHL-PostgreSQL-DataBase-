--Ранжирование команд по среднему весу игроков

SELECT team_name, ROUND(AVG(weight), 2) AS average_weight
FROM teams
JOIN players USING(team_id)
GROUP BY team_name
ORDER BY average_weight DESC;


--Ранжирование команд по среднему росту игроков

SELECT team_name, ROUND(AVG(height), 2) AS average_height
FROM teams
JOIN players USING(team_id)
GROUP BY team_name
ORDER BY average_height DESC;


--Ранжирование команд по 'мощи' (интегральный показатель по рангам роста и веса, чем меньше тем команда 'мощнее')

WITH avg_weight_rnk AS(
SELECT team_name, ROUND(AVG(weight), 2) AS average_weight, 
	RANK() OVER(ORDER BY AVG(weight) DESC) AS rnk_w
FROM teams
JOIN players USING(team_id)
GROUP BY team_name
			), 
avg_height_rnk AS (
SELECT team_name, ROUND(AVG(height), 2) AS average_height, 
	RANK() OVER(ORDER BY AVG(height) DESC) AS rnk_h
FROM teams
JOIN players USING(team_id)
GROUP BY team_name
				)
SELECT a1.team_name, rnk_w + rnk_h AS rating
FROM avg_weight_rnk a1
JOIN avg_height_rnk a2 USING(team_name)
ORDER BY rating


--Ранжирование игроков по росту (10 самых высоких и самый высокий россиянин)

WITH top_height AS (
SELECT first_name, last_name, height, RANK() OVER(ORDER BY height DESC) AS rnk FROM players
LIMIT 10
					),
top_russian AS (
SELECT first_name, last_name, height, rnk FROM (
	SELECT first_name, last_name, height, country_id, RANK() OVER(ORDER BY height DESC) AS rnk 
	FROM players
												) subq
JOIN countries USING(country_id)
WHERE country_name = 'Russia'
LIMIT 1
			)
SELECT first_name, last_name, CAST(height AS varchar), CAST(rnk AS varchar) FROM top_height
UNION ALL
SELECT '..........', '..........', '..........', '..........'
UNION ALL
SELECT first_name, last_name, CAST(height AS varchar), CAST(rnk AS varchar) FROM top_russian


--Ранжирование игроков по весу (10 самых тяжелых и 10 самых легких)

WITH top_weight AS (
	SELECT first_name, last_name, weight FROM players
	ORDER BY weight DESC 
	LIMIT 10
					),
bottom_weight AS (
	SELECT * FROM (
		SELECT first_name, last_name, weight FROM players
		ORDER BY weight
		LIMIT 10
				) subq
	ORDER BY weight DESC
				)

SELECT first_name, last_name, CAST(weight AS varchar) FROM top_weight
UNION ALL
SELECT '..........', '..........', '..........'
UNION ALL
SELECT first_name, last_name, CAST(weight AS varchar) FROM bottom_weight


--Количество кубков Стэнли по странам

SELECT country_name, SUM(number_of_cups) AS total_cups
FROM teams
JOIN cities USING(city_id)
JOIN states USING(state_id)
JOIN countries USING(country_id)
GROUP BY country_name;


--Топ-10 игроков по сумме контракта с разницей между ними

SELECT first_name, last_name, team_name, country_name, salary, (salary - LEAD(salary) OVER(ORDER BY salary DESC)) AS delta
FROM players
JOIN teams USING(team_id)
JOIN countries USING(country_id)
ORDER BY salary DESC
LIMIT 10


--Команды какого дивизиона больше всего брали кубок

SELECT division_name, SUM(number_of_cups) as sum_cups
FROM divisions
JOIN teams USING(division_id)
GROUP BY division_name
ORDER BY 2 DESC
LIMIT 1


--Ранжирование команд по количеству европейцев

SELECT team_name, COUNT(player_id)
FROM teams
JOIN players USING(team_id)
JOIN countries USING(country_id)
WHERE country_name NOT IN ('Canada', 'USA')
GROUP BY team_name
ORDER BY 2 DESC


--Вывод самых высокооплачиваемых игроков каждой команды

SELECT first_name, last_name, salary, team_name FROM (
	SELECT first_name, last_name, salary, team_name, RANK() OVER(PARTITION BY team_id ORDER BY salary DESC) AS rnk
	FROM players
	JOIN teams USING(team_id)
			) subq
WHERE rnk = 1


--Бюджет каждой команды

SELECT team_name, SUM(salary) AS budget
FROM players
JOIN teams USING(team_id)
GROUP BY team_name
ORDER BY 2 DESC


--В каком дивизионе больше всего русских игроков

SELECT division_name, COUNT(player_id)
FROM divisions
JOIN teams USING(division_id)
JOIN players USING(team_id)
JOIN countries USING(country_id)
WHERE country_name = 'Russia'
GROUP BY division_name
ORDER BY 2 DESC
LIMIT 1


--Самый высокий игрок национальности топ-6

SELECT first_name, last_name, country_name, height
FROM players
JOIN countries USING(country_id)
WHERE height = (
	SELECT MAX(height) 
	FROM players
	JOIN countries USING(country_id)
	WHERE country_name IN ('Canada', 'USA', 'Russia', 'Sweden', 'Czech Republic', 'Finland')
	)
AND country_name IN ('Canada', 'USA', 'Russia', 'Sweden', 'Czech Republic', 'Finland')


--Топ-3 по контракту на каждой позиции

SELECT * FROM (
	SELECT first_name, last_name, salary, player_role, team_name, RANK() OVER(PARTITION BY player_role ORDER BY salary DESC) AS rnk 
	FROM players
	JOIN teams USING(team_id)
				) subq
WHERE rnk <= 3


--Топ-3 по контракту каждой страны

SELECT * FROM (
	SELECT first_name, last_name, salary, country_name, team_name, RANK() OVER(PARTITION BY country_id ORDER BY salary DESC) AS rnk 
	FROM players
	JOIN countries USING(country_id)
	JOIN teams USING(team_id)
				) subq
WHERE rnk <= 3


--Топ игроков по контракту на каждый возраст

SELECT first_name, last_name, salary, age, team_name FROM (
	SELECT first_name, last_name, salary, age, team_name, RANK() OVER(PARTITION BY age ORDER BY salary DESC) AS rnk 
	FROM players
	JOIN teams USING(team_id)
				) subq
WHERE rnk = 1


--Средний контракт на каждый возраст

SELECT DISTINCT age,  FLOOR(AVG(salary) OVER(PARTITION BY age)) AS avg_sal 
FROM players
ORDER BY age;

--Команды, где капитан является самым высокооплачиваемым игроком

SELECT team_name, first_name, last_name, salary
FROM teams
JOIN players USING(team_id)
WHERE player_id = capitan
AND player_id IN (
	SELECT player_id FROM (
			SELECT player_id, RANK() OVER(PARTITION BY team_id ORDER BY salary DESC) AS rnk
			FROM players
							) subq
	WHERE rnk = 1
					)

--Сколько раз команда "защитила" титул (т.е. после победы снова выиграла в следующем году)

SELECT SUM(title_defence) AS count_of_title_defence FROM (
	SELECT team_name, year_of_cup, 
		CASE
		WHEN LAG(team_name) OVER(ORDER BY year_of_cup) = team_name THEN 1
		ELSE 0
		END AS title_defence
	FROM cups	
								) subq;

--Сколько раз команда "вернула" титул (т.е. после победы снова выиграла не в следующем году, а через год)

SELECT SUM(title_returns) AS return_of_title FROM (
	SELECT team_name, year_of_cup, 
			CASE
			WHEN LAG(team_name, 2) OVER(ORDER BY year_of_cup) = team_name 
			AND LAG(team_name) OVER(ORDER BY year_of_cup) <> team_name 
			THEN 1
			ELSE 0
			END AS title_returns
		FROM cups									)subq;

