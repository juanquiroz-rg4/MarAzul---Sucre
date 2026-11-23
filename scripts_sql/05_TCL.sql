USE marazul_sucre;

-- 1. Confirmar una cabecera y dos detalles.
START TRANSACTION;
INSERT INTO sales (id_buyer, id_commercial_manager)
VALUES (1, 2);
SET @sale1 = LAST_INSERT_ID();

INSERT INTO sale_details
    (id_sale, id_catch, sold_weight_kg, unit_price)
VALUES (@sale1, 5, 1, 18000), (@sale1, 10, 1, 24000);
COMMIT;

SELECT * FROM sales WHERE id_sale = @sale1;
SELECT * FROM sale_details WHERE id_sale = @sale1;

-- 2. Cancelar una venta superior al saldo disponible.
-- El saldo se calcula restando al peso capturado el peso vendido.
DELIMITER $$
DROP PROCEDURE IF EXISTS tcl_validate_sale$$
CREATE PROCEDURE tcl_validate_sale()
BEGIN
    DECLARE balance, x DECIMAL(12,3);
    DECLARE sale INT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT weight_kg INTO balance
    FROM catches WHERE id_catch = 5 FOR UPDATE;

    IF balance IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe la captura 5';
    END IF;

    SELECT balance - COALESCE(SUM(sold_weight_kg), 0) INTO balance
    FROM sale_details WHERE id_catch = 5 FOR UPDATE;

    INSERT INTO sales (id_buyer, id_commercial_manager)
    VALUES (1, 2);
    SET sale = LAST_INSERT_ID();
    SET @sale2 = sale;
    SET x = GREATEST(balance, 0) + 1;

    IF x > balance THEN
        ROLLBACK;
        SELECT 'Venta cancelada: kilos solicitados superiores al saldo' AS warning,
               x AS requested_kg, balance AS available_kg;
    ELSE
        INSERT INTO sale_details
            (id_sale, id_catch, sold_weight_kg, unit_price)
        VALUES (sale, 5, x, 18000);
        COMMIT;
    END IF;
END$$
DELIMITER ;

CALL tcl_validate_sale();
SELECT COUNT(*) AS saved_sales FROM sales WHERE id_sale = @sale2;
SELECT COUNT(*) AS saved_details FROM sale_details WHERE id_sale = @sale2;

-- 3. Conservar el primer item y descartar el segundo.
START TRANSACTION;
INSERT INTO sales (id_buyer, id_commercial_manager)
VALUES (1, 2);
SET @sale3 = LAST_INSERT_ID();

INSERT INTO sale_details
    (id_sale, id_catch, sold_weight_kg, unit_price)
VALUES (@sale3, 5, 1, 18000);
SAVEPOINT sp_item1;

-- Ejecutar esta sentencia por separado. Se espera error CHECK por peso negativo.
INSERT INTO sale_details
    (id_sale, id_catch, sold_weight_kg, unit_price)
VALUES (@sale3, 10, -5, 24000);

-- Despues del error esperado, ejecutar estas dos instrucciones.
ROLLBACK TO SAVEPOINT sp_item1;
COMMIT;

SELECT * FROM sales WHERE id_sale = @sale3;
SELECT * FROM sale_details WHERE id_sale = @sale3;


