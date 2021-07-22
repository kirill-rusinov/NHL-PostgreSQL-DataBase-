--Создаем расписание сезона: 
--У нас 31 команда, каждая сыграет с каждой дома и на выезде, т.е. 60 игр, а всего в чемпионате 31*60/2=930 игр.

DROP TABLE IF EXISTS schedule;
CREATE TABLE schedule (
	game_id serial PRIMARY KEY,
	team_1 varchar,
	team_2 varchar,
	game varchar DEFAULT NULL
);

INSERT INTO schedule (team_1, team_2)
SELECT t1.team_name, t2.team_name
FROM teams t1, teams t2
WHERE t1.team_name <> t2.team_name
ORDER BY RANDOM();


--Создаем турнирную таблицу: 

DROP TABLE IF EXISTS season;
CREATE TABLE season (
	team_name varchar, 
	division_name varchar,
	points int DEFAULT 0,
	games_played int DEFAULT 0,
	
	CONSTRAINT fk_season_team_name FOREIGN KEY (team_name) REFERENCES teams(team_name),
	CONSTRAINT fk_division_name FOREIGN KEY (division_name) REFERENCES divisions(division_name)
);

INSERT INTO season (team_name, division_name)
SELECT team_name, division_name
FROM teams
JOIN divisions USING(division_id);


--Далее симулируем игры:

--Создаем счетчик, чтобы пробежать по расписанию:

DROP SEQUENCE NHL_seq_1;
CREATE SEQUENCE NHL_seq_1;


--Функция, которая отыгрывает матч:
--Количество голов каждой команды определяем рандомом (ограничим 7-ю шайбами)

CREATE OR REPLACE FUNCTION play_match(OUT game_result varchar) 
AS $$
DECLARE
game_number int;
score_team_1 int;
score_team_2 int;
BEGIN
	game_number = nextval('NHL_seq_1');
	score_team_1 = floor(random()*8);
	score_team_2 = floor(random()*8);
	SELECT team_1 || ' ' || score_team_1 || ' : ' || score_team_2 || ' ' || team_2
	INTO game_result
	FROM schedule
	WHERE game_id = game_number;
	
--Заносим результат в расписание:	

	UPDATE schedule
	SET game = score_team_1 || ' : ' || score_team_2
	WHERE game_id = game_number;
	
--Обновляем турнирную таблицу:
--Добавляем 1 к количеству сыгранных игр:

	UPDATE season
	SET games_played = games_played + 1
	WHERE team_name IN (
		SELECT team_1
		FROM schedule
		WHERE game_id = game_number
		UNION
		SELECT team_2
		FROM schedule
		WHERE game_id = game_number
						);
						
--Начисляем очки первой команде (2 за победу, 1 за ничью):

	UPDATE season
	SET points = points + CASE
		WHEN score_team_1 > score_team_2 THEN 2
		WHEN score_team_1 = score_team_2 THEN 1
		ELSE 0
	END
	WHERE team_name = (
		SELECT team_1 FROM schedule
		WHERE game_id = game_number
						);
						
--Начисляем очки второй команде (2 за победу, 1 за ничью):

	UPDATE season
	SET points = points + CASE
		WHEN score_team_2 > score_team_1 THEN 2
		WHEN score_team_2 = score_team_1 THEN 1
		ELSE 0
	END
	WHERE team_name = (
		SELECT team_2 FROM schedule
		WHERE game_id = game_number
						);						
						
END						
$$ LANGUAGE plpgsql;

--Симулируем заданное количество игр:

SELECT play_match() FROM generate_series(1, 927);


--Вывод оставшихся игр:

SELECT * FROM schedule
WHERE game is NULL  --без WHERE выводятся все игры, в т.ч. сыгранные
ORDER BY game_id;


--Вывод текущей турнирной таблицы: 
--Добавляем текущее место команды в дивизионе и попадает ли команда в плей-офф (для этого нужно быть в топ-4 своего дивизиона)

SELECT *, DENSE_RANK() OVER(PARTITION BY division_name ORDER BY points DESC) AS place,
CASE
	WHEN RANK() OVER(PARTITION BY division_name ORDER BY points DESC) <= 4 THEN 'YES'
	ELSE 'NO'
END AS play_off
FROM season;
