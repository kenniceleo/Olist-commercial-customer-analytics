-- ============================================================
-- Olist Commercial & Customer Analytics
-- 24_seller_fulfilment_analysis.sql
--
-- Purpose:
-- Analyse seller concentration, processing, delivery performance
-- and customer experience.
-- ============================================================


-- ============================================================
-- 1. MARKETPLACE FULFILMENT KPIs
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(seller_processing_days),
        2
    ) AS avg_processing_days,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(carrier_delivery_days),
        2
    ) AS avg_carrier_delivery_days,

    COUNT(*) FILTER (
        WHERE late_delivery_flag = TRUE
    ) AS late_orders,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery_flag = TRUE
        )
        / NULLIF(
            COUNT(late_delivery_flag),
            0
        ),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score

FROM analytics.order_mart

WHERE is_delivered = TRUE;



-- ============================================================
-- 2. ON-TIME VS LATE CUSTOMER EXPERIENCE
-- ============================================================

SELECT
    CASE
        WHEN late_delivery_flag
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,

    COUNT(*) AS orders,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(order_gmv),
        2
    ) AS avg_order_gmv

FROM analytics.order_mart

WHERE is_delivered = TRUE
  AND late_delivery_flag IS NOT NULL

GROUP BY late_delivery_flag

ORDER BY late_delivery_flag;



-- ============================================================
-- 3. DELIVERY-TIME BANDS
-- ============================================================

SELECT
    CASE
        WHEN delivery_days <= 5
            THEN '0-5 days'

        WHEN delivery_days <= 10
            THEN '6-10 days'

        WHEN delivery_days <= 15
            THEN '11-15 days'

        WHEN delivery_days <= 20
            THEN '16-20 days'

        WHEN delivery_days <= 30
            THEN '21-30 days'

        ELSE '30+ days'
    END AS delivery_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery_flag = TRUE
        )
        /
        NULLIF(
            COUNT(late_delivery_flag),
            0
        ),
        2
    ) AS late_rate_pct

FROM analytics.order_mart

WHERE is_delivered = TRUE
  AND delivery_days IS NOT NULL

GROUP BY delivery_band

ORDER BY MIN(delivery_days);



-- ============================================================
-- 4. SELLER PROCESSING-TIME BANDS
-- ============================================================

SELECT
    CASE
        WHEN seller_processing_days <= 1
            THEN '0-1 day'

        WHEN seller_processing_days <= 2
            THEN '1-2 days'

        WHEN seller_processing_days <= 3
            THEN '2-3 days'

        WHEN seller_processing_days <= 5
            THEN '3-5 days'

        WHEN seller_processing_days <= 10
            THEN '5-10 days'

        ELSE '10+ days'
    END AS processing_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery_flag = TRUE
        )
        /
        NULLIF(
            COUNT(late_delivery_flag),
            0
        ),
        2
    ) AS late_delivery_rate_pct

FROM analytics.order_mart

WHERE is_delivered = TRUE
  AND seller_processing_days IS NOT NULL

GROUP BY processing_band

ORDER BY MIN(seller_processing_days);



-- ============================================================
-- 5. SELLER SCALE DISTRIBUTION
-- ============================================================

SELECT
    CASE
        WHEN delivered_orders <= 5
            THEN '1-5 orders'

        WHEN delivered_orders <= 20
            THEN '6-20 orders'

        WHEN delivered_orders <= 100
            THEN '21-100 orders'

        WHEN delivered_orders <= 500
            THEN '101-500 orders'

        ELSE '500+ orders'
    END AS seller_volume_band,

    COUNT(*) AS sellers,

    ROUND(
        AVG(delivered_orders),
        2
    ) AS avg_orders,

    ROUND(
        AVG(seller_gmv),
        2
    ) AS avg_seller_gmv,

    ROUND(
        AVG(avg_seller_processing_days),
        2
    ) AS avg_processing_days,

    ROUND(
        AVG(late_delivery_rate_pct),
        2
    ) AS avg_seller_late_rate_pct,

    ROUND(
        AVG(avg_review_score),
        2
    ) AS avg_seller_review

FROM analytics.seller_mart

GROUP BY seller_volume_band

ORDER BY MIN(delivered_orders);



-- ============================================================
-- 6. CUSTOMER STATE FULFILMENT
--
-- Minimum 200 delivered orders for more stable comparisons.
-- ============================================================

SELECT
    customer_state,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery_flag = TRUE
        )
        /
        NULLIF(
            COUNT(late_delivery_flag),
            0
        ),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(freight_to_gmv_ratio),
        4
    ) AS avg_freight_to_gmv_ratio

FROM analytics.order_mart

WHERE is_delivered = TRUE

GROUP BY customer_state

HAVING COUNT(*) >= 200

ORDER BY late_delivery_rate_pct DESC;



-- ============================================================
-- 7. FREIGHT BURDEN VS CUSTOMER EXPERIENCE
-- ============================================================

WITH freight_groups AS (

    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY freight_to_gmv_ratio
        ) AS freight_quartile

    FROM analytics.order_mart

    WHERE is_delivered = TRUE
      AND freight_to_gmv_ratio IS NOT NULL

)

SELECT
    freight_quartile,

    COUNT(*) AS orders,

    ROUND(
        AVG(freight_to_gmv_ratio),
        4
    ) AS avg_freight_ratio,

    ROUND(
        AVG(latest_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(order_gmv),
        2
    ) AS avg_order_gmv

FROM freight_groups

GROUP BY freight_quartile

ORDER BY freight_quartile;



-- ============================================================
-- 8. TOP 20 SELLERS
--
-- Operational metrics use single-seller order attribution.
-- ============================================================

SELECT
    seller_gmv_rank,

    seller_id,
    seller_state,

    delivered_orders,
    unique_customers,

    seller_gmv,

    avg_seller_processing_days,

    late_delivery_rate_pct,

    avg_review_score

FROM analytics.seller_mart

WHERE seller_gmv_rank <= 20

ORDER BY seller_gmv_rank;



-- ============================================================
-- 9. HIGH-VOLUME SELLERS WITH OPERATIONAL RISK
--
-- Restrict to sellers with at least 100 delivered orders.
-- ============================================================

SELECT
    seller_id,
    seller_state,

    delivered_orders,
    seller_gmv,

    avg_seller_processing_days,
    late_delivery_rate_pct,
    avg_review_score

FROM analytics.seller_mart

WHERE delivered_orders >= 100

ORDER BY
    late_delivery_rate_pct DESC,
    delivered_orders DESC

LIMIT 25;