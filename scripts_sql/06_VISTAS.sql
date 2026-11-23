-- Lenguaje procedimental - VIEW 

USE marazul_sucre;

-- 1. Capturas con peso disponible en el muelle.
CREATE OR REPLACE VIEW v_available_dock_catches AS
SELECT c.id_catch AS catch_code,
       e.common_name AS species,
       c.weight_kg - COALESCE(s.sold_kg, 0) AS available_weight_kg,
       c.landing_date,
       v.name AS vessel_name
FROM catches c
INNER JOIN species e ON e.id_species = c.id_species
INNER JOIN trips t ON t.id_trip = c.id_trip
INNER JOIN vessels v ON v.id_vessel = t.id_vessel
LEFT JOIN (
    SELECT id_catch, SUM(sold_weight_kg) AS sold_kg
    FROM sale_details
    GROUP BY id_catch
) s ON s.id_catch = c.id_catch
WHERE c.weight_kg - COALESCE(s.sold_kg, 0) > 0;

SELECT * FROM v_available_dock_catches
ORDER BY catch_code;


-- 2. Resumen de jornadas de pesca.
CREATE OR REPLACE VIEW v_fishing_trip_summary AS
SELECT t.id_trip,
       v.name AS vessel_name,
       z.name AS fishing_zone,
       t.departure_date,
       COALESCE(tc.fisherman_count, 0) AS fisherman_count,
       COALESCE(c.total_caught_kg, 0) AS total_caught_kg
FROM trips t
INNER JOIN vessels v ON v.id_vessel = t.id_vessel
INNER JOIN fishing_zones z ON z.id_zone = t.id_zone
LEFT JOIN (
    SELECT id_trip, COUNT(DISTINCT id_fisherman) AS fisherman_count
    FROM trip_crew
    GROUP BY id_trip
) tc ON tc.id_trip = t.id_trip
LEFT JOIN (
    SELECT id_trip, SUM(weight_kg) AS total_caught_kg
    FROM catches
    GROUP BY id_trip
) c ON c.id_trip = t.id_trip;

SELECT * FROM v_fishing_trip_summary
ORDER BY id_trip;


-- 3. Indicadores de comercialización por especie.
-- Rotación comercial: porcentaje del peso capturado que se ha vendido.
-- Umbrales de ingreso en COP:
-- ALTO: superior a 10.000.000.
-- MEDIO: desde 5.000.000 hasta 10.000.000.
-- BAJO: inferior a 5.000.000.
CREATE OR REPLACE VIEW v_fishing_commercialization_kpi AS
SELECT e.common_name AS species,
       SUM(c.weight_kg) AS total_caught_kg,
       SUM(COALESCE(s.sold_kg, 0)) AS total_sold_kg,
       SUM(COALESCE(s.revenue, 0)) AS total_revenue,
       ROUND(
           100 * SUM(COALESCE(s.sold_kg, 0))
           / NULLIF(SUM(c.weight_kg), 0), 2
       ) AS commercial_turnover_percentage,
       CASE
           WHEN SUM(COALESCE(s.revenue, 0)) > 10000000 THEN 'ALTO'
           WHEN SUM(COALESCE(s.revenue, 0)) >= 5000000 THEN 'MEDIO'
           ELSE 'BAJO'
       END AS performance_level
FROM species e
INNER JOIN catches c ON c.id_species = e.id_species
LEFT JOIN (
    SELECT id_catch,
           SUM(sold_weight_kg) AS sold_kg,
           SUM(sold_weight_kg * unit_price) AS revenue
    FROM sale_details
    GROUP BY id_catch
) s ON s.id_catch = c.id_catch
GROUP BY e.id_species, e.common_name;

SELECT * FROM v_fishing_commercialization_kpi
ORDER BY total_revenue DESC;