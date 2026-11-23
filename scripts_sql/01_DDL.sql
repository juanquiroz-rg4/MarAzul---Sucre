-- MarAzul Sucre 
CREATE DATABASE IF NOT EXISTS marazul_sucre
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE marazul_sucre;

CREATE TABLE organizations (
  id_organization INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tax_id VARCHAR(25) NOT NULL,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(25),
  CONSTRAINT uq_organization_tax_id UNIQUE (tax_id)
) ENGINE=InnoDB;

CREATE TABLE sales_staff (
  id_staff INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document VARCHAR(25) NOT NULL,
  first_names VARCHAR(80) NOT NULL,
  last_names VARCHAR(80) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_staff_document UNIQUE (document),
  CONSTRAINT ck_staff_active CHECK (active IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE fishermen (
  id_fisherman INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document VARCHAR(25) NOT NULL,
  first_names VARCHAR(80) NOT NULL,
  last_names VARCHAR(80) NOT NULL,
  phone VARCHAR(25),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_fisherman_document UNIQUE (document),
  CONSTRAINT ck_fisherman_active CHECK (active IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE vessels (
  id_vessel INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  registration VARCHAR(40) NOT NULL,
  name VARCHAR(100) NOT NULL,
  cargo_capacity_kg DECIMAL(12,3) NOT NULL,
  CONSTRAINT uq_vessel_registration UNIQUE (registration),
  CONSTRAINT ck_vessel_capacity CHECK (cargo_capacity_kg > 0)
) ENGINE=InnoDB;

-- ALTER requested by the case.
ALTER TABLE vessels
  ADD COLUMN autonomy_category VARCHAR(25) NOT NULL DEFAULT 'INSHORE',
  ADD CONSTRAINT ck_vessel_category CHECK
    (autonomy_category IN ('INSHORE','INTERMEDIATE_ARTISANAL','OFFSHORE'));

CREATE TABLE fishing_zones (
  id_zone INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  description VARCHAR(500)
) ENGINE=InnoDB;

CREATE TABLE species (
  id_species INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  common_name VARCHAR(100) NOT NULL,
  scientific_name VARCHAR(150) NOT NULL,
  minimum_size_cm DECIMAL(7,2) NOT NULL,
  CONSTRAINT uq_species_scientific UNIQUE (scientific_name),
  CONSTRAINT ck_species_size CHECK (minimum_size_cm >= 0)
) ENGINE=InnoDB;

CREATE TABLE buyers (
  id_buyer INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document_type VARCHAR(15) NOT NULL,
  document VARCHAR(25) NOT NULL,
  legal_name VARCHAR(150) NOT NULL,
  phone VARCHAR(25),
  email VARCHAR(254),
  CONSTRAINT uq_buyer_document UNIQUE (document_type,document)
) ENGINE=InnoDB;

CREATE TABLE trips (
  id_trip INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_organization INT UNSIGNED NOT NULL,
  id_coordinator INT UNSIGNED NOT NULL,
  id_vessel INT UNSIGNED NOT NULL,
  id_zone INT UNSIGNED NOT NULL,
  departure_date DATE NOT NULL,
  departure_time TIME NOT NULL,
  return_date DATE,
  arrival_time TIME,
  status VARCHAR(15) NOT NULL DEFAULT 'PLANNED',
  CONSTRAINT fk_trip_organization FOREIGN KEY (id_organization)
    REFERENCES organizations(id_organization) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_trip_coordinator FOREIGN KEY (id_coordinator)
    REFERENCES sales_staff(id_staff) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_trip_vessel FOREIGN KEY (id_vessel)
    REFERENCES vessels(id_vessel) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_trip_zone FOREIGN KEY (id_zone)
    REFERENCES fishing_zones(id_zone) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_trip_status CHECK
    (status IN ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED')),
  CONSTRAINT ck_trip_dates CHECK
    ((return_date IS NULL AND arrival_time IS NULL) OR
     (return_date IS NOT NULL AND arrival_time IS NOT NULL AND
      TIMESTAMP(return_date,arrival_time) >= TIMESTAMP(departure_date,departure_time))),
  CONSTRAINT ck_trip_completed CHECK
    (status <> 'COMPLETED' OR return_date IS NOT NULL),
  INDEX ix_trip_vessel_departure (id_vessel,departure_date),
  INDEX ix_trip_zone_return (id_zone,return_date)
) ENGINE=InnoDB;

CREATE TABLE trip_crew (
  id_trip_crew INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_trip INT UNSIGNED NOT NULL,
  id_fisherman INT UNSIGNED NOT NULL,
  role_on_board VARCHAR(20) NOT NULL DEFAULT 'CREW_MEMBER',
  UNIQUE (id_trip,id_fisherman),
  CONSTRAINT fk_crew_trip FOREIGN KEY (id_trip)
    REFERENCES trips(id_trip) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_crew_fisherman FOREIGN KEY (id_fisherman)
    REFERENCES fishermen(id_fisherman) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_crew_role CHECK (role_on_board IN ('IN_CHARGE','CREW_MEMBER')),
  INDEX ix_crew_fisherman (id_fisherman,id_trip)
) ENGINE=InnoDB;

CREATE TABLE catches (
  id_catch INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_trip INT UNSIGNED NOT NULL,
  id_species INT UNSIGNED NOT NULL,
  landing_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  weight_kg DECIMAL(12,3) NOT NULL,
  piece_count INT UNSIGNED NOT NULL,
  average_size_cm DECIMAL(7,2),
  CONSTRAINT fk_catch_trip FOREIGN KEY (id_trip)
    REFERENCES trips(id_trip) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_catch_species FOREIGN KEY (id_species)
    REFERENCES species(id_species) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_catch_weight CHECK (weight_kg > 0),
  CONSTRAINT ck_catch_pieces CHECK (piece_count > 0),
  CONSTRAINT ck_catch_size CHECK (average_size_cm IS NULL OR average_size_cm > 0),
  INDEX ix_catch_species_landing (id_species,landing_date),
  INDEX ix_catch_trip (id_trip)
) ENGINE=InnoDB;

CREATE TABLE sales (
  id_sale INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_buyer INT UNSIGNED NOT NULL,
  sale_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_commercial_manager INT UNSIGNED NOT NULL,
  CONSTRAINT fk_sale_manager FOREIGN KEY (id_commercial_manager)
    REFERENCES sales_staff(id_staff) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sale_buyer FOREIGN KEY (id_buyer)
    REFERENCES buyers(id_buyer) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX ix_sale_buyer_date (id_buyer,sale_date)
) ENGINE=InnoDB;

CREATE TABLE sale_details (
  id_detail INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_sale INT UNSIGNED NOT NULL,
  id_catch INT UNSIGNED NOT NULL,
  sold_weight_kg DECIMAL(12,3) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL COMMENT 'COP per kilogram',
  CONSTRAINT fk_detail_sale FOREIGN KEY (id_sale)
    REFERENCES sales(id_sale) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_detail_catch FOREIGN KEY (id_catch)
    REFERENCES catches(id_catch) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_detail_weight CHECK (sold_weight_kg > 0),
  CONSTRAINT ck_detail_price CHECK (unit_price > 0),
  CONSTRAINT uq_detail_sale_catch UNIQUE (id_sale,id_catch)
) ENGINE=InnoDB;

ALTER TABLE sale_details ADD INDEX ix_detail_catch_weight
  USING BTREE (id_catch,sold_weight_kg);

CREATE TABLE sales_audit (
  id_audit BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  change_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  db_user VARCHAR(288) NOT NULL,
  id_detail INT UNSIGNED NOT NULL,
  previous_weight DECIMAL(12,3) NOT NULL,
  new_weight DECIMAL(12,3) NOT NULL,
  previous_price DECIMAL(12,2) NOT NULL,
  new_price DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_audit_detail FOREIGN KEY (id_detail)
    REFERENCES sale_details(id_detail) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX ix_audit_detail_date (id_detail,change_date)
) ENGINE=InnoDB;

CREATE TABLE organization_fisherman (
  id_membership INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_organization INT UNSIGNED NOT NULL,
  id_fisherman INT UNSIGNED NOT NULL,
  join_date DATE NOT NULL,
  leave_date DATE,
  UNIQUE (id_organization,id_fisherman,join_date),
  CONSTRAINT fk_membership_organization FOREIGN KEY (id_organization)
    REFERENCES organizations(id_organization) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_membership_fisherman FOREIGN KEY (id_fisherman)
    REFERENCES fishermen(id_fisherman) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_membership_dates CHECK (leave_date IS NULL OR leave_date >= join_date)
) ENGINE=InnoDB;

CREATE TABLE organization_vessel (
  id_vessel_link INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_organization INT UNSIGNED NOT NULL,
  id_vessel INT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  UNIQUE (id_organization,id_vessel,start_date),
  CONSTRAINT fk_link_organization FOREIGN KEY (id_organization)
    REFERENCES organizations(id_organization) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_link_vessel FOREIGN KEY (id_vessel)
    REFERENCES vessels(id_vessel) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_link_dates CHECK (end_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

CREATE TABLE product_classifications (
  id_classification INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  description VARCHAR(300),
  CONSTRAINT uq_classification_name UNIQUE (name)
) ENGINE=InnoDB;

CREATE TABLE product_lots (
  id_lot INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_catch INT UNSIGNED NOT NULL,
  id_classification INT UNSIGNED NOT NULL,
  lot_code VARCHAR(40) NOT NULL,
  initial_weight_kg DECIMAL(12,3) NOT NULL,
  classification_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_lot_code UNIQUE (lot_code),
  CONSTRAINT fk_lot_catch FOREIGN KEY (id_catch)
    REFERENCES catches(id_catch) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lot_classification FOREIGN KEY (id_classification)
    REFERENCES product_classifications(id_classification) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_lot_weight CHECK (initial_weight_kg > 0)
) ENGINE=InnoDB;

CREATE TABLE warehouses (
  id_warehouse INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_organization INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(200) NOT NULL,
  CONSTRAINT uq_warehouse_name UNIQUE (id_organization,name),
  CONSTRAINT fk_warehouse_organization FOREIGN KEY (id_organization)
    REFERENCES organizations(id_organization) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventory_movements (
  id_movement BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_lot INT UNSIGNED NOT NULL,
  id_source_warehouse INT UNSIGNED,
  id_destination_warehouse INT UNSIGNED,
  id_responsible INT UNSIGNED NOT NULL,
  weight_kg DECIMAL(12,3) NOT NULL,
  movement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_movement_lot FOREIGN KEY (id_lot)
    REFERENCES product_lots(id_lot) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_movement_source FOREIGN KEY (id_source_warehouse)
    REFERENCES warehouses(id_warehouse) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_movement_destination FOREIGN KEY (id_destination_warehouse)
    REFERENCES warehouses(id_warehouse) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_movement_responsible FOREIGN KEY (id_responsible)
    REFERENCES sales_staff(id_staff) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_movement_weight CHECK (weight_kg > 0),
  CONSTRAINT ck_movement_route CHECK (
    (id_source_warehouse IS NOT NULL OR id_destination_warehouse IS NOT NULL)
    AND (id_source_warehouse IS NULL OR id_destination_warehouse IS NULL
         OR id_source_warehouse <> id_destination_warehouse)
  ),
  INDEX ix_movement_lot_date (id_lot,movement_date)
) ENGINE=InnoDB;

CREATE TABLE catch_audit (
  id_catch_audit BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_catch INT UNSIGNED NOT NULL,
  change_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  db_user VARCHAR(288) NOT NULL,
  operation VARCHAR(10) NOT NULL,
  previous_data JSON,
  new_data JSON NOT NULL,
  CONSTRAINT fk_catch_audit FOREIGN KEY (id_catch)
    REFERENCES catches(id_catch) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_catch_audit_operation CHECK (operation IN ('INSERT','UPDATE')),
  INDEX ix_catch_audit_date (id_catch,change_date)
) ENGINE=InnoDB;

CREATE TABLE trip_observations (
  id_observation INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_trip INT UNSIGNED NOT NULL,
  date_time DATETIME NOT NULL,
  description TEXT NOT NULL,
  CONSTRAINT fk_observation_trip FOREIGN KEY (id_trip)
    REFERENCES trips(id_trip) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX ix_observation_trip_date (id_trip,date_time)
) ENGINE=InnoDB;

CREATE TABLE roles (
  id_role INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL,
  description VARCHAR(250),
  CONSTRAINT uq_role_name UNIQUE (role_name)
) ENGINE=InnoDB;

CREATE TABLE users (
  id_user INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  status VARCHAR(10) NOT NULL DEFAULT 'INACTIVE',
  id_role INT UNSIGNED NOT NULL,
  id_staff INT UNSIGNED NOT NULL,
  CONSTRAINT uq_user_username UNIQUE (username),
  CONSTRAINT uq_user_staff UNIQUE (id_staff),
  CONSTRAINT ck_user_status CHECK (status IN ('ACTIVE','INACTIVE')),
  CONSTRAINT fk_user_role FOREIGN KEY (id_role)
    REFERENCES roles(id_role) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_user_staff FOREIGN KEY (id_staff)
    REFERENCES sales_staff(id_staff) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
