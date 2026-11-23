-- Data Manipulation Language (DML) - SUBCONSULTA 

-- 1. Capturas sin registros de venta
USE marazul_sucre;

SELECT c.id_catch AS `Catch`, e.common_name AS `Species`,
       c.landing_date AS `Landing date`, c.weight_kg AS `Weight (kg)`
FROM catches c
INNER JOIN species e ON e.id_species = c.id_species
WHERE NOT EXISTS (
    SELECT 1 FROM sale_details d
    WHERE d.id_catch = c.id_catch
)
ORDER BY c.id_catch;


-- 2. Especies cuyo volumen supera el promedio general por especie

SELECT e.common_name AS `Species`,
       SUM(c.weight_kg) AS `Total caught (kg)`
FROM species e
INNER JOIN catches c ON c.id_species = e.id_species
GROUP BY e.id_species, e.common_name
HAVING SUM(c.weight_kg) > (
    SELECT AVG(t.total_kg)
    FROM (
        SELECT COALESCE(SUM(c2.weight_kg), 0) AS total_kg
        FROM species e2
        LEFT JOIN catches c2 ON c2.id_species = e2.id_species
        GROUP BY e2.id_species
    ) t
)
ORDER BY `Total caught (kg)` DESC, `Species`;


-- 3. Jornadas con capturas superiores al promedio de su zona

SELECT j.id_trip, j.id_zone,
       SUM(c.weight_kg) AS `Total caught (kg)`
FROM trips j
INNER JOIN catches c ON c.id_trip = j.id_trip
GROUP BY j.id_trip, j.id_zone
HAVING SUM(c.weight_kg) > (
    SELECT AVG((
        SELECT COALESCE(SUM(c2.weight_kg), 0)
        FROM catches c2
        WHERE c2.id_trip = j2.id_trip
    ))
    FROM trips j2
    WHERE j2.id_zone = j.id_zone
)
ORDER BY j.id_zone, `Total caught (kg)` DESC, j.id_trip;

