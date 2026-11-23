-- TRIGGER

USE marazul_sucre;

-- 1. Inicializar la disponibilidad de una captura.
DELIMITER $$

CREATE TRIGGER trg_initialize_availability
BEFORE INSERT ON catches
FOR EACH ROW
BEGIN
    SET NEW.available_weight_kg = NEW.weight_kg;
END$$

DELIMITER ;


-- 2. Impedir que la disponibilidad sea negativa.
DELIMITER $$

CREATE TRIGGER trg_prevent_negative_weight
BEFORE UPDATE ON catches
FOR EACH ROW
BEGIN
    IF NEW.available_weight_kg < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El peso disponible no puede ser negativo';
    END IF;
END$$

DELIMITER ;


-- 3. Registrar los cambios en los detalles de venta.
CREATE TABLE IF NOT EXISTS sales_audit (
    id_audit BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    change_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    db_user VARCHAR(288) NOT NULL,
    id_detail INT UNSIGNED NOT NULL,
    previous_weight DECIMAL(12,3) NOT NULL,
    new_weight DECIMAL(12,3) NOT NULL,
    previous_price DECIMAL(12,2) NOT NULL,
    new_price DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_audit_detail FOREIGN KEY (id_detail)
        REFERENCES sale_details(id_detail)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX ix_audit_detail_date (id_detail, change_date)
) ENGINE=InnoDB;

DELIMITER $$

CREATE TRIGGER trg_audit_sale_changes
AFTER UPDATE ON sale_details
FOR EACH ROW
BEGIN
    INSERT INTO sales_audit (
        change_date,
        db_user,
        id_detail,
        previous_weight,
        new_weight,
        previous_price,
        new_price
    )
    VALUES (
        CURRENT_TIMESTAMP,
        USER(),
        NEW.id_detail,
        OLD.sold_weight_kg,
        NEW.sold_weight_kg,
        OLD.unit_price,
        NEW.unit_price
    );
END$$

DELIMITER ;