-- ============================================================
-- Olist Commercial & Customer Analytics
-- 22_commercial_analysis.sql
--
-- Purpose:
-- Analyse marketplace commercial performance across time,
-- categories, geography, payment behaviour and sellers.
--
-- Unless otherwise stated, commercial metrics use successfully
-- delivered orders only.
--
-- GMV refers to merchandise value, not Olist corporate revenue.
-- ============================================================


-- ============================================================
-- 1. EXECUTIVE COMMERCIAL KPIs
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(
        DISTINCT customer_unique_id
    ) AS customers,

    ROUND(
        SUM(order_gmv),
        2
    ) AS total_gmv,

    ROUND(
        AVG(order_gmv),
        2
    ) AS average_order_value,

    ROUND(
        AVG(item_count),
        2
    ) AS avg_items_per_order,

    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight,

    ROUND(
        100.0
        * SUM(freight_value)
        / NULLIF(SUM(order_gmv), 0),
        2
    ) AS freight_as_pct_of_gmv

FROM analytics.order_mart

WHERE is_delivered = TRUE;



-- ============================================================
-- 2. MONTHLY COMMERCIAL PERFORMANCE
--
-- 2016 contains extremely sparse launch-period data.
-- August 2018 is incomplete.
--
-- For clean month-on-month comparisons, use Jan 2017–Jul 2018.
-- ============================================================

WITH monthly AS (

    SELECT
        purchase_month,

        COUNT(*) AS orders,

        COUNT(
            DISTINCT customer_unique_id
        ) AS customers,

        ROUND(
            SUM(order_gmv),
            2
        ) AS gmv,

        ROUND(
            AVG(order_gmv),
            2
        ) AS aov

    FROM analytics.order_mart

    WHERE is_delivered = TRUE
      AND purchase_date >= DATE '2017-01-01'
      AND purchase_date < DATE '2018-08-01'

    GROUP BY purchase_month

),

with_lags AS (

    SELECT
        *,

        LAG(gmv) OVER (
            ORDER BY purchase_month
        ) AS prior_month_gmv,

        LAG(orders) OVER (
            ORDER BY purchase_month
        ) AS prior_month_orders

    FROM monthly

)

SELECT
    purchase_month,
    orders,
    customers,
    gmv,
    aov,

    ROUND(
        100.0
        * (gmv - prior_month_gmv)
        / NULLIF(prior_month_gmv, 0),
        2
    ) AS gmv_mom_pct,

    ROUND(
        100.0
        * (orders - prior_month_orders)
        / NULLIF(prior_month_orders, 0),
        2
    ) AS order_mom_pct

FROM with_lags

ORDER BY purchase_month;



-- ============================================================
-- 3. CATEGORY PERFORMANCE
--
-- Use item-level data here rather than primary category so
-- multi-category orders are allocated correctly.
-- ============================================================

WITH category_performance AS (

    SELECT
        p.product_category,

        COUNT(
            DISTINCT i.order_id
        ) AS orders,

        COUNT(
            DISTINCT o.customer_unique_id
        ) AS customers,

        COUNT(*) AS items_sold,

        COUNT(
            DISTINCT i.product_id
        ) AS products_sold,

        ROUND(
            SUM(i.item_gmv),
            2
        ) AS category_gmv,

        ROUND(
            AVG(i.item_gmv),
            2
        ) AS avg_item_value

    FROM staging.order_items i

    INNER JOIN analytics.order_mart o
        ON i.order_id = o.order_id

    LEFT JOIN staging.products p
        ON i.product_id = p.product_id

    WHERE o.is_delivered = TRUE

    GROUP BY p.product_category

)

SELECT
    *,

    ROUND(
        100.0
        * category_gmv
        / SUM(category_gmv) OVER (),
        2
    ) AS pct_of_marketplace_gmv

FROM category_performance

ORDER BY category_gmv DESC;



-- ============================================================
-- 4. CUSTOMER GEOGRAPHY
-- ============================================================

SELECT
    customer_state,

    COUNT(*) AS orders,

    COUNT(
        DISTINCT customer_unique_id
    ) AS customers,

    ROUND(
        SUM(order_gmv),
        2
    ) AS gmv,

    ROUND(
        AVG(order_gmv),
        2
    ) AS aov,

    ROUND(
        100.0
        * SUM(order_gmv)
        / SUM(SUM(order_gmv)) OVER (),
        2
    ) AS pct_of_gmv

FROM analytics.order_mart

WHERE is_delivered = TRUE

GROUP BY customer_state

ORDER BY gmv DESC;



-- ============================================================
-- 5. PAYMENT METHOD PERFORMANCE
-- ============================================================

SELECT
    COALESCE(
        primary_payment_type,
        'unknown'
    ) AS primary_payment_type,

    COUNT(*) AS orders,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_orders,

    ROUND(
        SUM(order_gmv),
        2
    ) AS gmv,

    ROUND(
        AVG(order_gmv),
        2
    ) AS aov,

    ROUND(
        AVG(max_installments),
        2
    ) AS avg_max_installments

FROM analytics.order_mart

WHERE is_delivered = TRUE

GROUP BY primary_payment_type

ORDER BY orders DESC;



-- ============================================================
-- 6. SELLER CONCENTRATION
-- ============================================================

WITH ranked_sellers AS (

    SELECT
        seller_id,
        seller_gmv,

        ROW_NUMBER() OVER (
            ORDER BY seller_gmv DESC
        ) AS seller_rank,

        SUM(seller_gmv) OVER (
            ORDER BY seller_gmv DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_gmv,

        SUM(seller_gmv) OVER ()
            AS marketplace_gmv

    FROM analytics.seller_mart

)

SELECT
    seller_rank,
    seller_id,

    ROUND(
        seller_gmv,
        2
    ) AS seller_gmv,

    ROUND(
        100.0
        * seller_gmv
        / marketplace_gmv,
        2
    ) AS seller_gmv_share_pct,

    ROUND(
        100.0
        * cumulative_gmv
        / marketplace_gmv,
        2
    ) AS cumulative_gmv_share_pct

FROM ranked_sellers

WHERE seller_rank <= 20

ORDER BY seller_rank;



-- ============================================================
-- 7. TOP-N SELLER GMV SHARE
-- ============================================================

WITH ranked AS (

    SELECT
        seller_gmv,

        ROW_NUMBER() OVER (
            ORDER BY seller_gmv DESC
        ) AS rn

    FROM analytics.seller_mart

),

totals AS (

    SELECT
        SUM(seller_gmv) AS total_gmv
    FROM analytics.seller_mart

)

SELECT
    ROUND(
        100.0
        * SUM(
            CASE WHEN rn <= 10
                 THEN seller_gmv ELSE 0 END
        )
        / MAX(total_gmv),
        2
    ) AS top_10_seller_gmv_share,

    ROUND(
        100.0
        * SUM(
            CASE WHEN rn <= 50
                 THEN seller_gmv ELSE 0 END
        )
        / MAX(total_gmv),
        2
    ) AS top_50_seller_gmv_share,

    ROUND(
        100.0
        * SUM(
            CASE WHEN rn <= 100
                 THEN seller_gmv ELSE 0 END
        )
        / MAX(total_gmv),
        2
    ) AS top_100_seller_gmv_share

FROM ranked

CROSS JOIN totals;