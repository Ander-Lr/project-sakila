-- ============================================================
--  EXTENSIÓN DE SAKILA
--  Autenticación con Google OAuth + JWT, roles, revocación
--  de tokens y auditoría de eventos.
--  Este script es ADITIVO: no elimina ni modifica datos
--  existentes de Sakila, solo agrega columnas y tablas nuevas.
-- ============================================================

USE sakila;

-- ------------------------------------------------------------
-- 1) Disponibilidad de películas
--    Sakila no trae "active" en film (solo customer/staff lo
--    tienen). Lo necesitas para "Activar o desactivar registros".
-- ------------------------------------------------------------
ALTER TABLE film
  ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE AFTER rating;

-- ------------------------------------------------------------
-- 2) Usuarios de la aplicación (login con Google OAuth)
--    Independiente de customer/staff para no arrastrar columnas
--    obligatorias (address_id, store_id) que no aplican al login.
--    Se enlaza opcionalmente a customer o staff según el rol.
-- ------------------------------------------------------------
CREATE TABLE app_user (
  user_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  google_id      VARCHAR(255) NOT NULL,          -- "sub" devuelto por Google
  email          VARCHAR(150) NOT NULL,
  full_name      VARCHAR(150) NOT NULL,
  role           ENUM('ADMIN','CUSTOMER') NOT NULL DEFAULT 'CUSTOMER',
  customer_id    SMALLINT UNSIGNED DEFAULT NULL, -- si role = CUSTOMER
  staff_id       TINYINT UNSIGNED DEFAULT NULL,  -- si role = ADMIN
  active         BOOLEAN NOT NULL DEFAULT TRUE,
  token_version  INT UNSIGNED NOT NULL DEFAULT 1, -- invalida todos los JWT previos al incrementarse
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login     DATETIME DEFAULT NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_google_id (google_id),
  UNIQUE KEY uq_email (email),
  KEY idx_fk_customer_id (customer_id),
  KEY idx_fk_staff_id (staff_id),
  CONSTRAINT fk_appuser_customer FOREIGN KEY (customer_id)
      REFERENCES customer (customer_id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_appuser_staff FOREIGN KEY (staff_id)
      REFERENCES staff (staff_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 3) Revocación de tokens (logout real, no solo del navegador)
--    jti = identificador único del token (UUID), incluido como
--    claim al generar el JWT. Al hacer logout, se inserta aquí
--    y el filtro de seguridad lo rechaza aunque la firma sea válida.
-- ------------------------------------------------------------
CREATE TABLE revoked_token (
  jti         VARCHAR(36) NOT NULL,
  user_id     BIGINT UNSIGNED NOT NULL,
  revoked_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at  DATETIME NOT NULL,   -- permite purgar filas ya vencidas
  PRIMARY KEY (jti),
  KEY idx_fk_user_id (user_id),
  CONSTRAINT fk_revoked_user FOREIGN KEY (user_id)
      REFERENCES app_user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 4) Sesiones activas (opcional pero recomendado)
--    Útil para listar dispositivos conectados o forzar el cierre
--    de todas las sesiones de un usuario.
-- ------------------------------------------------------------
CREATE TABLE active_session (
  session_id  VARCHAR(36) NOT NULL,  -- jti del access token
  user_id     BIGINT UNSIGNED NOT NULL,
  issued_at   DATETIME NOT NULL,
  expires_at  DATETIME NOT NULL,
  ip_address  VARCHAR(45) DEFAULT NULL,
  user_agent  VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (session_id),
  KEY idx_fk_user_id (user_id),
  CONSTRAINT fk_session_user FOREIGN KEY (user_id)
      REFERENCES app_user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 5) Auditoría de eventos de negocio
--    (login, alquileres, devoluciones, cambios de stock, errores…)
--    Complementa -no reemplaza- los logs de archivo (Logback).
-- ------------------------------------------------------------
CREATE TABLE audit_log (
  log_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- en UTC
  level       ENUM('INFO','WARN','ERROR') NOT NULL DEFAULT 'INFO',
  event_type  VARCHAR(50) NOT NULL,     -- LOGIN_SUCCESS, LOGIN_FAILED, RENTAL_CREATED, RETURN_REGISTERED, STOCK_UPDATED, TOKEN_REVOKED...
  user_id     BIGINT UNSIGNED DEFAULT NULL,
  module      VARCHAR(100) DEFAULT NULL, -- ruta o módulo, ej. /api/rentals
  result      VARCHAR(20) DEFAULT NULL,  -- SUCCESS / FAILURE
  message     VARCHAR(255) DEFAULT NULL, -- mensaje breve, nunca datos sensibles
  PRIMARY KEY (log_id),
  KEY idx_fk_user_id (user_id),
  KEY idx_event_type (event_type),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
      REFERENCES app_user (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 6) Vista de disponibilidad de ejemplares
--    Sakila calcula disponibilidad viendo si existe un rental
--    sin return_date para ese inventory_id (no hace falta una
--    columna de estado propia, evita datos duplicados/inconsistentes).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW inventory_availability AS
SELECT
  i.inventory_id,
  i.film_id,
  i.store_id,
  (i.active = TRUE AND NOT EXISTS (
    SELECT 1 FROM rental r
    WHERE r.inventory_id = i.inventory_id
      AND r.return_date IS NULL
  )) AS available
FROM inventory i;

-- Índice de apoyo para acelerar esa verificación de disponibilidad
CREATE INDEX idx_rental_inventory_open
  ON rental (inventory_id, return_date);

-- ------------------------------------------------------------
-- 7) Staff "sistema" para alquileres registrados desde la app
--    rental.staff_id es NOT NULL en Sakila. Cuando un cliente
--    alquila desde la web (no un empleado físico), se usa un
--    staff_id "de sistema". Ajusta el ID según lo que traiga
--    sakila-data.sql (usualmente 1 y 2 ya existen).
-- ------------------------------------------------------------
-- Ejemplo: revisar staff existentes
-- SELECT staff_id, first_name, last_name, store_id FROM staff;

-- Si necesitas uno dedicado para operaciones automáticas del sistema:
-- INSERT INTO staff (first_name, last_name, address_id, email, store_id, active, username, password)
-- VALUES ('Sistema', 'App', 1, 'sistema@app.local', 1, TRUE, 'sistema', NULL);

-- ------------------------------------------------------------
-- 8) Semilla de un administrador inicial (opcional)
--    En la práctica, el primer login con Google determina el
--    rol vía DB (por ejemplo, comparando el email contra una
--    whitelist de administradores). Aquí un ejemplo manual:
-- ------------------------------------------------------------
-- INSERT INTO app_user (google_id, email, full_name, role, staff_id, active)
-- VALUES ('GOOGLE_SUB_AQUI', 'admin@tuempresa.com', 'Nombre Admin', 'ADMIN', 1, TRUE);
ALTER TABLE app_user MODIFY COLUMN role ENUM('ADMIN', 'CUSTOMER') NOT NULL DEFAULT 'CUSTOMER';

-- google_id ya no puede ser obligatorio (los usuarios de email/contraseña no tienen uno)
ALTER TABLE app_user
  MODIFY COLUMN google_id VARCHAR(255) NULL;

-- Nueva columna para el hash de la contraseña (nunca la contraseña en texto plano)
ALTER TABLE app_user
  ADD COLUMN password_hash VARCHAR(255) NULL AFTER full_name;

-- Para saber cómo se registró cada usuario y validar la lógica correcta al iniciar sesión
ALTER TABLE app_user
  ADD COLUMN auth_provider ENUM('GOOGLE','LOCAL') NOT NULL DEFAULT 'LOCAL' AFTER password_hash;


ALTER TABLE app_user
  ADD COLUMN status ENUM('PENDING', 'ACTIVE') NOT NULL DEFAULT 'PENDING' AFTER auth_provider,
  ADD COLUMN verification_code VARCHAR(255) NULL AFTER status,
  ADD COLUMN verification_code_expires_at DATETIME NULL AFTER verification_code;

ALTER TABLE inventory ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;

-- Eliminar campos innecesarios
ALTER TABLE staff DROP COLUMN username;

ALTER TABLE staff DROP COLUMN password;

ALTER TABLE rental MODIFY staff_id TINYINT UNSIGNED NULL;

ALTER TABLE payment MODIFY staff_id TINYINT UNSIGNED NULL;

ALTER TABLE payment
  ADD COLUMN payment_method VARCHAR(20) NOT NULL DEFAULT 'CARD',
  ADD COLUMN card_last4 CHAR(4) DEFAULT NULL,
  ADD COLUMN transaction_ref VARCHAR(36) DEFAULT NULL;