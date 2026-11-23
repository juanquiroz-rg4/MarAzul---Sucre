-- Data Definition Language (DDL)

-- A) quality_inspections
USE marazul_sucre;

CREATE TABLE quality_inspections (
    id_inspection INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_catch INT UNSIGNED NOT NULL,
    control_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    temperature_c DECIMAL(4,1) NOT NULL,
    freshness_level VARCHAR(10) NOT NULL,
    CONSTRAINT fk_inspection_catch FOREIGN KEY (id_catch)
        REFERENCES catches(id_catch)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_inspection_temperature
        CHECK (temperature_c BETWEEN -5.0 AND 15.0),
    CONSTRAINT ck_inspection_freshness
        CHECK (freshness_level IN ('EXELENTE', 'ACEPTABLE', 'RECHAZADO')),
    INDEX ix_inspection_catch_date (id_catch, control_date)
) ENGINE=InnoDB;

SHOW CREATE TABLE quality_inspections;

-- B) vessels

ALTER TABLE vessels
    ADD COLUMN autonomy_category VARCHAR(25)
        NOT NULL DEFAULT 'INSHORE',
    ADD CONSTRAINT ck_vessel_category
        CHECK (autonomy_category IN (
            'BAJAMAR', 'ARTESANAL_INTERMEDIA', 'ALTAMAR'
        ));

-- C) sale_details

ALTER TABLE marazul_sucre.sale_details
    DROP FOREIGN KEY fk_detail_catch,
    ADD CONSTRAINT fk_detail_catch
        FOREIGN KEY (id_catch)
        REFERENCES marazul_sucre.catches(id_catch)
        ON DELETE RESTRICT
        ON UPDATE CASCADE;

ALTER TABLE marazul_sucre.sale_details
    ADD INDEX ix_detail_catch_weight
        USING BTREE (id_catch, sold_weight_kg);

SHOW CREATE TABLE marazul_sucre.sale_details;
SHOW INDEX FROM marazul_sucre.sale_details;