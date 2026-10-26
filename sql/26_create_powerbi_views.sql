-- ============================================================
-- Olist Commercial & Customer Analytics
-- 26_create_powerbi_views.sql
--
-- Purpose:
-- Create a clean presentation layer for Power BI.
--
-- Business logic remains in the validated analytics marts.
-- These views provide a stable BI-facing interface without
-- duplicating analytical tables.
-- ============================================================


-- ============================================================
-- 1. BI SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS bi;


-- ============================================================
-- 2. ORDER DASHBOARD VIEW
--
-- Grain: 1 row per order
--
-- Primary use:
-- - Executive commercial KPIs
-- - Monthly GMV / order trends
-- - Category analysis
-- - Geography
-- - Payment behaviour
-- - Fulfilment / review analysis
-- ============================================================

CREATE OR REPLACE VIEW bi.order_dashboard AS

SELECT
    *
FROM analytics.order_mart;



-- ============================================================
-- 3. CUSTOMER DASHBOARD VIEW
--
-- Grain: 1 row per customer_unique_id
--
-- Primary use:
-- - Repeat behaviour
-- - Customer value
-- - First-order characteristics
-- - Return behaviour
-- - Customer-level segmentation
-- ============================================================

CREATE OR REPLACE VIEW bi.customer_dashboard AS

SELECT
    c.*,

    s.customer_segment,
    s.customer_value_band

FROM analytics.customer_mart c

LEFT JOIN analytics.customer_segments s
    ON c.customer_unique_id = s.customer_unique_id;



-- ============================================================
-- 4. COHORT DASHBOARD VIEW
--
-- Grain:
-- cohort_month x months_since_first_purchase
--
-- Primary use:
-- - Cohort retention heatmap
-- - Retention curves
-- - Cohort-size filtering
-- ============================================================

CREATE OR REPLACE VIEW bi.cohort_dashboard AS

SELECT
    *
FROM analytics.cohort_retention;



-- ============================================================
-- 5. SELLER DASHBOARD VIEW
--
-- Grain: 1 row per seller
--
-- Primary use:
-- - Seller commercial performance
-- - Seller concentration
-- - Processing performance
-- - Late-delivery performance
-- - Seller review performance
-- ============================================================

CREATE OR REPLACE VIEW bi.seller_dashboard AS

SELECT
    *
FROM analytics.seller_mart;