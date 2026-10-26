-- ============================================================
-- Olist Commercial & Customer Analytics
-- 01_create_raw_schema.sql
--
-- Purpose:
-- Create raw tables mirroring the original Olist CSV files.
-- No cleaning or transformation is performed at this stage.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;


-- ------------------------------------------------------------
-- Customers
-- Grain: one row per order-specific customer_id
-- customer_unique_id identifies the underlying customer
-- across different orders.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.customers;

CREATE TABLE raw.customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state VARCHAR(2)
);


-- ------------------------------------------------------------
-- Orders
-- Grain: one row per order
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.orders;

CREATE TABLE raw.orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


-- ------------------------------------------------------------
-- Order Items
-- Grain: one row per item within an order
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.order_items;

CREATE TABLE raw.order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2)
);


-- ------------------------------------------------------------
-- Payments
-- Grain: one row per payment component for an order
-- An order may have multiple payment records.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.order_payments;

CREATE TABLE raw.order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC(12,2)
);


-- ------------------------------------------------------------
-- Reviews
-- Grain: review records associated with orders
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.order_reviews;

CREATE TABLE raw.order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- ------------------------------------------------------------
-- Products
-- Grain: one row per product
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.products;

CREATE TABLE raw.products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);


-- ------------------------------------------------------------
-- Sellers
-- Grain: one row per seller
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.sellers;

CREATE TABLE raw.sellers (
    seller_id TEXT,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state VARCHAR(2)
);


-- ------------------------------------------------------------
-- Geolocation
-- Multiple latitude/longitude observations may exist
-- for the same ZIP-code prefix.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.geolocation;

CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city TEXT,
    geolocation_state VARCHAR(2)
);


-- ------------------------------------------------------------
-- Product Category Translation
-- ------------------------------------------------------------

DROP TABLE IF EXISTS raw.product_category_translation;

CREATE TABLE raw.product_category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);