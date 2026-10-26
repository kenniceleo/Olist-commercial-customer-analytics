-- ============================================================
-- Olist Commercial & Customer Analytics
-- 15_validate_customer_mart.sql
-- ============================================================


-- ============================================================
-- 1. CUSTOMER MART GRAIN
-- ============================================================

SELECT
    COUNT(*) AS customer_rows,

    COUNT(
        DISTINCT customer_unique_id
    ) AS unique_customers

FROM analytics.customer_mart;



-- ============================================================
-- 2. RECONCILE TO DELIVERED ORDERS
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM analytics.order_mart
        WHERE is_delivered
    ) AS delivered_orders_in_order_mart,

    (
        SELECT SUM(delivered_orders)
        FROM analytics.customer_mart
    ) AS delivered_orders_in_customer_mart;



-- ============================================================
-- 3. RECONCILE GMV
-- ============================================================

SELECT
    ROUND(
        (
            SELECT SUM(order_gmv)
            FROM analytics.order_mart
            WHERE is_delivered
        ),
        2
    ) AS order_mart_gmv,

    ROUND(
        (
            SELECT SUM(total_gmv)
            FROM analytics.customer_mart
        ),
        2
    ) AS customer_mart_gmv;



-- ============================================================
-- 4. CUSTOMER FREQUENCY DISTRIBUTION
-- ============================================================

SELECT
    delivered_orders,
    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_customers

FROM analytics.customer_mart

GROUP BY delivered_orders

ORDER BY delivered_orders;



-- ============================================================
-- 5. REPEAT CUSTOMER RATE
-- ============================================================

SELECT
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE repeat_customer_flag
    ) AS repeat_customers,

    COUNT(*) FILTER (
        WHERE NOT repeat_customer_flag
    ) AS one_time_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeat_customer_flag
        )
        / COUNT(*),
        2
    ) AS repeat_customer_pct

FROM analytics.customer_mart;



-- ============================================================
-- 6. TIME TO SECOND PURCHASE
-- ============================================================

SELECT
    COUNT(days_to_second_purchase)
        AS repeat_customers,

    ROUND(
        AVG(days_to_second_purchase),
        2
    ) AS avg_days_to_second_purchase,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY days_to_second_purchase
        ) AS median_days_to_second_purchase,

    MIN(days_to_second_purchase)
        AS min_days,

    MAX(days_to_second_purchase)
        AS max_days

FROM analytics.customer_mart

WHERE repeat_customer_flag;



-- ============================================================
-- 7. FIXED-HORIZON REPEAT RATES
-- ============================================================

SELECT
    '30 days' AS horizon,

    COUNT(*) FILTER (
        WHERE eligible_30d_followup
    ) AS eligible_customers,

    COUNT(*) FILTER (
        WHERE eligible_30d_followup
          AND repeated_within_30d
    ) AS repeat_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE eligible_30d_followup
              AND repeated_within_30d
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE eligible_30d_followup
            ),
            0
        ),
        2
    ) AS repeat_rate_pct

FROM analytics.customer_mart

UNION ALL

SELECT
    '60 days',

    COUNT(*) FILTER (
        WHERE eligible_60d_followup
    ),

    COUNT(*) FILTER (
        WHERE eligible_60d_followup
          AND repeated_within_60d
    ),

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE eligible_60d_followup
              AND repeated_within_60d
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE eligible_60d_followup
            ),
            0
        ),
        2
    )

FROM analytics.customer_mart

UNION ALL

SELECT
    '90 days',

    COUNT(*) FILTER (
        WHERE eligible_90d_followup
    ),

    COUNT(*) FILTER (
        WHERE eligible_90d_followup
          AND repeated_within_90d
    ),

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE eligible_90d_followup
              AND repeated_within_90d
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE eligible_90d_followup
            ),
            0
        ),
        2
    )

FROM analytics.customer_mart;



-- ============================================================
-- 8. FIRST-ORDER FEATURE COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS customers,

    COUNT(first_order_gmv)
        AS customers_with_first_order_gmv,

    COUNT(first_order_category)
        AS customers_with_first_category,

    COUNT(first_order_payment_type)
        AS customers_with_first_payment,

    COUNT(first_order_review_score)
        AS customers_with_first_review,

    COUNT(first_order_delivery_days)
        AS customers_with_first_delivery_metric

FROM analytics.customer_mart;



-- ============================================================
-- 9. RAW RFM COMPONENTS
-- ============================================================

SELECT
    MIN(recency_days) AS min_recency,
    ROUND(AVG(recency_days), 2)
        AS avg_recency,
    MAX(recency_days) AS max_recency,

    MIN(frequency) AS min_frequency,
    ROUND(AVG(frequency), 2)
        AS avg_frequency,
    MAX(frequency) AS max_frequency,

    MIN(monetary_value) AS min_monetary,
    ROUND(AVG(monetary_value), 2)
        AS avg_monetary,
    MAX(monetary_value) AS max_monetary

FROM analytics.customer_mart;