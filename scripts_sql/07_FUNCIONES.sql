USE marazul_sucre;

-- 1. Consultar la disponibilidad de una especie.
DELIMITER $$

CREATE FUNCTION fn_species_availability(p_id_species INT)
RETURNS DECIMAL(12,3)
READS SQL DATA
BEGIN
    RETURN (
        SELECT COALESCE(SUM(
            c.weight_kg - (
                SELECT COALESCE(SUM(d.sold_weight_kg), 0)
                FROM sale_details d
                WHERE d.id_catch = c.id_catch
            )
        ), 0)
        FROM catches c
        WHERE c.id_species = p_id_species
    );
END$$

DELIMITER ;

-- Prueba con una especie registrada.
SELECT fn_species_availability(1) AS available_weight_kg;

-- Sin registros debe devolver cero.
SELECT fn_species_availability(999999) AS available_weight_kg;


-- 2. Calcular el porcentaje de capacidad utilizada.
DELIMITER $$

CREATE FUNCTION fn_trip_efficiency(p_id_trip INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    RETURN (
        SELECT 100 * COALESCE(SUM(c.weight_kg), 0)
               / v.cargo_capacity_kg
        FROM trips t
        INNER JOIN vessels v ON v.id_vessel = t.id_vessel
        LEFT JOIN catches c ON c.id_trip = t.id_trip
        WHERE t.id_trip = p_id_trip
        GROUP BY t.id_trip, v.cargo_capacity_kg
    );
END$$

DELIMITER ;

-- La función devuelve el porcentaje numérico.
-- CONCAT agrega el símbolo % para mostrarlo.
SELECT CONCAT(fn_trip_efficiency(1), '%') AS efficiency_percentage;


-- 3. Validar la talla promedio de una captura.
DELIMITER $$

CREATE FUNCTION fn_validate_catch_size(
    p_id_species INT,
    p_average_size_cm DECIMAL(7,2)
)
RETURNS VARCHAR(25)
READS SQL DATA
BEGIN
    DECLARE minimum_cm DECIMAL(7,2);

    -- Capturar el caso en que la especie no existe.
    DECLARE EXIT HANDLER FOR NOT FOUND
        RETURN 'ESPECIE_NO_REGISTRADA';

    SELECT minimum_size_cm INTO minimum_cm
    FROM species
    WHERE id_species = p_id_species;

    IF p_average_size_cm < minimum_cm THEN
        RETURN 'VIOLACION_VEDA';
    END IF;

    RETURN 'PERMITIDO';
END$$

DELIMITER ;

-- Sierra tiene una talla mínima registrada de 30 cm.
SELECT fn_validate_catch_size(1, 35) AS size_validation;

SELECT fn_validate_catch_size(1, 20) AS size_validation;

SELECT fn_validate_catch_size(999999, 35) AS size_validation;