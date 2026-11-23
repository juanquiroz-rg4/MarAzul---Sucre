\set ON_ERROR_STOP on

-- Funcion de MySQL adaptada al lenguaje SQL de PostgreSQL.
CREATE FUNCTION fn_trip_efficiency(p_id_trip BIGINT)
RETURNS NUMERIC
LANGUAGE SQL
STABLE
AS $$
    SELECT (
        100 * COALESCE(SUM(c.weight_kg), 0) / v.cargo_capacity_kg
    )::NUMERIC(12,2)
    FROM trips t
    INNER JOIN vessels v ON v.id_vessel = t.id_vessel
    LEFT JOIN catches c ON c.id_trip = t.id_trip
    WHERE t.id_trip = p_id_trip
    GROUP BY t.id_trip, v.cargo_capacity_kg;
$$;
