--  Write a "backfill" query that can populate the entire `actors_history_scd` table in a single query.
WITH actors_change_flags AS (
    SELECT
        actor_id,
        actor_name,
        current_year,
        quality_class,
        is_active,
        LAG(quality_class, 1) OVER (PARTITION BY actor_id ORDER BY current_year) <> quality_class
        OR LAG(is_active, 1) OVER (PARTITION BY actor_id ORDER BY current_year) <> is_active
        OR LAG(quality_class, 1) OVER (PARTITION BY actor_id ORDER BY current_year) IS NULL
        AS did_change
    FROM actors
),

changes_identified AS (
    SELECT
        actor_id,
        actor_name,
        current_year,
        quality_class,
        is_active,
        SUM(CASE WHEN did_change THEN 1 ELSE 0 END)
            OVER (PARTITION BY actor_id ORDER BY current_year) AS change_period
    FROM actors_change_flags
),

aggregated AS (
    SELECT
        actor_id,
        actor_name,
        quality_class,
        is_active,
		change_period,
        MIN(current_year) AS start_date,
        MAX(current_year) AS end_date
    FROM changes_identified
    GROUP BY actor_id, actor_name, quality_class, is_active, change_period
)

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
FROM aggregated
