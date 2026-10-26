-- ============================================================
-- Olist Commercial & Customer Analytics
-- 04_clean_customers.sql
--
-- Purpose:
-- Create the staging layer and clean customer records.
--
-- Grain:
-- One row per order-specific customer_id.
--
-- Important:
-- customer_unique_id represents the persistent customer and
-- must be used for repeat-purchase / retention analysis.
-- ============================================================


-- Re-running this file resets the entire staging layer.
DROP SCHEMA IF EXISTS staging CASCADE;

CREATE SCHEMA staging;


-- ============================================================
-- CUSTOMERS
-- ============================================================

CREATE TABLE staging.customers AS

SELECT
    TRIM(customer_id) AS customer_id,
    TRIM(customer_unique_id) AS customer_unique_id,

    customer_zip_code_prefix,

    NULLIF(
        TRIM(customer_city),
        ''
    ) AS customer_city,

    NULLIF(
        UPPER(TRIM(customer_state)),
        ''
    ) AS customer_state

FROM raw.customers;


-- Primary key:
-- customer_id was confirmed unique in the raw-data audit.
ALTER TABLE staging.customers
ADD CONSTRAINT pk_staging_customers
PRIMARY KEY (customer_id);


-- Useful for repeat-purchase queries.
CREATE INDEX idx_staging_customers_unique_customer
ON staging.customers (customer_unique_id);


-- Useful for geographic analysis.
CREATE INDEX idx_staging_customers_state
ON staging.customers (customer_state);