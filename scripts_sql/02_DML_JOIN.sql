-- Data Manipulation Language (DML) - JOIN

-- A) Fishermen and fishing trips
USE marazul_sucre;

SELECT CONCAT_WS(' ', p.first_names, p.last_names) AS `Fisherman name`,
       p.document AS `Document`,
       e.name AS `Vessel`,
       z.name AS `Fishing zone`,
       j.departure_date AS `Departure date`,
       j.status AS `Trip status`
FROM fishermen AS p
INNER JOIN trip_crew AS t ON t.id_fisherman = p.id_fisherman
INNER JOIN trips AS j ON j.id_trip = t.id_trip
INNER JOIN vessels AS e ON e.id_vessel = j.id_vessel
INNER JOIN fishing_zones AS z ON z.id_zone = j.id_zone
ORDER BY j.departure_date, p.last_names, p.first_names, j.id_trip;


-- B) Monthly catch volume by species

SELECT YEAR(j.return_date) AS `Year`,
       MONTH(j.return_date) AS `Month`,
       e.common_name AS `Species`,
       SUM(c.weight_kg) AS `Total caught (kg)`,
       ROUND(SUM(c.weight_kg) / NULLIF(SUM(c.piece_count), 0), 3)
           AS `Average weight per piece (kg)`
FROM species AS e
INNER JOIN catches AS c ON c.id_species = e.id_species
INNER JOIN trips AS j ON j.id_trip = c.id_trip
WHERE j.return_date IS NOT NULL
GROUP BY YEAR(j.return_date), MONTH(j.return_date), e.common_name
ORDER BY `Year`, `Month`, `Total caught (kg)` DESC, `Species`;


-- C) Sales percentage by zone and species

WITH sales_per_catch AS (
    SELECT id_catch, SUM(sold_weight_kg) AS sold_kg
    FROM sale_details
    GROUP BY id_catch
)
SELECT z.name AS `Fishing zone`,
       e.common_name AS `Species`,
       SUM(c.weight_kg) AS `Total caught (kg)`,
       SUM(COALESCE(v.sold_kg, 0)) AS `Total sold (kg)`,
       ROUND(100 * SUM(COALESCE(v.sold_kg, 0)) /
             NULLIF(SUM(c.weight_kg), 0), 2) AS `Sales percentage`
FROM fishing_zones AS z
INNER JOIN trips AS j ON j.id_zone = z.id_zone
INNER JOIN catches AS c ON c.id_trip = j.id_trip
INNER JOIN species AS e ON e.id_species = c.id_species
LEFT JOIN sales_per_catch AS v ON v.id_catch = c.id_catch
WHERE j.status = 'FINALIZADA'
GROUP BY z.id_zone, z.name, e.id_species, e.common_name
ORDER BY `Sales percentage` DESC, `Fishing zone`, `Species`;


