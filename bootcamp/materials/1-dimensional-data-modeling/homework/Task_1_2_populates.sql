-- Write a query that populates the `actors` table one year at a time.
DO $$

DECLARE
    y INTEGER;
    min_year INTEGER;
    max_year INTEGER;
	
BEGIN
    SELECT MIN(year), MAX(year) INTO min_year, max_year FROM actor_films;
    
    FOR y IN min_year..max_year LOOP
        RAISE NOTICE 'Processing year %', y;
        
        EXECUTE format($f$
		
			INSERT INTO actors (actor_id, actor_name, films, quality_class, is_active, current_year)
			
			WITH latest_year_per_actor AS (
			    SELECT 
					actorid, 
					MAX(year) AS latest_year
			    FROM actor_films
			    WHERE year <= %s
			    GROUP BY actorid
			),
			
			avg_rating_per_actor AS (
			    SELECT
			        af.actorid,
			        AVG(af.rating) AS avg_rating_latest_year
			    FROM actor_films af
			    JOIN latest_year_per_actor ly ON af.actorid = ly.actorid
			    WHERE af.year = ly.latest_year
			    GROUP BY af.actorid
			)
			
			SELECT
			    af.actorid AS actor_id,
			    af.actor AS actor_name,
			
			    -- List of films until the current_year snapshot.
			    ARRAY_AGG(ROW(
			        af.film,
			        af.votes,
			        af.rating,
			        af.filmid,
			        af.year
			    )::films ORDER BY af.year, af.filmid) AS films,
				
				-- The average rating of movies of their most recent year. Keep this sequence.
			    CASE
			        WHEN ar.avg_rating_latest_year > 8 THEN 'star'
			        WHEN ar.avg_rating_latest_year > 7 THEN 'good'
			        WHEN ar.avg_rating_latest_year > 6 THEN 'average'
					WHEN ar.avg_rating_latest_year <= 6 THEN 'bad'
			    END::quality_class AS quality_class,
			
				-- If actor has films in the current_year
			    BOOL_OR(af.year = %s) AS is_active,
			
			    %s AS current_year
			
			FROM actor_films af
			INNER JOIN latest_year_per_actor ly ON af.actorid = ly.actorid
			INNER JOIN avg_rating_per_actor ar ON af.actorid = ar.actorid
			WHERE af.year <= %s
			GROUP BY af.actorid, af.actor, ar.avg_rating_latest_year;

        $f$, y, y, y, y);
    END LOOP;
END
$$;