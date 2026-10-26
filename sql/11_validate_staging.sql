-- ============================================================
-- Olist Commercial & Customer Analytics
-- 10_validate_staging.sql
--
-- Purpose:
-- Validate row preservation, grain, key integrity and derived
-- metrics after cleaning.
-- ============================================================


-- ============================================================
-- 1. RAW VS STAGING ROW COUNTS
-- ============================================================

SELECT
    'customers' AS table_name,
    (SELECT COUNT(*) FROM raw.customers) AS raw_rows,
    (SELECT COUNT(*) FROM staging.customers) AS staging_rows

UNION ALL

SELECT
    'products',
    (SELECT COUNT(*) FROM raw.products),
    (SELECT COUNT(*) FROM staging.products)

UNION ALL

SELECT
    'sellers',
    (SELECT COUNT(*) FROM raw.sellers),
    (SELECT COUNT(*) FROM staging.sellers)

UNION ALL

SELECT
    'orders',
    (SELECT COUNT(*) FROM raw.orders),
    (SELECT COUNT(*) FROM staging.orders)

UNION ALL

SELECT
    'order_items',
    (SELECT COUNT(*) FROM raw.order_items),
    (SELECT COUNT(*) FROM staging.order_items)

UNION ALL

SELECT
    'payments',
    (SELECT COUNT(*) FROM raw.order_payments),
    (SELECT COUNT(*) FROM staging.payments)

UNION ALL

SELECT
    'reviews',
    (SELECT COUNT(*) FROM raw.order_reviews),
    (SELECT COUNT(*) FROM staging.reviews)

ORDER BY table_name;



-- ============================================================
-- 2. KEY UNIQUENESS
-- ============================================================

SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT customer_id)
        AS unique_customer_ids
FROM staging.customers;


SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT product_id) 
        AS unique_products
FROM staging.products;


SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT seller_id) 
        AS unique_sellers
FROM staging.sellers;


SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT order_id)
        AS unique_orders
FROM staging.orders;


SELECT
    COUNT(*) AS rows,
    COUNT(
        DISTINCT (order_id, order_item_id)
    ) AS unique_order_items
FROM staging.order_items;


SELECT
    COUNT(*) AS rows,
    COUNT(
        DISTINCT (order_id, payment_sequential)
    ) AS unique_payments
FROM staging.payments;


SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT review_row_id)
        AS unique_review_rows
FROM staging.reviews;



-- ============================================================
-- 3. CUSTOMER IDENTITY
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id)
        AS customer_ids,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers

FROM staging.customers;



-- ============================================================
-- 4. ORDER STATUS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS orders
FROM staging.orders
GROUP BY order_status
ORDER BY orders DESC;



-- ============================================================
-- 5. DELIVERED ORDER VALIDITY
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE is_delivered
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND seller_processing_days IS NULL
    ) AS delivered_missing_processing_days,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND delivery_days IS NULL
    ) AS delivered_missing_delivery_days,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND late_delivery_flag = TRUE
    ) AS late_delivered_orders

FROM staging.orders;



-- ============================================================
-- 6. INVALID NUMERIC VALUES
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE valid_price = FALSE
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE valid_freight = FALSE
    ) AS invalid_freight,

    COUNT(*) FILTER (
        WHERE free_shipping_flag = TRUE
    ) AS zero_freight_items

FROM staging.order_items;


SELECT
    COUNT(*) FILTER (
        WHERE valid_payment_value = FALSE
    ) AS invalid_payments,

    COUNT(*) FILTER (
        WHERE zero_payment_flag = TRUE
    ) AS zero_payment_rows,

    COUNT(*) FILTER (
        WHERE valid_installments = FALSE
    ) AS invalid_installments

FROM staging.payments;



-- ============================================================
-- 7. PRODUCT CATEGORY COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE product_category = 'unknown'
    ) AS unknown_category_products,

    COUNT(*) FILTER (
        WHERE has_complete_dimensions = FALSE
    ) AS products_missing_dimensions

FROM staging.products;



-- ============================================================
-- 8. REVIEW VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS review_rows,

    COUNT(DISTINCT review_id)
        AS distinct_review_ids,

    COUNT(DISTINCT order_id)
        AS reviewed_orders,

    COUNT(*) FILTER (
        WHERE valid_review_score = FALSE
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE duplicated_review_id_flag = TRUE
    ) AS rows_with_reused_review_id,

    COUNT(DISTINCT order_id) FILTER (
        WHERE multiple_reviews_for_order_flag = TRUE
    ) AS orders_with_multiple_review_rows

FROM staging.reviews;



-- ============================================================
-- 9. FOREIGN-KEY / ORPHAN CHECK
-- ============================================================

SELECT
    COUNT(*) AS orphan_order_items
FROM staging.order_items i

LEFT JOIN staging.orders o
    ON i.order_id = o.order_id

WHERE o.order_id IS NULL;


SELECT
    COUNT(*) AS orphan_payments
FROM staging.payments p

LEFT JOIN staging.orders o
    ON p.order_id = o.order_id

WHERE o.order_id IS NULL;


SELECT
    COUNT(*) AS orphan_reviews
FROM staging.reviews r

LEFT JOIN staging.orders o
    ON r.order_id = o.order_id

WHERE o.order_id IS NULL;



-- ============================================================
-- 10. BASIC DATE COVERAGE
-- ============================================================

SELECT
    MIN(purchase_date) AS earliest_purchase,
    MAX(purchase_date) AS latest_purchase,

    MIN(purchase_date) FILTER (
        WHERE is_delivered
    ) AS earliest_delivered_purchase,

    MAX(purchase_date) FILTER (
        WHERE is_delivered
    ) AS latest_delivered_purchase

FROM staging.orders;


-- ============================================================
-- 11. SELLER PROCESSING TIME DIAGNOSTIC
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE is_delivered
          AND order_approved_at IS NULL
    ) AS missing_approval,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND order_delivered_carrier_date IS NULL
    ) AS missing_carrier_date,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND order_approved_at IS NOT NULL
          AND order_delivered_carrier_date IS NOT NULL
          AND order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE is_delivered
          AND seller_processing_days IS NULL
    ) AS total_invalid_processing_time

FROM staging.orders;