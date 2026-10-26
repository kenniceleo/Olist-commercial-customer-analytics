-- ============================================================
-- Olist Commercial & Customer Analytics
-- 11_create_order_mart.sql
--
-- Purpose:
-- Create the central order-level analytical mart.
--
-- Grain:
-- One row per order_id.
--
-- The mart combines:
-- - customer identity
-- - order information
-- - merchandise value
-- - freight
-- - product/seller structure
-- - payment behaviour
-- - reviews
-- - fulfilment metrics
--
-- Multi-row transactional tables are aggregated BEFORE joining
-- to prevent row multiplication and inflated metrics.
-- ============================================================


CREATE SCHEMA IF NOT EXISTS analytics;


DROP TABLE IF EXISTS analytics.order_mart CASCADE;

-- ============================================================
-- 1. ORDER-ITEM AGGREGATION
-- ============================================================

CREATE TABLE analytics.order_mart AS

WITH item_summary AS (

    SELECT
        oi.order_id,

        COUNT(*) AS item_count,

        COUNT(DISTINCT oi.product_id)
            AS distinct_products,

        COUNT(DISTINCT oi.seller_id)
            AS distinct_sellers,

        ROUND(
            SUM(oi.item_gmv),
            2
        ) AS order_gmv,

        ROUND(
            SUM(oi.freight_value),
            2
        ) AS freight_value,

        ROUND(
            SUM(oi.item_total_value),
            2
        ) AS merchandise_plus_freight,

        CASE
            WHEN SUM(oi.item_gmv) > 0

            THEN ROUND(
                (
                    SUM(oi.freight_value)
                    /
                    SUM(oi.item_gmv)
                )::NUMERIC,
                4
            )

            ELSE NULL
        END AS freight_to_gmv_ratio

    FROM staging.order_items oi

    GROUP BY oi.order_id
),

-- ============================================================
-- 2. PAYMENT AGGREGATION
-- ============================================================

ranked_payments AS (

    SELECT
        p.order_id,

        p.payment_type,
        p.payment_value,
        p.payment_installments,

        ROW_NUMBER() OVER (

            PARTITION BY p.order_id

            ORDER BY
                p.payment_value DESC,
                p.payment_sequential ASC

        ) AS payment_rank

    FROM staging.payments p

),

payment_summary AS (

    SELECT
        p.order_id,

        COUNT(*) AS payment_components,

        COUNT(DISTINCT p.payment_type)
            AS payment_methods_used,

        ROUND(
            SUM(p.payment_value),
            2
        ) AS total_payment_value,

        MAX(p.payment_installments)
            AS max_installments

    FROM staging.payments p

    GROUP BY p.order_id

),

primary_payment AS (

    SELECT
        order_id,
        payment_type AS primary_payment_type

    FROM ranked_payments

    WHERE payment_rank = 1

),

-- ============================================================
-- 3. REVIEW AGGREGATION
-- ============================================================

review_summary AS (

    SELECT
        r.order_id,

        COUNT(*) AS review_count,

        ROUND(
            AVG(r.review_score)::NUMERIC,
            2
        ) AS avg_review_score,

        MIN(r.review_score)
            AS min_review_score,

        MAX(r.review_score)
            AS max_review_score,

        MAX(
            CASE
                WHEN r.latest_review_for_order_flag
                THEN r.review_score
            END
        ) AS latest_review_score,

        MAX(
            CASE
                WHEN r.has_review_comment
                THEN 1
                ELSE 0
            END
        ) AS has_review_comment

    FROM staging.reviews r

    GROUP BY r.order_id

),

-- ============================================================
-- 4. PRODUCT / CATEGORY AGGREGATION
-- ============================================================

category_value AS (

    SELECT
        oi.order_id,
        p.product_category,

        SUM(oi.item_gmv)
            AS category_gmv

    FROM staging.order_items oi

    LEFT JOIN staging.products p
        ON oi.product_id = p.product_id

    GROUP BY
        oi.order_id,
        p.product_category

),

ranked_categories AS (

    SELECT
        order_id,
        product_category,
        category_gmv,

        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY
                category_gmv DESC,
                product_category

        ) AS category_rank

    FROM category_value

),

category_summary AS (

    SELECT
        order_id,

        COUNT(*)
            AS distinct_categories,

        MAX(
            CASE
                WHEN category_rank = 1
                THEN product_category
            END
        ) AS primary_product_category

    FROM ranked_categories

    GROUP BY order_id

),

-- ============================================================
-- 5. FINAL ORDER MART
-- ============================================================

final_order_mart AS (

    SELECT
        o.order_id,

        -- ------------------------------------
        -- Customer
        -- ------------------------------------

        o.customer_id,
        o.customer_unique_id,

        o.customer_city,
        o.customer_state,


        -- ------------------------------------
        -- Date
        -- ------------------------------------
        o.order_purchase_timestamp,

        o.purchase_date,
        o.purchase_month,
        o.purchase_year,
        o.purchase_month_number,


        -- ------------------------------------
        -- Status
        -- ------------------------------------

        o.order_status,
        o.is_delivered,


        -- ------------------------------------
        -- Commercial
        -- ------------------------------------

        i.order_gmv,
        i.freight_value,
        i.merchandise_plus_freight,

        i.freight_to_gmv_ratio,

        i.item_count,
        i.distinct_products,
        i.distinct_sellers,

        c.distinct_categories,
        c.primary_product_category,


        -- ------------------------------------
        -- Payments
        -- ------------------------------------

        ps.total_payment_value,

        ps.payment_components,
        ps.payment_methods_used,

        pp.primary_payment_type,

        ps.max_installments,


        -- ------------------------------------
        -- Customer experience
        -- ------------------------------------

        rs.review_count,
        rs.avg_review_score,
        rs.latest_review_score,
        rs.min_review_score,
        rs.max_review_score,
        rs.has_review_comment,


        -- ------------------------------------
        -- Fulfilment
        -- ------------------------------------

        o.seller_processing_days,
        o.delivery_days,
        o.carrier_delivery_days,

        o.days_vs_estimated_delivery,
        o.late_delivery_flag,


        -- ------------------------------------
        -- Validity
        -- ------------------------------------

        o.valid_approval_timestamp,
        o.valid_carrier_timestamp,
        o.valid_delivery_timestamp


    FROM staging.orders o

    LEFT JOIN item_summary i
        ON o.order_id = i.order_id

    LEFT JOIN payment_summary ps
        ON o.order_id = ps.order_id

    LEFT JOIN primary_payment pp
        ON o.order_id = pp.order_id

    LEFT JOIN review_summary rs
        ON o.order_id = rs.order_id

    LEFT JOIN category_summary c
        ON o.order_id = c.order_id

)


SELECT *
FROM final_order_mart;


ALTER TABLE analytics.order_mart
ADD CONSTRAINT pk_order_mart
PRIMARY KEY (order_id);


CREATE INDEX idx_order_mart_customer
ON analytics.order_mart (customer_unique_id);


CREATE INDEX idx_order_mart_purchase_date
ON analytics.order_mart (purchase_date);


CREATE INDEX idx_order_mart_category
ON analytics.order_mart (primary_product_category);


CREATE INDEX idx_order_mart_state
ON analytics.order_mart (customer_state);