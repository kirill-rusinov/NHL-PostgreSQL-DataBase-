--скрипт для создания таблиц в БД

DROP TABLE IF EXISTS cups;
DROP TABLE IF EXISTS divisions CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS players;


CREATE TABLE countries 
(
	country_id serial PRIMARY KEY,
	country_name varchar UNIQUE NOT NULL
);



CREATE TABLE states 
(
	state_id serial PRIMARY KEY,
	state_name varchar UNIQUE NOT NULL,
	country_id int,
	
	CONSTRAINT Fk_states_countries FOREIGN KEY (country_id) REFERENCES countries (country_id)
);



CREATE TABLE cities
(
	cities_id serial PRIMARY KEY,
	city_name varchar NOT NULL,
	state_id int,
	
	CONSTRAINT Fk_cities_state_id FOREIGN KEY (state_id) REFERENCES states (state_id)
);

ALTER TABLE cities
RENAME COLUMN cities_id TO city_id;



CREATE TABLE divisions
(
	division_id serial PRIMARY KEY,
	division_name varchar UNIQUE NOT NULL,
	conference_name varchar
);



CREATE TABLE teams
(
	team_id serial PRIMARY KEY,
	team_name varchar UNIQUE NOT NULL,
	city_id int,
	foundation int,
	number_of_cups int,
	last_cups int UNIQUE,
	division_id int,
	stadium_capacity int,
	capitan int,
	
	CONSTRAINT Fk_teams_city_id FOREIGN KEY (city_id) REFERENCES cities (city_id),
	CONSTRAINT Chk_teams_foundation CHECK (foundation BETWEEN 1800 AND 2021),
	CONSTRAINT Chk_teams_number_of_cups CHECK (number_of_cups >= 0),
	CONSTRAINT Chk_teams_last_cups CHECK (last_cups BETWEEN 1800 AND 2021),
	CONSTRAINT Fk_teams_division_id FOREIGN KEY (division_id) REFERENCES divisions (division_id),
	CONSTRAINT Chk_teams_stadium_capacity CHECK (stadium_capacity >= 0)
);



CREATE TABLE players
(
	player_id serial PRIMARY KEY,
	first_name varchar NOT NULL,
	last_name varchar NOT NULL,
	team_id int REFERENCES teams(team_id),
	country_id int REFERENCES countries(country_id),
	player_role varchar CHECK (player_role IN ('GK', 'D', 'LW', 'RW', 'C')),
	salary bigint,
	age int CHECK (age > 14),
	height int,
	weight int
);



CREATE TABLE cups (
	year_of_cup int PRIMARY KEY,
	team_name varchar
					);
