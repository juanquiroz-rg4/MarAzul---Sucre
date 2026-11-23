CREATE ROLE 'rol_inspector_aunap', 'rol_operador_muelle', 'rol_gestor_comercial';

CREATE USER 'usr_inspector1'@'localhost' IDENTIFIED BY 'Inspector_Juan_2026!';
CREATE USER 'usr_operador1'@'localhost' IDENTIFIED BY 'Operador_Juan_2026!';
CREATE USER 'usr_comercial1'@'localhost' IDENTIFIED BY 'Comercial_Juan_2026!';

-- 1. Lectura para inspeccion.
GRANT SELECT ON marazul_sucre.trips TO 'rol_inspector_aunap';
GRANT SELECT ON marazul_sucre.catches TO 'rol_inspector_aunap';
GRANT SELECT ON marazul_sucre.species TO 'rol_inspector_aunap';
GRANT 'rol_inspector_aunap' TO 'usr_inspector1'@'localhost';
SET DEFAULT ROLE 'rol_inspector_aunap' TO 'usr_inspector1'@'localhost';

-- 2. Minimo privilegio para dos usuarios distintos.
GRANT INSERT, UPDATE ON marazul_sucre.trips TO 'rol_operador_muelle';
GRANT INSERT, UPDATE ON marazul_sucre.catches TO 'rol_operador_muelle';
GRANT 'rol_operador_muelle' TO 'usr_operador1'@'localhost';
SET DEFAULT ROLE 'rol_operador_muelle' TO 'usr_operador1'@'localhost';

GRANT INSERT, UPDATE ON marazul_sucre.sales TO 'rol_gestor_comercial';
GRANT INSERT, UPDATE ON marazul_sucre.sale_details TO 'rol_gestor_comercial';
GRANT 'rol_gestor_comercial' TO 'usr_comercial1'@'localhost';
SET DEFAULT ROLE 'rol_gestor_comercial' TO 'usr_comercial1'@'localhost';

-- 3. Concesion temporal y revocacion de DELETE exigidas por el reto.
GRANT DELETE ON marazul_sucre.sales TO 'rol_gestor_comercial';
SHOW GRANTS FOR 'rol_gestor_comercial';
REVOKE DELETE ON marazul_sucre.sales FROM 'rol_gestor_comercial';

-- Verificacion desde la conexion administradora.
-- Los roles sin host explicito usan %.
SELECT GRANTEE, TABLE_SCHEMA, TABLE_NAME, PRIVILEGE_TYPE
FROM information_schema.TABLE_PRIVILEGES
WHERE GRANTEE = CONCAT(CHAR(39), 'rol_gestor_comercial', CHAR(39), '@', CHAR(39), '%', CHAR(39))
  AND TABLE_SCHEMA = 'marazul_sucre'
ORDER BY TABLE_NAME, PRIVILEGE_TYPE;

-- Debe devolver cero.
SELECT COUNT(*) AS remaining_delete_privileges
FROM information_schema.TABLE_PRIVILEGES
WHERE GRANTEE = CONCAT(CHAR(39), 'rol_gestor_comercial', CHAR(39), '@', CHAR(39), '%', CHAR(39))
  AND TABLE_SCHEMA = 'marazul_sucre' AND TABLE_NAME = 'sales'
  AND PRIVILEGE_TYPE = 'DELETE';

SHOW GRANTS FOR 'usr_operador1'@'localhost' USING 'rol_operador_muelle';
SHOW GRANTS FOR 'usr_comercial1'@'localhost' USING 'rol_gestor_comercial';

SELECT COUNT(*) AS remaining_delete_privileges
FROM information_schema.TABLE_PRIVILEGES
WHERE GRANTEE = CONCAT(
    CHAR(39), 'rol_gestor_comercial', CHAR(39),
    '@', CHAR(39), '%', CHAR(39)
)
  AND TABLE_SCHEMA = 'marazul_sucre'
  AND TABLE_NAME = 'sales'
  AND PRIVILEGE_TYPE = 'DELETE';
  
  -- usr_Inspector1
  
  SELECT CURRENT_USER() AS current_account,
       CURRENT_ROLE() AS active_role;

SELECT * FROM marazul_sucre.catches LIMIT 10;

UPDATE marazul_sucre.catches
SET weight_kg = 1
WHERE 1 = 0;
  
  -- usr_operador1

SELECT CURRENT_USER() AS current_account,
       CURRENT_ROLE() AS active_role;

SHOW GRANTS FOR CURRENT_USER()
USING 'rol_operador_muelle';

UPDATE marazul_sucre.catches
SET weight_kg = 1
WHERE 1 = 0;

-- usr_comercial1

SELECT CURRENT_USER() AS current_account,
       CURRENT_ROLE() AS active_role;

SHOW GRANTS FOR CURRENT_USER()
USING 'rol_gestor_comercial';

DELETE FROM marazul_sucre.sales
WHERE 1 = 0;