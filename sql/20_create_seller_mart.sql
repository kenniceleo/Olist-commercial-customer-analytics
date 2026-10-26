-- ============================================================
-- Olist Commercial & Customer Analytics
-- 19_create_seller_mart.sql
--
-- Purpose:
-- Create seller-level commercial and operational metrics.
--
-- Grain:
-- One row per seller_id.
--
-- Attribution rule:
-- Commercial metrics can use all seller-specific item records.
--
-- Order-level fulfilment / review metrics use single-seller
-- orders only to avoid attributing an order-level outcome to
-- multiple sellers.
-- ============================================================


DROP TABLE IF EXISTS analytics.seller_mart CASCADE;


CREATE TABLE analytics.seller_mart AS


WITH seller_item_base AS (

    SELECT
        i.seller_id,

        i.order_id,

        i.product_id,

        p.product_category,

        i.item_gmv,

        i.freight_value

    FROM staging.order_items i

    LEFT JOIN staging.products p
        ON i.product_id = p.product_id

    INNER JOIN analytics.order_mart o
        ON i.order_id = o.order_id

    WHERE o.is_delivered = TRUE

),


-- ------------------------------------------------------------
-- One row per seller + order
-- ------------------------------------------------------------

seller_order_summary AS (

    SELECT
        seller_id,

        order_id,

        COUNT(*) AS seller_items_in_order,

        COUNT(
            DISTINCT product_id
        ) AS seller_products_in_order,

        ROUND(
            SUM(item_gmv),
            2
        ) AS seller_order_gmv,

        ROUND(
            SUM(freight_value),
            2
        ) AS seller_order_freight

    FROM seller_item_base

    GROUP BY
        seller_id,
        order_id

),


-- ------------------------------------------------------------
-- Product/category breadth per seller
-- ------------------------------------------------------------

seller_catalog_summary AS (

    SELECT
        seller_id,

        COUNT(
            DISTINCT product_id
        ) AS distinct_products_sold,

        COUNT(
            DISTINCT product_category
        ) AS distinct_categories_sold

    FROM seller_item_base

    GROUP BY seller_id

),


-- ------------------------------------------------------------
-- Core commercial seller metrics
-- ------------------------------------------------------------

seller_commercial AS (

    SELECT
        so.seller_id,

        COUNT(
            DISTINCT so.order_id
        ) AS delivered_orders,

        SUM(
            so.seller_items_in_order
        ) AS items_sold,

        COUNT(
            DISTINCT o.customer_unique_id
        ) AS unique_customers,

        ROUND(
            SUM(so.seller_order_gmv),
            2
        ) AS seller_gmv,

        ROUND(
            SUM(so.seller_order_freight),
            2
        ) AS seller_freight_value,

        ROUND(
            AVG(so.seller_order_gmv),
            2
        ) AS avg_seller_gmv_per_order,

        COUNT(*) FILTER (
            WHERE o.distinct_sellers > 1
        ) AS multi_seller_orders

    FROM seller_order_summary so

    INNER JOIN analytics.order_mart o
        ON so.order_id = o.order_id

    GROUP BY so.seller_id

),


-- ------------------------------------------------------------
-- Seller operational metrics
--
-- Only single-seller orders are used for attribution.
-- ------------------------------------------------------------

seller_operations AS (

    SELECT
        so.seller_id,


        COUNT(*) AS single_seller_orders,


        COUNT(
            o.seller_processing_days
        ) AS orders_with_processing_metric,


        ROUND(
            AVG(
                o.seller_processing_days
            ),
            2
        ) AS avg_seller_processing_days,


        COUNT(
            o.delivery_days
        ) AS orders_with_delivery_metric,


        ROUND(
            AVG(
                o.delivery_days
            ),
            2
        ) AS avg_delivery_days,


        COUNT(
            o.late_delivery_flag
        ) AS orders_with_lateness_metric,


        COUNT(*) FILTER (
            WHERE o.late_delivery_flag = TRUE
        ) AS late_orders,


        ROUND(

            100.0

            * COUNT(*) FILTER (
                WHERE o.late_delivery_flag = TRUE
            )

            / NULLIF(
                COUNT(
                    o.late_delivery_flag
                ),
                0
            ),

            2

        ) AS late_delivery_rate_pct,


        COUNT(
            o.latest_review_score
        ) AS orders_with_review,


        ROUND(
            AVG(
                o.latest_review_score
            ),
            2
        ) AS avg_review_score


    FROM seller_order_summary so

    INNER JOIN analytics.order_mart o
        ON so.order_id = o.order_id

    WHERE o.distinct_sellers = 1

    GROUP BY so.seller_id

),


seller_base AS (

    SELECT
        s.seller_id,

        s.seller_city,
        s.seller_state,

        c.delivered_orders,
        c.items_sold,
        c.unique_customers,

        c.seller_gmv,
        c.seller_freight_value,
        c.avg_seller_gmv_per_order,

        cat.distinct_products_sold,
        cat.distinct_categories_sold,

        c.multi_seller_orders,

        op.single_seller_orders,

        op.orders_with_processing_metric,
        op.avg_seller_processing_days,

        op.orders_with_delivery_metric,
        op.avg_delivery_days,

        op.orders_with_lateness_metric,
        op.late_orders,
        op.late_delivery_rate_pct,

        op.orders_with_review,
        op.avg_review_score


    FROM staging.sellers s

    INNER JOIN seller_commercial c
        ON s.seller_id = c.seller_id

    LEFT JOIN seller_catalog_summary cat
        ON s.seller_id = cat.seller_id

    LEFT JOIN seller_operations op
        ON s.seller_id = op.seller_id

)


SELECT
    *,

    RANK() OVER (
        ORDER BY seller_gmv DESC
    ) AS seller_gmv_rank,

    RANK() OVER (
        ORDER BY delivered_orders DESC
    ) AS seller_order_volume_rank


FROM seller_base;

ALTER TABLE analytics.seller_mart
ADD CONSTRAINT pk_seller_mart
PRIMARY KEY (seller_id);


CREATE INDEX idx_seller_mart_state
ON analytics.seller_mart (
    seller_state
);


CREATE INDEX idx_seller_mart_gmv
ON analytics.seller_mart (
    seller_gmv
);