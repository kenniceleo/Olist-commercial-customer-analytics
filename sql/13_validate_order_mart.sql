-- ============================================================
-- Olist Commercial & Customer Analytics
-- 13_validate_order_mart.sql
--
-- Purpose:
-- Validate the order mart grain, coverage and metric
-- reconciliation before building downstream customer marts.
-- ============================================================


-- ============================================================
-- 1. ONE ROW PER ORDER
-- ============================================================

SELECT
    COUNT(*) AS mart_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM analytics.order_mart;


-- ============================================================
-- 2. RAW / STAGING / MART ORDER RECONCILIATION
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.orders) AS raw_orders,
    (SELECT COUNT(*) FROM staging.orders) AS staging_orders,
    (SELECT COUNT(*) FROM analytics.order_mart) AS mart_orders;


-- ============================================================
-- 3. DELIVERED ORDER COUNT
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders
FROM analytics.order_mart
WHERE is_delivered;


-- ============================================================
-- 4. ITEM COVERAGE
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE order_gmv IS NULL
    ) AS orders_without_item_data,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND order_gmv IS NULL
    ) AS delivered_orders_without_item_data

FROM analytics.order_mart;


-- ============================================================
-- 5. PAYMENT COVERAGE
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE total_payment_value IS NULL
    ) AS orders_without_payment_data,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND total_payment_value IS NULL
    ) AS delivered_orders_without_payment_data

FROM analytics.order_mart;


-- ============================================================
-- 6. REVIEW COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE latest_review_score IS NOT NULL
    ) AS orders_with_review,

    COUNT(*) FILTER (
        WHERE latest_review_score IS NULL
    ) AS orders_without_review

FROM analytics.order_mart;


-- ============================================================
-- 7. ITEM GMV RECONCILIATION
--
-- Mart GMV should equal item-level GMV because items were
-- aggregated before joining.
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(item_gmv)
         FROM staging.order_items),
        2
    ) AS staging_item_gmv,

    ROUND(
        (SELECT SUM(order_gmv)
         FROM analytics.order_mart),
        2
    ) AS mart_order_gmv;


-- Delivered orders only
SELECT
    ROUND(
        SUM(order_gmv),
        2
    ) AS delivered_gmv
FROM analytics.order_mart
WHERE is_delivered;


-- ============================================================
-- 8. FREIGHT RECONCILIATION
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(freight_value)
         FROM staging.order_items),
        2
    ) AS staging_freight,

    ROUND(
        (SELECT SUM(freight_value)
         FROM analytics.order_mart),
        2
    ) AS mart_freight;


-- ============================================================
-- 9. PAYMENT RECONCILIATION
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(payment_value)
         FROM staging.payments),
        2
    ) AS staging_payment_value,

    ROUND(
        (SELECT SUM(total_payment_value)
         FROM analytics.order_mart),
        2
    ) AS mart_payment_value;


-- ============================================================
-- 10. GMV VS PAYMENT VALUE
--
-- These need not be identical because payment value includes
-- freight and may contain other transaction-level differences.
-- This is an analytical comparison, not a strict equality test.
-- ============================================================

SELECT
    ROUND(SUM(order_gmv), 2)
        AS total_gmv,

    ROUND(SUM(freight_value), 2)
        AS total_freight,

    ROUND(SUM(merchandise_plus_freight), 2)
        AS merchandise_plus_freight,

    ROUND(SUM(total_payment_value), 2)
        AS total_payment_value

FROM analytics.order_mart;


-- ============================================================
-- 11. KEY COMMERCIAL SANITY CHECKS
-- ============================================================

SELECT
    MIN(order_gmv) AS min_order_gmv,
    ROUND(AVG(order_gmv), 2) AS avg_order_gmv,
    MAX(order_gmv) AS max_order_gmv,

    MIN(item_count) AS min_items,
    ROUND(AVG(item_count), 2) AS avg_items,
    MAX(item_count) AS max_items

FROM analytics.order_mart
WHERE is_delivered;


-- ============================================================
-- 12. PAYMENT METHOD DISTRIBUTION
-- ============================================================

SELECT
    primary_payment_type,
    COUNT(*) AS orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_orders

FROM analytics.order_mart

WHERE is_delivered

GROUP BY primary_payment_type

ORDER BY orders DESC;


-- ============================================================
-- 13. CATEGORY COVERAGE
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE primary_product_category IS NULL
    ) AS orders_without_category,

    COUNT(*) FILTER (
        WHERE primary_product_category = 'unknown'
    ) AS orders_with_unknown_category

FROM analytics.order_mart
WHERE is_delivered;


-- ============================================================
-- 14. FULFILMENT COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(seller_processing_days)
        AS orders_with_processing_metric,

    COUNT(delivery_days)
        AS orders_with_delivery_metric,

    COUNT(late_delivery_flag)
        AS orders_with_lateness_metric,

    COUNT(*) FILTER (
        WHERE late_delivery_flag = TRUE
    ) AS late_orders

FROM analytics.order_mart
WHERE is_delivered;