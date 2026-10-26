-- ============================================================
-- VALIDATION
-- ============================================================


-- Mart grain
SELECT
    COUNT(*) AS seller_rows,

    COUNT(
        DISTINCT seller_id
    ) AS unique_sellers

FROM analytics.seller_mart;


-- Compare against sellers with delivered transactions
SELECT
    COUNT(
        DISTINCT i.seller_id
    ) AS sellers_with_delivered_orders

FROM staging.order_items i

INNER JOIN analytics.order_mart o
    ON i.order_id = o.order_id

WHERE o.is_delivered = TRUE;


-- Seller GMV must reconcile to delivered order mart GMV
SELECT

    ROUND(
        (
            SELECT SUM(seller_gmv)
            FROM analytics.seller_mart
        ),
        2
    ) AS seller_mart_gmv,

    ROUND(
        (
            SELECT SUM(order_gmv)
            FROM analytics.order_mart
            WHERE is_delivered = TRUE
        ),
        2
    ) AS delivered_order_mart_gmv;


-- Seller distribution
SELECT
    COUNT(*) AS sellers,

    ROUND(
        AVG(delivered_orders),
        2
    ) AS avg_orders_per_seller,

    PERCENTILE_CONT(0.5)
    WITHIN GROUP (
        ORDER BY delivered_orders
    ) AS median_orders_per_seller,

    MAX(delivered_orders)
        AS max_orders_per_seller,

    ROUND(
        AVG(seller_gmv),
        2
    ) AS avg_seller_gmv

FROM analytics.seller_mart;


-- Operational attribution coverage
SELECT
    SUM(delivered_orders)
        AS seller_order_relationships,

    SUM(single_seller_orders)
        AS single_seller_orders_used_for_ops,

    SUM(multi_seller_orders)
        AS multi_seller_order_relationships

FROM analytics.seller_mart;


-- Top 10 by GMV
SELECT
    seller_id,
    seller_state,

    delivered_orders,
    seller_gmv,

    avg_seller_processing_days,
    late_delivery_rate_pct,
    avg_review_score,

    seller_gmv_rank

FROM analytics.seller_mart

ORDER BY seller_gmv_rank

LIMIT 10;