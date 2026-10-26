-- ============================================================
-- Olist Commercial & Customer Analytics
-- 14_create_customer_mart.sql
--
-- Purpose:
-- Create customer-level behavioural features from successfully
-- delivered orders.
--
-- Grain:
-- One row per customer_unique_id.
--
-- Key analytical considerations:
-- 1. customer_unique_id identifies the persistent customer.
-- 2. Only delivered orders count as completed purchases.
-- 3. Repeat behaviour is sequenced using purchase timestamp.
-- 4. Follow-up eligibility flags account for right-censoring
--    near the end of the dataset.
-- ============================================================


DROP TABLE IF EXISTS analytics.customer_mart CASCADE;

-- ============================================================
-- 1. DELIVERED-ORDER POPULATION
-- ============================================================

CREATE TABLE analytics.customer_mart AS

WITH delivered_orders AS (

    SELECT *
    FROM analytics.order_mart

    WHERE is_delivered = TRUE

),

-- ============================================================
-- 2. CUSTOMER PURCHASE SEQUENCING
-- ============================================================

ranked_orders AS (

    SELECT
        d.*,

        ROW_NUMBER() OVER (

            PARTITION BY customer_unique_id

            ORDER BY
                order_purchase_timestamp,
                order_id

        ) AS customer_order_number

    FROM delivered_orders d

),

-- ============================================================
-- 3. DATASET OBSERVATION WINDOW
-- ============================================================

dataset_bounds AS (

    SELECT
        MAX(purchase_date)
            AS observation_end_date

    FROM delivered_orders

),

-- ============================================================
-- 4. CUSTOMER-LEVEL AGGREGATION
-- ============================================================

customer_rollup AS (

    SELECT
        customer_unique_id,


        -- ------------------------------------
        -- Purchase timing
        -- ------------------------------------

        MIN(order_purchase_timestamp)
            AS first_order_timestamp,

        MIN(
            CASE
                WHEN customer_order_number = 2
                THEN order_purchase_timestamp
            END
        ) AS second_order_timestamp,

        MAX(order_purchase_timestamp)
            AS last_order_timestamp,


        MIN(purchase_date)
            AS first_order_date,

        MIN(
            CASE
                WHEN customer_order_number = 2
                THEN purchase_date
            END
        ) AS second_order_date,

        MAX(purchase_date)
            AS last_order_date,


        -- ------------------------------------
        -- Frequency
        -- ------------------------------------

        COUNT(*) AS delivered_orders,


        -- ------------------------------------
        -- Commercial value
        -- ------------------------------------

        ROUND(
            SUM(order_gmv),
            2
        ) AS total_gmv,

        ROUND(
            AVG(order_gmv),
            2
        ) AS average_order_value,

        ROUND(
            SUM(freight_value),
            2
        ) AS total_freight_value,

        ROUND(
            SUM(merchandise_plus_freight),
            2
        ) AS total_transaction_value,


        -- ------------------------------------
        -- Product breadth
        -- ------------------------------------

        COUNT(
            DISTINCT primary_product_category
        ) AS distinct_primary_categories,


        -- ------------------------------------
        -- Customer experience
        -- ------------------------------------

        ROUND(
            AVG(latest_review_score)::NUMERIC,
            2
        ) AS average_review_score,

        ROUND(
            AVG(delivery_days)::NUMERIC,
            2
        ) AS average_delivery_days,

        SUM(
            CASE
                WHEN late_delivery_flag = TRUE
                THEN 1
                ELSE 0
            END
        ) AS late_orders

    FROM ranked_orders

    GROUP BY customer_unique_id

),

-- ============================================================
-- 5. FIRST-ORDER CHARACTERISTICS
-- ============================================================

first_order_features AS (

    SELECT
        customer_unique_id,

        order_id
            AS first_order_id,

        customer_state
            AS first_order_state,

        order_gmv
            AS first_order_gmv,

        freight_value
            AS first_order_freight,

        freight_to_gmv_ratio
            AS first_order_freight_ratio,

        item_count
            AS first_order_item_count,

        distinct_products
            AS first_order_distinct_products,

        distinct_sellers
            AS first_order_distinct_sellers,

        primary_product_category
            AS first_order_category,

        primary_payment_type
            AS first_order_payment_type,

        max_installments
            AS first_order_installments,

        latest_review_score
            AS first_order_review_score,

        seller_processing_days
            AS first_order_processing_days,

        delivery_days
            AS first_order_delivery_days,

        late_delivery_flag
            AS first_order_late_flag

    FROM ranked_orders

    WHERE customer_order_number = 1

),

-- ============================================================
-- 6. REPEAT-PURCHASE & CUSTOMER FEATURES
-- ============================================================

customer_features AS (

    SELECT
        c.*,

        f.first_order_id,
        f.first_order_state,

        f.first_order_gmv,
        f.first_order_freight,
        f.first_order_freight_ratio,

        f.first_order_item_count,
        f.first_order_distinct_products,
        f.first_order_distinct_sellers,

        f.first_order_category,
        f.first_order_payment_type,
        f.first_order_installments,

        f.first_order_review_score,
        f.first_order_processing_days,
        f.first_order_delivery_days,
        f.first_order_late_flag,


        -- ------------------------------------
        -- Repeat customer
        -- ------------------------------------

        CASE
            WHEN c.delivered_orders >= 2
            THEN TRUE
            ELSE FALSE
        END AS repeat_customer_flag,


        -- ------------------------------------
        -- Time to second purchase
        -- ------------------------------------

        CASE
            WHEN c.second_order_timestamp IS NOT NULL

            THEN ROUND(
                (
                    EXTRACT(
                        EPOCH FROM (
                            c.second_order_timestamp
                            - c.first_order_timestamp
                        )
                    ) / 86400.0
                )::NUMERIC,
                2
            )

            ELSE NULL
        END AS days_to_second_purchase,


        -- ------------------------------------
        -- Customer lifespan
        -- ------------------------------------

        ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        c.last_order_timestamp
                        - c.first_order_timestamp
                    )
                ) / 86400.0
            )::NUMERIC,
            2
        ) AS customer_lifespan_days,


        -- ------------------------------------
        -- RFM components
        --
        -- Recency measured relative to end of
        -- observed delivered-order period.
        -- ------------------------------------

        (
            b.observation_end_date
            - c.last_order_date
        ) AS recency_days,

        c.delivered_orders
            AS frequency,

        c.total_gmv
            AS monetary_value,


        -- ------------------------------------
        -- Follow-up eligibility
        --
        -- Prevents newer customers from being
        -- unfairly labelled non-repeat simply
        -- because the dataset ended.
        -- ------------------------------------

        CASE
            WHEN c.first_order_date <=
                 b.observation_end_date - 30
            THEN TRUE
            ELSE FALSE
        END AS eligible_30d_followup,

        CASE
            WHEN c.first_order_date <=
                 b.observation_end_date - 60
            THEN TRUE
            ELSE FALSE
        END AS eligible_60d_followup,

        CASE
            WHEN c.first_order_date <=
                 b.observation_end_date - 90
            THEN TRUE
            ELSE FALSE
        END AS eligible_90d_followup,


        -- ------------------------------------
        -- Repeat within fixed horizons
        -- ------------------------------------

        CASE
            WHEN c.second_order_timestamp IS NOT NULL
             AND c.second_order_timestamp <=
                 c.first_order_timestamp
                 + INTERVAL '30 days'
            THEN TRUE

            ELSE FALSE
        END AS repeated_within_30d,

        CASE
            WHEN c.second_order_timestamp IS NOT NULL
             AND c.second_order_timestamp <=
                 c.first_order_timestamp
                 + INTERVAL '60 days'
            THEN TRUE

            ELSE FALSE
        END AS repeated_within_60d,

        CASE
            WHEN c.second_order_timestamp IS NOT NULL
             AND c.second_order_timestamp <=
                 c.first_order_timestamp
                 + INTERVAL '90 days'
            THEN TRUE

            ELSE FALSE
        END AS repeated_within_90d


    FROM customer_rollup c

    LEFT JOIN first_order_features f
        ON c.customer_unique_id =
           f.customer_unique_id

    CROSS JOIN dataset_bounds b

),

-- ============================================================
-- 7. FINAL CUSTOMER MART
-- ============================================================

final_customer_mart AS (

    SELECT *
    FROM customer_features

)


SELECT *
FROM final_customer_mart;


ALTER TABLE analytics.customer_mart
ADD CONSTRAINT pk_customer_mart
PRIMARY KEY (customer_unique_id);


CREATE INDEX idx_customer_mart_repeat
ON analytics.customer_mart (
    repeat_customer_flag
);


CREATE INDEX idx_customer_mart_first_order_date
ON analytics.customer_mart (
    first_order_date
);


CREATE INDEX idx_customer_mart_state
ON analytics.customer_mart (
    first_order_state
);