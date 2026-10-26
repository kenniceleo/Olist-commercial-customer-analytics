-- ============================================================
-- Olist Commercial & Customer Analytics
-- 18_create_customer_segments.sql
--
-- Purpose:
-- Create behaviour/value-based customer segments.
--
-- Grain:
-- One row per customer_unique_id.
--
-- Why not classic RFM?
-- 97% of customers have exactly one delivered order, making
-- frequency quintiles misleading.
--
-- Segmentation dimensions:
-- 1. Repeat vs one-time purchasing
-- 2. High vs standard observed customer value
-- 3. Recency among one-time customers
-- ============================================================


DROP TABLE IF EXISTS analytics.customer_segments CASCADE;


CREATE TABLE analytics.customer_segments AS


WITH value_threshold AS (

    SELECT
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY total_gmv
        ) AS p75_customer_gmv

    FROM analytics.customer_mart

)


SELECT
    c.customer_unique_id,

    c.first_order_date,
    c.last_order_date,

    c.delivered_orders,

    c.repeat_customer_flag,

    c.recency_days,

    c.total_gmv,
    c.average_order_value,

    v.p75_customer_gmv
        AS high_value_threshold,


    -- --------------------------------------------------------
    -- CUSTOMER VALUE
    -- --------------------------------------------------------

    CASE
        WHEN c.total_gmv >= v.p75_customer_gmv
        THEN 'High Value'

        ELSE 'Standard Value'
    END AS customer_value_band,


    -- --------------------------------------------------------
    -- CUSTOMER BEHAVIOUR
    --
    -- "Lapsed" means no observed purchase within the final
    -- 90 days of the dataset. It does not prove true churn.
    -- --------------------------------------------------------

    CASE
        WHEN c.repeat_customer_flag = TRUE
        THEN 'Repeat'

        WHEN c.recency_days <= 90
        THEN 'Recent One-Time'

        ELSE 'Lapsed One-Time'
    END AS customer_behaviour_band,


    -- --------------------------------------------------------
    -- FINAL SEGMENT
    -- --------------------------------------------------------

    CASE

        WHEN c.repeat_customer_flag = TRUE
         AND c.total_gmv >= v.p75_customer_gmv
        THEN 'Repeat High Value'

        WHEN c.repeat_customer_flag = TRUE
        THEN 'Repeat Standard Value'


        WHEN c.repeat_customer_flag = FALSE
         AND c.recency_days <= 90
         AND c.total_gmv >= v.p75_customer_gmv
        THEN 'Recent High Value One-Time'

        WHEN c.repeat_customer_flag = FALSE
         AND c.recency_days <= 90
        THEN 'Recent Standard One-Time'


        WHEN c.repeat_customer_flag = FALSE
         AND c.recency_days > 90
         AND c.total_gmv >= v.p75_customer_gmv
        THEN 'Lapsed High Value One-Time'

        ELSE 'Lapsed Standard One-Time'

    END AS customer_segment


FROM analytics.customer_mart c

CROSS JOIN value_threshold v;


ALTER TABLE analytics.customer_segments
ADD CONSTRAINT pk_customer_segments
PRIMARY KEY (customer_unique_id);


CREATE INDEX idx_customer_segments_segment
ON analytics.customer_segments (
    customer_segment
);
