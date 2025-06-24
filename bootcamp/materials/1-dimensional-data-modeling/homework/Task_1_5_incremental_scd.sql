-- Write an "incremental" query that combines the previous year's SCD data with new incoming data from the `actors` table.
CREATE TYPE actor_scd_type AS (
    quality_class quality_class,
    is_active boolean,
    start_date INTEGER,
    end_date INTEGER
);


WITH 
last_scd AS (
    SELECT DISTINCT ON (actor_id)
        actor_id,
        actor_name,
        quality_class,
        is_active,
        start_date,
        end_date
    FROM actors_history_scd
    ORDER BY actor_id, end_date DESC -- Keep it to have the latest record at the top of the list.
),

latest_actors AS (
    SELECT * 
    FROM actors
    WHERE current_year = (SELECT MAX(current_year) FROM actors)
),

record_transitions AS (
    SELECT
        a.actor_id,
        UNNEST(ARRAY[
            -- Old record.
            ROW(
                s.quality_class,
                s.is_active,
                s.start_date,
                s.end_date -- to be tested for records within the same year period (e.g. if registers new quality_class when need to be recalculated)
            )::actor_scd_type,
            
            -- New record.
            ROW(
                a.quality_class,
                a.is_active,
                a.current_year,
                a.current_year
            )::actor_scd_type
        ]) AS records,
        a.actor_name
    FROM latest_actors a
    INNER JOIN last_scd s ON a.actor_id = s.actor_id
    WHERE a.quality_class IS DISTINCT FROM s.quality_class
       OR a.is_active IS DISTINCT FROM s.is_active
),

unchanged_records AS (
    SELECT
        a.actor_id,
        a.actor_name,
        a.quality_class,
        a.is_active,
        s.start_date,
        a.current_year AS end_date
    FROM latest_actors a
    INNER JOIN last_scd s ON a.actor_id = s.actor_id
    WHERE a.quality_class = s.quality_class
      AND a.is_active = s.is_active
),

new_records AS (
    SELECT
        a.actor_id,
        a.actor_name,
        a.quality_class,
        a.is_active,
        a.current_year AS start_date,
        a.current_year AS end_date
    FROM latest_actors a
    LEFT JOIN last_scd s ON a.actor_id = s.actor_id
    WHERE s.actor_id IS NULL
),

unnested_changed_records AS (
    SELECT
        actor_id,
        actor_name,
        (records).quality_class,
        (records).is_active,
        (records).start_date,
        (records).end_date
    FROM record_transitions
),

merged AS (
    SELECT * FROM unchanged_records
    UNION ALL
    SELECT * FROM unnested_changed_records
    UNION ALL
    SELECT * FROM new_records
)

-- Insert only truly new records: prevent duplicates by matching actor_id, quality_class, is_active, start_date, end_date
INSERT INTO actors_history_scd (
    actor_id,
    actor_name,
    quality_class,
    is_active,
    start_date,
    end_date
)
SELECT
    actor_id,
    actor_name,
    quality_class,
    is_active,
    start_date,
    end_date
FROM merged m
WHERE NOT EXISTS (
    SELECT 1
    FROM actors_history_scd s
    WHERE s.actor_id = m.actor_id
      AND s.quality_class = m.quality_class
      AND s.is_active = m.is_active
      AND s.start_date = m.start_date
      AND s.end_date = m.end_date
);


/*
-- Inserting new record for actor Fred Astaire. Testing new entries with new year.
INSERT INTO actors (actor_id, actor_name, films, quality_class, is_active, current_year)
VALUES (
    'nm0000001',
    'Fred Astaire',
    ARRAY[
        ROW('“xxx”', 123, 10, 'tt9999999', 2025)::films
    ],
    'star',
    true,
    2025
);
*/