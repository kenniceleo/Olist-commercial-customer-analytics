-- ============================================================
-- VALIDATION
-- ============================================================


-- Grain
SELECT
    COUNT(*) AS segment_rows,

    COUNT(
        DISTINCT customer_unique_id
    ) AS unique_customers

FROM analytics.customer_segments;


-- Value threshold selected from actual data
SELECT DISTINCT
    ROUND(
        high_value_threshold::NUMERIC,
        2
    ) AS high_value_threshold

FROM analytics.customer_segments;


-- Segment distribution
SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_customers,

    ROUND(
        AVG(total_gmv),
        2
    ) AS avg_customer_gmv,

    ROUND(
        AVG(average_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days

FROM analytics.customer_segments

GROUP BY customer_segment

ORDER BY customers DESC;


-- Reconcile with customer mart
SELECT
    (
        SELECT COUNT(*)
        FROM analytics.customer_mart
    ) AS customer_mart_rows,

    (
        SELECT COUNT(*)
        FROM analytics.customer_segments
    ) AS customer_segment_rows;


-- Check for missing segments
SELECT
    COUNT(*) AS customers_without_segment

FROM analytics.customer_segments

WHERE customer_segment IS NULL;