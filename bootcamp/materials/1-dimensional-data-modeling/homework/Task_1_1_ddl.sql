-- Create a DDL for an `actors` table with the following fields:
CREATE TYPE films AS (
	film TEXT, -- The name of the film.
	votes INTEGER, -- The number of votes the film received.
	rating REAL, -- The rating of the film.
	filmid TEXT, -- A unique identifier for each film.
	year INTEGER -- To help calculate the quality_class (added).
);

CREATE TYPE quality_class AS ENUM ('star','good','average','bad');
/*		
- `star`: Average rating > 8.
- `good`: Average rating > 7 and ≤ 8.
- `average`: Average rating > 6 and ≤ 7.
- `bad`: Average rating ≤ 6.
*/
		
CREATE TABLE actors (
	actor_id TEXT,
	actor_name TEXT,
    films films[],
    quality_class quality_class, -- Determined by the average rating of movies of their most recent year.
	is_active BOOLEAN, -- Is currently active in the film industry (i.e., making films this year).
	current_year INTEGER -- Snapshot year (added).
);
