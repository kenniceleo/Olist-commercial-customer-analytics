-- ============================================================
-- Olist Commercial & Customer Analytics
-- 23_customer_retention_analysis.sql
--
-- Purpose:
-- Analyse repeat purchasing and first-order characteristics
-- associated with subsequent customer behaviour.
--
-- IMPORTANT:
-- Associations are descriptive and should not be interpreted
-- as causal effects.
-- ============================================================


-- ============================================================
-- 1. OVERALL CUSTOMER REPEAT BEHAVIOUR
-- ============================================================

SELECT
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE repeat_customer_flag
    ) AS repeat_customers,

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
-- 2. FIXED FOLLOW-UP WINDOWS
-- ============================================================

SELECT
    '30 days' AS horizon,

    COUNT(*) FILTER (
        WHERE eligible_30d_followup
    ) AS eligible_customers,

    COUNT(*) FILTER (
        WHERE eligible_30d_followup
          AND repeated_within_30d
    ) AS repeaters,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE eligible_30d_followup
              AND repeated_within_30d
        )
        / NULLIF(
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
-- 3. TIME TO SECOND PURCHASE DISTRIBUTION
-- ============================================================

SELECT
    CASE
        WHEN days_to_second_purchase < 1
            THEN '< 1 day'

        WHEN days_to_second_purchase <= 7
            THEN '1-7 days'

        WHEN days_to_second_purchase <= 30
            THEN '8-30 days'

        WHEN days_to_second_purchase <= 60
            THEN '31-60 days'

        WHEN days_to_second_purchase <= 90
            THEN '61-90 days'

        WHEN days_to_second_purchase <= 180
            THEN '91-180 days'

        ELSE '180+ days'
    END AS repeat_timing,

    COUNT(*) AS customers,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_repeat_customers

FROM analytics.customer_mart

WHERE repeat_customer_flag = TRUE

GROUP BY repeat_timing

ORDER BY
    MIN(days_to_second_purchase);


-- ============================================================
-- 3B. STRICTER RETURN-PURCHASE METRIC
--
-- Excludes second purchases made within 24 hours, which may
-- represent split orders / same-session behaviour rather than
-- genuine customer return behaviour.
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE eligible_90d_followup
    ) AS eligible_customers,

    COUNT(*) FILTER (
        WHERE eligible_90d_followup
          AND days_to_second_purchase >= 1
          AND days_to_second_purchase <= 90
    ) AS returned_1_to_90_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE eligible_90d_followup
              AND days_to_second_purchase >= 1
              AND days_to_second_purchase <= 90
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE eligible_90d_followup
            ),
            0
        ),
        2
    ) AS return_rate_1_to_90_days_pct

FROM analytics.customer_mart;


-- ============================================================
-- 4. FIRST-ORDER CHARACTERISTICS:
--    90-DAY REPEATERS VS NON-REPEATERS
-- ============================================================

SELECT
    repeated_within_90d,

    COUNT(*) AS customers,

    ROUND(
        AVG(first_order_gmv),
        2
    ) AS avg_first_order_gmv,

    ROUND(
        AVG(first_order_freight_ratio),
        4
    ) AS avg_first_order_freight_ratio,

    ROUND(
        AVG(first_order_item_count),
        2
    ) AS avg_first_order_items,

    ROUND(
        AVG(first_order_review_score),
        2
    ) AS avg_first_order_review,

    ROUND(
        AVG(first_order_delivery_days),
        2
    ) AS avg_first_order_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE first_order_late_flag = TRUE
        )
        /
        NULLIF(
            COUNT(first_order_late_flag),
            0
        ),
        2
    ) AS first_order_late_rate_pct

FROM analytics.customer_mart

WHERE eligible_90d_followup = TRUE

GROUP BY repeated_within_90d

ORDER BY repeated_within_90d DESC;



-- ============================================================
-- 5. FIRST-ORDER CATEGORY VS 90-DAY REPEAT
--
-- Minimum 200 eligible customers prevents tiny categories from
-- dominating rankings.
-- ============================================================

SELECT
    first_order_category,

    COUNT(*) AS eligible_customers,

    COUNT(*) FILTER (
        WHERE repeated_within_90d
    ) AS repeaters_90d,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct,

    ROUND(
        AVG(first_order_gmv),
        2
    ) AS avg_first_order_gmv

FROM analytics.customer_mart

WHERE eligible_90d_followup = TRUE

GROUP BY first_order_category

HAVING COUNT(*) >= 200

ORDER BY repeat_rate_90d_pct DESC;



-- ============================================================
-- 6. FIRST REVIEW SCORE VS 90-DAY REPEAT
-- ============================================================

SELECT
    first_order_review_score,

    COUNT(*) AS eligible_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct

FROM analytics.customer_mart

WHERE eligible_90d_followup = TRUE
  AND first_order_review_score IS NOT NULL

GROUP BY first_order_review_score

ORDER BY first_order_review_score;



-- ============================================================
-- 7. FIRST-ORDER LATENESS VS REPEAT
-- ============================================================

SELECT
    CASE
        WHEN first_order_late_flag = TRUE
            THEN 'Late'

        WHEN first_order_late_flag = FALSE
            THEN 'On Time'

        ELSE 'Unknown'
    END AS first_delivery_status,

    COUNT(*) AS eligible_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct,

    ROUND(
        AVG(first_order_review_score),
        2
    ) AS avg_first_order_review

FROM analytics.customer_mart

WHERE eligible_90d_followup = TRUE

GROUP BY first_delivery_status

ORDER BY eligible_customers DESC;



-- ============================================================
-- 8. FIRST PAYMENT METHOD VS 90-DAY REPEAT
-- ============================================================

SELECT
    COALESCE(
        first_order_payment_type,
        'unknown'
    ) AS first_payment_method,

    COUNT(*) AS eligible_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct,

    ROUND(
        AVG(first_order_gmv),
        2
    ) AS avg_first_order_gmv

FROM analytics.customer_mart

WHERE eligible_90d_followup = TRUE

GROUP BY first_order_payment_type

ORDER BY eligible_customers DESC;



-- ============================================================
-- 9. FIRST-ORDER VALUE QUARTILES VS REPEAT
-- ============================================================

WITH eligible AS (

    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY first_order_gmv
        ) AS gmv_quartile

    FROM analytics.customer_mart

    WHERE eligible_90d_followup = TRUE

)

SELECT
    gmv_quartile,

    COUNT(*) AS customers,

    ROUND(
        MIN(first_order_gmv),
        2
    ) AS min_first_order_gmv,

    ROUND(
        MAX(first_order_gmv),
        2
    ) AS max_first_order_gmv,

    ROUND(
        AVG(first_order_gmv),
        2
    ) AS avg_first_order_gmv,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct

FROM eligible

GROUP BY gmv_quartile

ORDER BY gmv_quartile;



-- ============================================================
-- 10. FREIGHT BURDEN QUARTILES VS REPEAT
-- ============================================================

WITH eligible AS (

    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY first_order_freight_ratio
        ) AS freight_quartile

    FROM analytics.customer_mart

    WHERE eligible_90d_followup = TRUE
      AND first_order_freight_ratio IS NOT NULL

)

SELECT
    freight_quartile,

    COUNT(*) AS customers,

    ROUND(
        AVG(first_order_freight_ratio),
        4
    ) AS avg_freight_ratio,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE repeated_within_90d
        )
        / COUNT(*),
        2
    ) AS repeat_rate_90d_pct

FROM eligible

GROUP BY freight_quartile

ORDER BY freight_quartile;