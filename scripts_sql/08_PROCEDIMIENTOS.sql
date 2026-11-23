-- Procedimientos Almacenados

USE marazul_sucre;


ALTER TABLE catches
    ADD COLUMN available_weight_kg DECIMAL(12,3) NOT NULL DEFAULT 0;

SET @previous_safe_updates = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

UPDATE catches c
LEFT JOIN (
    SELECT id_catch, SUM(sold_weight_kg) AS sold_kg
    FROM sale_details
    GROUP BY id_catch
) s ON s.id_catch = c.id_catch
SET c.available_weight_kg = c.weight_kg - COALESCE(s.sold_kg, 0);

SET SQL_SAFE_UPDATES = @previous_safe_updates;

ALTER TABLE catches
    ADD CONSTRAINT ck_catch_availability
    CHECK (available_weight_kg >= 0 AND available_weight_kg <= weight_kg);


-- 1. Registrar una captura con saldo inicial igual al peso capturado.
DELIMITER $$

CREATE PROCEDURE sp_register_catch(
    IN p_id_trip INT,
    IN p_id_species INT,
    IN p_weight_kg DECIMAL(12,3),
    IN p_piece_count INT
)
BEGIN
    IF p_weight_kg IS NULL OR p_weight_kg <= 0
       OR p_piece_count IS NULL OR p_piece_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El peso y la cantidad de piezas deben ser mayores que cero';
    END IF;

    INSERT INTO catches
        (id_trip, id_species, weight_kg, piece_count, available_weight_kg)
    VALUES
        (p_id_trip, p_id_species, p_weight_kg, p_piece_count, p_weight_kg);
END$$

DELIMITER ;


-- 2. Despachar una captura para una venta existente.
-- Ejecutar CALL fuera de otra transaccion: este procedimiento controla la suya.
DELIMITER $$

CREATE PROCEDURE sp_dispatch_catch(
    IN p_id_sale INT,
    IN p_id_catch INT,
    IN p_weight_to_sell DECIMAL(12,3),
    IN p_unit_price DECIMAL(12,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_weight_to_sell IS NULL OR p_weight_to_sell <= 0
       OR p_unit_price IS NULL OR p_unit_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El peso y el precio deben ser mayores que cero';
    END IF;

    -- Verificar y descontar en una sola sentencia para evitar sobreventa.
    UPDATE catches
    SET available_weight_kg = available_weight_kg - p_weight_to_sell
    WHERE id_catch = p_id_catch
      AND available_weight_kg >= p_weight_to_sell;

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Captura inexistente o disponibilidad insuficiente';
    END IF;

    INSERT INTO sale_details
        (id_sale, id_catch, sold_weight_kg, unit_price)
    VALUES
        (p_id_sale, p_id_catch, p_weight_to_sell, p_unit_price);

    COMMIT;
END$$

DELIMITER ;


-- 3. Procesar una venta integral con una cabecera y un detalle.
-- Ejecutar CALL fuera de otra transaccion.
-- Codigos: 0 exito; -1 disponibilidad insuficiente; -2 error tecnico.
-- En MySQL, SQLEXCEPTION equivale al manejo general de excepciones.
DELIMITER $$

CREATE PROCEDURE sp_process_complete_sale(
    IN p_id_buyer INT,
    IN p_id_commercial_manager INT,
    IN p_id_catch INT,
    IN p_weight_to_sell DECIMAL(12,3),
    IN p_unit_price DECIMAL(12,2),
    OUT p_result_code INT
)
main: BEGIN
    DECLARE buyer_count INT;
    DECLARE catch_count INT;
    DECLARE new_sale_id INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result_code = -2;
    END;

    SET p_result_code = -2;
    START TRANSACTION;

    SELECT COUNT(*) INTO buyer_count
    FROM buyers
    WHERE id_buyer = p_id_buyer;

    IF buyer_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El comprador no esta registrado';
    END IF;

    IF p_weight_to_sell IS NULL OR p_weight_to_sell <= 0
       OR p_unit_price IS NULL OR p_unit_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El peso y el precio deben ser mayores que cero';
    END IF;

    SELECT COUNT(*) INTO catch_count
    FROM catches
    WHERE id_catch = p_id_catch;

    IF catch_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La captura no existe';
    END IF;

    -- La condicion comprueba el saldo al bloquear y actualizar la captura.
    UPDATE catches
    SET available_weight_kg = available_weight_kg - p_weight_to_sell
    WHERE id_catch = p_id_catch
      AND available_weight_kg >= p_weight_to_sell;

    IF ROW_COUNT() <> 1 THEN
        ROLLBACK;
        SET p_result_code = -1;
        LEAVE main;
    END IF;

    INSERT INTO sales (id_buyer, id_commercial_manager)
    VALUES (p_id_buyer, p_id_commercial_manager);

    SET new_sale_id = LAST_INSERT_ID();

    INSERT INTO sale_details
        (id_sale, id_catch, sold_weight_kg, unit_price)
    VALUES
        (new_sale_id, p_id_catch, p_weight_to_sell, p_unit_price);

    COMMIT;
    SET p_result_code = 0;
END$$

DELIMITER ;

