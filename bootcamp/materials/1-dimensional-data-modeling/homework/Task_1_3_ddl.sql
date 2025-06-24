-- Create a DDL for an `actors_history_scd` table with the following features:
--Implements type 2 dimension modeling (i.e., includes `start_date` and `end_date` fields).
--Tracks `quality_class` and `is_active` status for each actor in the `actors` table.
CREATE TABLE actors_history_scd (
    actor_id TEXT,
	actor_name TEXT,
	quality_class quality_class, -- SCD 2 column
	is_active BOOLEAN,  -- SCD 2 column
	start_date INTEGER,
	end_date INTEGER,
    PRIMARY KEY (actor_id, start_date)
);
