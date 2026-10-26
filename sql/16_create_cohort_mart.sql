-- ============================================================
-- Olist Commercial & Customer Analytics
-- 16_create_cohort_mart.sql
--
-- Purpose:
-- Create monthly acquisition cohorts and measure customer
-- activity in subsequent calendar months.
--
-- Grain:
-- One row per cohort_month + months_since_first_purchase.
--
-- Important:
-- A customer is counted at most once in each activity month,
-- even if they place multiple orders in that month.
-- ============================================================


DROP TABLE IF EXISTS analytics.cohort_retention CASCADE;


CREATE TABLE analytics.cohort_retention AS


WITH customer_cohorts AS (

    -- --------------------------------------------------------
    -- Assign every customer to the month of their first
    -- successfully delivered order.
    -- --------------------------------------------------------

    SELECT
        customer_unique_id,

        DATE_TRUNC(
            'month',
            first_order_date
        )::DATE AS cohort_month

    FROM analytics.customer_mart

),


customer_month_activity AS (

    -- --------------------------------------------------------
    -- One row per customer per active purchase month.
    --
    -- DISTINCT prevents a customer placing multiple orders
    -- within the same month from being counted multiple times.
    -- --------------------------------------------------------

    SELECT DISTINCT
        customer_unique_id,

        DATE_TRUNC(
            'month',
            purchase_date
        )::DATE AS activity_month

    FROM analytics.order_mart

    WHERE is_delivered = TRUE

),


cohort_activity AS (

    -- --------------------------------------------------------
    -- Calculate how many calendar months after acquisition
    -- each activity month occurred.
    -- --------------------------------------------------------

    SELECT
        c.customer_unique_id,

        c.cohort_month,

        a.activity_month,

        (
            EXTRACT(YEAR FROM a.activity_month)::INTEGER * 12
            +
            EXTRACT(MONTH FROM a.activity_month)::INTEGER
        )
        -
        (
            EXTRACT(YEAR FROM c.cohort_month)::INTEGER * 12
            +
            EXTRACT(MONTH FROM c.cohort_month)::INTEGER
        ) AS months_since_first_purchase

    FROM customer_cohorts c

    INNER JOIN customer_month_activity a
        ON c.customer_unique_id =
           a.customer_unique_id

    WHERE a.activity_month >= c.cohort_month

),


cohort_sizes AS (

    -- --------------------------------------------------------
    -- Number of customers originally acquired in each cohort.
    -- --------------------------------------------------------

    SELECT
        cohort_month,

        COUNT(*) AS cohort_customers

    FROM customer_cohorts

    GROUP BY cohort_month

),


retention_counts AS (

    -- --------------------------------------------------------
    -- Count how many customers from each cohort were active
    -- in each subsequent month.
    -- --------------------------------------------------------

    SELECT
        cohort_month,

        months_since_first_purchase,

        COUNT(
            DISTINCT customer_unique_id
        ) AS active_customers

    FROM cohort_activity

    GROUP BY
        cohort_month,
        months_since_first_purchase

)


SELECT
    r.cohort_month,

    r.months_since_first_purchase,

    s.cohort_customers,

    r.active_customers,

    ROUND(
        100.0
        * r.active_customers
        / NULLIF(s.cohort_customers, 0),
        2
    ) AS retention_rate_pct

FROM retention_counts r

INNER JOIN cohort_sizes s
    ON r.cohort_month =
       s.cohort_month

ORDER BY
    r.cohort_month,
    r.months_since_first_purchase;


CREATE INDEX idx_cohort_month
ON analytics.cohort_retention (
    cohort_month
);


CREATE INDEX idx_cohort_month_offset
ON analytics.cohort_retention (
    cohort_month,
    months_since_first_purchase
);