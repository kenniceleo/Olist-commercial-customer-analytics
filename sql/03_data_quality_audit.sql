-- ============================================================
-- Olist Commercial & Customer Analytics
-- 03_data_quality_audit.sql
--
-- Initial source-table audit
-- ============================================================


SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM raw.order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM raw.order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM raw.order_reviews

UNION ALL

SELECT 'products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM raw.sellers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM raw.geolocation

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM raw.product_category_translation

ORDER BY table_name;

-- ============================================================
-- 2. KEY UNIQUENESS / DUPLICATE CHECKS
-- ============================================================

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers
FROM raw.customers;


-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids
FROM raw.orders;


-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS distinct_product_ids
FROM raw.products;


-- Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_seller_ids
FROM raw.sellers;


-- Order items
-- Expected grain = one row per order_id + order_item_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_order_items
FROM raw.order_items;


-- Payments
-- Expected grain = one payment component per order_id + payment_sequential
-- Grain: what does one row represent? (for each table)
-- order_id + payment_sequential
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential)) AS distinct_payments
FROM raw.order_payments;


-- Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id) AS reviewed_orders
FROM raw.order_reviews;


-- Category translation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS distinct_categories
FROM raw.product_category_translation;

-- ============================================================
-- 3. EXPLICIT DUPLICATE KEY CHECKS
-- ============================================================


-- Duplicate customer_id
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM raw.customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Duplicate order_id
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Duplicate product_id
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM raw.products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Duplicate seller_id
SELECT
    seller_id,
    COUNT(*) AS occurrences
FROM raw.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Duplicate order-item composite key
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrences
FROM raw.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Duplicate payment composite key
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS occurrences
FROM raw.order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- ============================================================
-- 4. REFERENTIAL INTEGRITY CHECKS
-- ============================================================


-- Orders without a matching customer
SELECT COUNT(*) AS orphan_orders
FROM raw.orders o
LEFT JOIN raw.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order items without a matching order
SELECT COUNT(*) AS orphan_order_items
FROM raw.order_items oi
LEFT JOIN raw.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Order items without a matching product
SELECT COUNT(*) AS items_without_product
FROM raw.order_items oi
LEFT JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Order items without a matching seller
SELECT COUNT(*) AS items_without_seller
FROM raw.order_items oi
LEFT JOIN raw.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Payments without a matching order
SELECT COUNT(*) AS payments_without_order
FROM raw.order_payments op
LEFT JOIN raw.orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Reviews without a matching order
SELECT COUNT(*) AS reviews_without_order
FROM raw.order_reviews r
LEFT JOIN raw.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ============================================================
-- 5. ORDER STATUS DISTRIBUTION
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_orders
FROM raw.orders
GROUP BY order_status
ORDER BY orders DESC;

-- ============================================================
-- 6. CUSTOMER IDENTITY
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id) AS order_level_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_people
FROM raw.customers;

SELECT
    customer_unique_id,
    COUNT(*) AS number_of_customer_ids
FROM raw.customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY number_of_customer_ids DESC
LIMIT 20;

-- ============================================================
-- 7. REVIEW TABLE MULTIPLICITY
-- ============================================================

-- How many review IDs appear more than once?
SELECT
    COUNT(*) AS duplicated_review_ids
FROM (
    SELECT review_id
    FROM raw.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) x;


-- Inspect duplicated review IDs
SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM raw.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;


-- How many orders have more than one review row?
SELECT
    COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT order_id
    FROM raw.order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;


-- Inspect those orders
SELECT
    order_id,
    COUNT(*) AS review_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score
FROM raw.order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_rows DESC
LIMIT 20;

-- ============================================================
-- 8. CRITICAL NULL CHECKS
-- ============================================================

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_customer_unique_id,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS null_zip,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_state
FROM raw.customers;


-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_ts,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_ts,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_customer_delivery_ts,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_delivery_ts
FROM raw.orders;


-- Order items
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight
FROM raw.order_items;


-- Payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS null_installments,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM raw.order_payments;


-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width
FROM raw.products;


-- Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_message,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS null_creation_date
FROM raw.order_reviews;

-- ============================================================
-- 9. DELIVERED ORDER COMPLETENESS
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_date,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_customer_delivery,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery

FROM raw.orders
WHERE order_status = 'delivered';

-- ============================================================
-- 10. NUMERIC VALUE VALIDITY
-- ============================================================

-- Prices and freight
SELECT
    COUNT(*) FILTER (WHERE price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE price = 0) AS zero_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight,
    COUNT(*) FILTER (WHERE freight_value = 0) AS zero_freight
FROM raw.order_items;


-- Payments
SELECT
    COUNT(*) FILTER (WHERE payment_value < 0) AS negative_payments,
    COUNT(*) FILTER (WHERE payment_value = 0) AS zero_payments,
    COUNT(*) FILTER (WHERE payment_installments < 0) AS negative_installments,
    COUNT(*) FILTER (WHERE payment_installments = 0) AS zero_installments
FROM raw.order_payments;


-- Review scores
SELECT
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score,
    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores
FROM raw.order_reviews;

-- ============================================================
-- 11. TIMESTAMP LOGIC
-- ============================================================

SELECT

    COUNT(*) FILTER (
        WHERE order_approved_at < order_purchase_timestamp
    ) AS approved_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_purchase_timestamp
    ) AS carrier_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_purchase_timestamp
    ) AS delivered_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS customer_delivery_before_carrier

FROM raw.orders;

-- ============================================================
-- 12. DATE COVERAGE
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM raw.orders;


SELECT
    MIN(order_purchase_timestamp) AS earliest_delivered_order,
    MAX(order_purchase_timestamp) AS latest_delivered_order
FROM raw.orders
WHERE order_status = 'delivered';

-- ============================================================
-- 13. MULTI-ROW ORDER STRUCTURE
-- ============================================================

-- Orders containing multiple item rows
SELECT
    COUNT(*) AS orders_with_multiple_items
FROM (
    SELECT order_id
    FROM raw.order_items
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;


-- Orders containing multiple payment rows
SELECT
    COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT order_id
    FROM raw.order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x;


-- Maximum item rows in one order
SELECT
    MAX(item_count) AS max_items_in_single_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS item_count
    FROM raw.order_items
    GROUP BY order_id
) x;


-- Maximum payment rows in one order
SELECT
    MAX(payment_count) AS max_payments_in_single_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS payment_count
    FROM raw.order_payments
    GROUP BY order_id
) x;