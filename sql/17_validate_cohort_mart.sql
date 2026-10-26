-- ============================================================
-- Olist Commercial & Customer Analytics
-- 17_validate_cohort_mart.sql
--
-- Purpose:
-- Validate cohort sizes, Month-0 retention and customer
-- reconciliation before using cohort data in analysis / BI.
-- ============================================================


-- ============================================================
-- 1. COHORT DATE COVERAGE
-- ============================================================

SELECT
    MIN(cohort_month) AS earliest_cohort,
    MAX(cohort_month) AS latest_cohort,
    COUNT(
        DISTINCT cohort_month
    ) AS cohort_months

FROM analytics.cohort_retention;



-- ============================================================
-- 2. COHORT SIZES
-- ============================================================

SELECT
    cohort_month,
    cohort_customers

FROM analytics.cohort_retention

WHERE months_since_first_purchase = 0

ORDER BY cohort_month;



-- ============================================================
-- 3. MONTH 0 MUST EQUAL 100%
-- ============================================================

SELECT
    COUNT(*) AS invalid_month_zero_rows

FROM analytics.cohort_retention

WHERE months_since_first_purchase = 0
  AND retention_rate_pct <> 100.00;



-- ============================================================
-- 4. RECONCILE TOTAL CUSTOMERS
-- ============================================================

SELECT
    SUM(cohort_customers)
        AS customers_across_cohorts,

    (
        SELECT COUNT(*)
        FROM analytics.customer_mart
    ) AS customers_in_customer_mart

FROM analytics.cohort_retention

WHERE months_since_first_purchase = 0;



-- ============================================================
-- 5. RETENTION MATRIX PREVIEW
--
-- This previews the same structure that will eventually become
-- our Power BI cohort heatmap.
-- ============================================================

SELECT
    cohort_month,

    MAX(
        CASE
            WHEN months_since_first_purchase = 0
            THEN retention_rate_pct
        END
    ) AS month_0,

    MAX(
        CASE
            WHEN months_since_first_purchase = 1
            THEN retention_rate_pct
        END
    ) AS month_1,

    MAX(
        CASE
            WHEN months_since_first_purchase = 2
            THEN retention_rate_pct
        END
    ) AS month_2,

    MAX(
        CASE
            WHEN months_since_first_purchase = 3
            THEN retention_rate_pct
        END
    ) AS month_3,

    MAX(
        CASE
            WHEN months_since_first_purchase = 4
            THEN retention_rate_pct
        END
    ) AS month_4,

    MAX(
        CASE
            WHEN months_since_first_purchase = 5
            THEN retention_rate_pct
        END
    ) AS month_5,

    MAX(
        CASE
            WHEN months_since_first_purchase = 6
            THEN retention_rate_pct
        END
    ) AS month_6

FROM analytics.cohort_retention

GROUP BY cohort_month

ORDER BY cohort_month;



-- ============================================================
-- 6. CHECK FOR IMPOSSIBLE VALUES
-- ============================================================

SELECT
    COUNT(*) AS invalid_retention_rows

FROM analytics.cohort_retention

WHERE retention_rate_pct < 0
   OR retention_rate_pct > 100
   OR active_customers > cohort_customers
   OR months_since_first_purchase < 0;



-- ============================================================
-- 7. OBSERVED MONTH RANGE
-- ============================================================

SELECT
    MIN(months_since_first_purchase)
        AS min_month_offset,

    MAX(months_since_first_purchase)
        AS max_month_offset

FROM analytics.cohort_retention;